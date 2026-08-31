#!/usr/bin/env python3
"""Local learner CLI for a MATLAB learning harness."""
from __future__ import annotations
import argparse
from contextlib import contextmanager
import json
import os
from pathlib import Path
import sys
import tempfile
import time

if os.name == "nt":
    import msvcrt
else:
    import fcntl

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "curriculum" / "modules.json"
STATE_DIR = ROOT / ".learning"
STATE_FILE = STATE_DIR / "progress.json"
STATE_LOCK_FILE = STATE_DIR / "progress.lock"
STATE_LOCK_TIMEOUT_SECONDS = 2.0


def empty_state():
    return {"current": None, "completed": {}, "notes": {}}

def load_manifest():
    return json.loads(MANIFEST.read_text(encoding="utf-8"))

def load_state():
    if not STATE_FILE.exists():
        return empty_state()
    try:
        state = json.loads(STATE_FILE.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        raise SystemExit(
            f"Learner state is unreadable or malformed: {STATE_FILE}. "
            "No state was changed."
        ) from error
    if not isinstance(state, dict):
        raise SystemExit(f"Learner state must be a JSON object: {STATE_FILE}. No state was changed.")
    state.setdefault("current", None)
    state.setdefault("completed", {})
    state.setdefault("notes", {})
    if state["current"] is not None and not isinstance(state["current"], str):
        raise SystemExit(f"Learner state has an invalid current module: {STATE_FILE}. No state was changed.")
    if not isinstance(state["completed"], dict) or not isinstance(state["notes"], dict):
        raise SystemExit(f"Learner state has invalid progress maps: {STATE_FILE}. No state was changed.")
    if any(not isinstance(value, bool) for value in state["completed"].values()):
        raise SystemExit(f"Learner state has invalid completion values: {STATE_FILE}. No state was changed.")
    if any(not isinstance(value, str) for value in state["notes"].values()):
        raise SystemExit(f"Learner state has invalid note values: {STATE_FILE}. No state was changed.")
    return state

def save_state(state):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        dir=STATE_DIR, prefix=".progress-", suffix=".tmp"
    )
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(state, handle, indent=2)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary_path, STATE_FILE)
    finally:
        temporary_path.unlink(missing_ok=True)


def acquire_state_lock(handle):
    handle.seek(0)
    if os.name == "nt":
        msvcrt.locking(handle.fileno(), msvcrt.LK_NBLCK, 1)
    else:
        fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)


def release_state_lock(handle):
    handle.seek(0)
    if os.name == "nt":
        msvcrt.locking(handle.fileno(), msvcrt.LK_UNLCK, 1)
    else:
        fcntl.flock(handle.fileno(), fcntl.LOCK_UN)


@contextmanager
def state_lock():
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    with STATE_LOCK_FILE.open("a+b") as handle:
        handle.seek(0, os.SEEK_END)
        if handle.tell() == 0:
            handle.write(b"\0")
            handle.flush()
        deadline = time.monotonic() + STATE_LOCK_TIMEOUT_SECONDS
        locked = False
        try:
            while not locked:
                try:
                    acquire_state_lock(handle)
                    locked = True
                except OSError as error:
                    if time.monotonic() >= deadline:
                        raise SystemExit(
                            "Learner state is busy; no state was changed. Try again."
                        ) from error
                    time.sleep(0.05)
            yield
        finally:
            if locked:
                release_state_lock(handle)

def resolve_module(manifest, ref, state=None):
    modules = manifest["modules"]
    if ref is None:
        state = load_state() if state is None else state
        if state.get("current"):
            ref = state["current"]
        else:
            ref = next((m["id"] for m in modules if m["status"] == "implemented"), modules[0]["id"])
    ref_text = str(ref).strip().upper()
    for module in modules:
        if ref_text in {module["id"], str(module["number"]), f"{module['number']:02d}", module["slug"].upper()}:
            if state is not None and module["status"] != "implemented":
                earlier = modules[: modules.index(module)]
                return next(
                    (candidate for candidate in reversed(earlier) if candidate["status"] == "implemented"),
                    module,
                )
            return module
    raise SystemExit(f"Unknown module: {ref}")

def print_start(module):
    folder = ROOT / module["folder"]
    print(f"{module['id']} — {module['title']}")
    print(f"Status: {module['status']}")
    print(f"Guiding question: {module['guiding_question']}")
    print(f"Folder: {folder.relative_to(ROOT)}")
    if module["status"] != "implemented":
        print("This module is scaffolded. Activate its governed implementation batch before tutor use.")
        return 2
    print("\nMATLAB:")
    print(f"  launch_lesson('{module['id']}')")
    print("\nTutor files:")
    for name in ["README.md", "lesson.md", "walkthrough.md", "checks.md"]:
        path = folder / name
        if path.exists():
            print(f"  {path.relative_to(ROOT)}")
    return 0

def cmd_start(args):
    manifest = load_manifest()
    if args.module is None:
        with state_lock():
            state = load_state()
            module = resolve_module(manifest, None, state)
            if module["status"] == "implemented":
                state["current"] = module["id"]
                save_state(state)
        return print_start(module)

    module = resolve_module(manifest, args.module)
    if module["status"] == "implemented":
        with state_lock():
            state = load_state()
            state["current"] = module["id"]
            save_state(state)
    return print_start(module)

def cmd_continue(_args):
    manifest = load_manifest()
    with state_lock():
        state = load_state()
        module = resolve_module(manifest, None, state)
        if module["status"] == "implemented" and state.get("current") != module["id"]:
            state["current"] = module["id"]
            save_state(state)
    return print_start(module)

def cmd_list(_args):
    manifest = load_manifest()
    state = load_state()
    completed = state.get("completed", {})
    for m in manifest["modules"]:
        if m["status"] != "implemented":
            marker = "○"
        elif completed.get(m["id"]) is True:
            marker = "✓"
        else:
            marker = "●"
        print(f"{marker} {m['id']}  Phase {m['phase']}  {m['title']} [{m['status']}]")
    return 0

def cmd_status(_args):
    manifest = load_manifest()
    state = load_state()
    complete = sum(
        module["status"] == "implemented"
        and state.get("completed", {}).get(module["id"]) is True
        for module in manifest["modules"]
    )
    implemented = sum(m["status"] == "implemented" for m in manifest["modules"])
    print(f"Track: {manifest['title']}")
    print(f"Modules: {manifest['module_count']} total, {implemented} implemented, {complete} completed")
    print(f"Current: {state.get('current') or 'none'}")
    return 0

def cmd_complete(args):
    manifest = load_manifest()
    module = resolve_module(manifest, args.module)
    if module["status"] != "implemented":
        raise SystemExit("Cannot complete a scaffolded module.")
    teach_back = args.teach_back.strip()
    if not args.checks_passed or not teach_back:
        print("Completion not recorded: executable checks and a short teach-back are required.")
        print(f"Run in MATLAB from the repository root: run_module_checks('{module['id']}')")
        print(
            f"Then rerun: ./bin/learn complete {module['id']} "
            '--checks-passed --teach-back "<mechanism and consequence>"'
        )
        return 2
    with state_lock():
        state = load_state()
        state.setdefault("completed", {})[module["id"]] = True
        notes = state.setdefault("notes", {})
        previous_note = notes.get(module["id"], "").strip()
        retained_note = teach_back
        if args.note.strip():
            retained_note += f"\nNote: {args.note.strip()}"
        elif previous_note:
            retained_note += f"\nNote: {previous_note}"
        notes[module["id"]] = retained_note
        state["current"] = module["id"]
        save_state(state)
    print(f"Marked {module['id']} complete after check attestation and teach-back.")
    return 0

def cmd_check(args):
    manifest = load_manifest()
    module = resolve_module(manifest, args.module)
    if module["status"] != "implemented":
        raise SystemExit("Cannot check a scaffolded module.")
    folder = ROOT / module["folder"]
    if not (folder / "run_checks.m").exists():
        raise SystemExit(f"{module['id']} has no executable checks.")
    print(f"Run in MATLAB: run_module_checks('{module['id']}')")
    return 0

def main():
    parser = argparse.ArgumentParser(prog="learn")
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("start"); p.add_argument("module", nargs="?"); p.set_defaults(func=cmd_start)
    p = sub.add_parser("continue"); p.set_defaults(func=cmd_continue)
    p = sub.add_parser("list"); p.set_defaults(func=cmd_list)
    p = sub.add_parser("status"); p.set_defaults(func=cmd_status)
    p = sub.add_parser("complete"); p.add_argument("module"); p.add_argument("--checks-passed", action="store_true"); p.add_argument("--teach-back", default=""); p.add_argument("--note", default=""); p.set_defaults(func=cmd_complete)
    p = sub.add_parser("check"); p.add_argument("module", nargs="?"); p.set_defaults(func=cmd_check)
    args = parser.parse_args()
    raise SystemExit(args.func(args))

if __name__ == "__main__":
    main()
