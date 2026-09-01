from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]


class LearnCliTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((ROOT / "curriculum/modules.json").read_text(encoding="utf-8"))

    def create_fixture(self, fixture: Path) -> None:
        shutil.copytree(ROOT / "bin", fixture / "bin")
        shutil.copytree(ROOT / "curriculum", fixture / "curriculum")
        manifest = json.loads((fixture / "curriculum/modules.json").read_text(encoding="utf-8"))
        for module in manifest["modules"]:
            source = ROOT / module["folder"]
            target = fixture / module["folder"]
            target.mkdir(parents=True, exist_ok=True)
            for name in (
                "README.md",
                "lesson.md",
                "walkthrough.md",
                "checks.md",
                "run_checks.m",
            ):
                if (source / name).exists():
                    shutil.copy2(source / name, target / name)

    def run_cli_in_fixture(
        self, fixture: Path, *args: str
    ) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        environment["PYTHONDONTWRITEBYTECODE"] = "1"
        return subprocess.run(
            [str(fixture / "bin/learn"), *args],
            cwd=fixture,
            text=True,
            capture_output=True,
            env=environment,
            timeout=10,
        )

    def run_cli(self, *args: str) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            return self.run_cli_in_fixture(fixture, *args)

    def load_cli_module(self, fixture: Path):
        module_path = fixture / "bin/learn.py"
        spec = importlib.util.spec_from_file_location(
            f"learn_fixture_{id(fixture)}", module_path
        )
        self.assertIsNotNone(spec)
        self.assertIsNotNone(spec.loader)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module

    def test_status_and_list(self):
        status = self.run_cli("status")
        self.assertEqual(status.returncode, 0, status.stderr)
        implemented = sum(
            module["status"] == "implemented" for module in self.manifest["modules"]
        )
        self.assertIn(f"24 total, {implemented} implemented", status.stdout)
        listing = self.run_cli("list")
        self.assertEqual(listing.returncode, 0, listing.stderr)
        self.assertEqual(len([line for line in listing.stdout.splitlines() if line.strip()]), 24)

    def test_all_manifest_implemented_modules_start_and_check(self):
        implemented_ids = [
            module["id"]
            for module in self.manifest["modules"]
            if module["status"] == "implemented"
        ]
        for module_id in implemented_ids:
            with self.subTest(module=module_id):
                implemented = self.run_cli("start", module_id)
                self.assertEqual(implemented.returncode, 0, implemented.stderr)
                self.assertIn(f"{module_id} —", implemented.stdout)
                self.assertIn("Guiding question:", implemented.stdout)

                check = self.run_cli("check", module_id)
                self.assertEqual(check.returncode, 0, check.stderr)
                self.assertIn(f"run_module_checks('{module_id}')", check.stdout)

    def test_first_scaffold_refuses(self):
        first_scaffold = next(
            (module for module in self.manifest["modules"] if module["status"] == "scaffolded"),
            None,
        )
        if first_scaffold is None:
            return
        scaffold = self.run_cli("start", first_scaffold["id"])
        self.assertEqual(scaffold.returncode, 2)
        self.assertIn("Activate its governed implementation batch", scaffold.stdout)

    def test_check_rejects_scaffold_even_when_stale_check_artifact_remains(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            manifest_path = fixture / "curriculum/modules.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            p02 = next(module for module in manifest["modules"] if module["id"] == "P02")
            p02["status"] = "scaffolded"
            p02["evidence_level"] = "none"
            manifest_path.write_text(
                json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
            )

            stale_check = fixture / p02["folder"] / "run_checks.m"
            self.assertTrue(stale_check.is_file())
            rejected = self.run_cli_in_fixture(fixture, "check", "P02")

            self.assertNotEqual(rejected.returncode, 0)
            self.assertIn("Cannot check a scaffolded module", rejected.stderr)
            self.assertNotIn("Run in MATLAB", rejected.stdout)

    def test_rejected_scaffold_does_not_replace_resumable_selection(self):
        first_scaffold = next(
            (module for module in self.manifest["modules"] if module["status"] == "scaffolded"),
            None,
        )
        if first_scaffold is None:
            self.skipTest("the canonical manifest has no remaining scaffolded module")

        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)

            selected = self.run_cli_in_fixture(fixture, "start", "P02")
            self.assertEqual(selected.returncode, 0, selected.stderr)

            rejected = self.run_cli_in_fixture(fixture, "start", first_scaffold["id"])
            self.assertEqual(rejected.returncode, 2, rejected.stderr)

            resumed = self.run_cli_in_fixture(fixture, "continue")
            self.assertEqual(resumed.returncode, 0, resumed.stderr)
            self.assertIn("P02 —", resumed.stdout)

            state = json.loads(
                (fixture / ".learning/progress.json").read_text(encoding="utf-8")
            )
            self.assertEqual(state["current"], "P02")

    def test_legacy_scaffold_selection_recovers_to_latest_implemented_predecessor(self):
        first_scaffold_index = next(
            (
                index
                for index, module in enumerate(self.manifest["modules"])
                if module["status"] == "scaffolded"
            ),
            None,
        )
        if first_scaffold_index is None:
            self.skipTest("the canonical manifest has no remaining scaffolded module")
        expected = next(
            module
            for module in reversed(self.manifest["modules"][:first_scaffold_index])
            if module["status"] == "implemented"
        )

        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            state_path = fixture / ".learning/progress.json"
            state_path.parent.mkdir(parents=True)
            state_path.write_text(
                json.dumps(
                    {
                        "current": self.manifest["modules"][first_scaffold_index]["id"],
                        "completed": {"P01": True},
                    }
                )
                + "\n",
                encoding="utf-8",
            )

            resumed = self.run_cli_in_fixture(fixture, "continue")
            self.assertEqual(resumed.returncode, 0, resumed.stderr)
            self.assertIn(f"{expected['id']} —", resumed.stdout)
            recovered = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertEqual(recovered["current"], expected["id"])
            self.assertEqual(recovered["completed"], {"P01": True})
            self.assertEqual(recovered["notes"], {})

    def test_complete_requires_check_attestation_and_teach_back(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            state_path = fixture / ".learning/progress.json"

            for incomplete_args in (
                ("complete", "P02"),
                ("complete", "P02", "--checks-passed"),
                ("complete", "P02", "--checks-passed", "--teach-back", "   "),
                ("complete", "P02", "--teach-back", "Counts become density by area."),
            ):
                with self.subTest(args=incomplete_args):
                    rejected = self.run_cli_in_fixture(fixture, *incomplete_args)
                    self.assertEqual(rejected.returncode, 2, rejected.stderr)
                    self.assertIn("Completion not recorded", rejected.stdout)
                    self.assertFalse(state_path.exists())

            completed = self.run_cli_in_fixture(
                fixture,
                "complete",
                "P02",
                "--checks-passed",
                "--teach-back",
                "Intervals count outcomes; width-normalized area is probability.",
                "--note",
                "Reviewed unequal bins.",
            )
            self.assertEqual(completed.returncode, 0, completed.stderr)
            state = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertTrue(state["completed"]["P02"])
            self.assertEqual(state["current"], "P02")
            self.assertIn("width-normalized area", state["notes"]["P02"])
            self.assertIn("Reviewed unequal bins", state["notes"]["P02"])

            first_scaffold = next(
                (
                    module
                    for module in self.manifest["modules"]
                    if module["status"] == "scaffolded"
                ),
                None,
            )
            if first_scaffold is not None:
                rejected_scaffold = self.run_cli_in_fixture(
                    fixture,
                    "complete",
                    first_scaffold["id"],
                    "--checks-passed",
                    "--teach-back",
                    "This must not be retained.",
                )
                self.assertNotEqual(rejected_scaffold.returncode, 0)
                self.assertIn("Cannot complete a scaffolded module", rejected_scaffold.stderr)
                unchanged = json.loads(state_path.read_text(encoding="utf-8"))
                self.assertNotIn(first_scaffold["id"], unchanged["completed"])

    def test_recompletion_preserves_a_legacy_note_with_the_new_teach_back(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            state_path = fixture / ".learning/progress.json"
            state_path.parent.mkdir(parents=True)
            state_path.write_text(
                json.dumps(
                    {
                        "current": "P01",
                        "completed": {"P01": True},
                        "notes": {"P01": "Legacy learner note."},
                    }
                )
                + "\n",
                encoding="utf-8",
            )

            completed = self.run_cli_in_fixture(
                fixture,
                "complete",
                "P01",
                "--checks-passed",
                "--teach-back",
                "Repetition stabilizes the long-run proportion.",
            )
            self.assertEqual(completed.returncode, 0, completed.stderr)
            state = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertIn("Repetition stabilizes", state["notes"]["P01"])
            self.assertIn("Legacy learner note.", state["notes"]["P01"])

    def test_p04_completion_command_persists_attested_teach_back(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            p04 = next(
                module for module in self.manifest["modules"] if module["id"] == "P04"
            )
            self.assertEqual(p04["status"], "implemented")

            teach_back = (
                "Weight both alarm paths by their priors, then normalize the "
                "observed alarm column; ignoring the base rate creates false confidence."
            )
            completed = self.run_cli_in_fixture(
                fixture,
                "complete",
                "P04",
                "--checks-passed",
                "--teach-back",
                teach_back,
            )
            self.assertEqual(completed.returncode, 0, completed.stderr)
            self.assertIn("Marked P04 complete", completed.stdout)

            state_path = fixture / ".learning/progress.json"
            state = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertEqual(state["current"], "P04")
            self.assertTrue(state["completed"]["P04"])
            self.assertEqual(state["notes"]["P04"], teach_back)

            resumed = self.run_cli_in_fixture(fixture, "continue")
            self.assertEqual(resumed.returncode, 0, resumed.stderr)
            self.assertIn("P04 —", resumed.stdout)
            status = self.run_cli_in_fixture(fixture, "status")
            self.assertEqual(status.returncode, 0, status.stderr)
            self.assertIn("1 completed", status.stdout)
            listing = self.run_cli_in_fixture(fixture, "list")
            self.assertEqual(listing.returncode, 0, listing.stderr)
            p04_line = next(
                line for line in listing.stdout.splitlines() if " P04 " in line
            )
            self.assertTrue(p04_line.startswith("✓ P04"), p04_line)

    def test_malformed_state_is_preserved_with_a_controlled_diagnostic(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            state_path = fixture / ".learning/progress.json"
            state_path.parent.mkdir(parents=True)
            malformed = b'{"current":'
            state_path.write_bytes(malformed)

            status = self.run_cli_in_fixture(fixture, "status")
            self.assertNotEqual(status.returncode, 0)
            self.assertIn("Learner state is unreadable or malformed", status.stderr)
            self.assertEqual(state_path.read_bytes(), malformed)

    def test_invalid_utf8_and_progress_values_are_preserved_and_rejected(self):
        malformed_states = (
            (b'\xff\xfe', "unreadable or malformed"),
            (
                b'{"current": null, "completed": {"P01": "yes"}, "notes": {}}\n',
                "invalid completion values",
            ),
            (
                b'{"current": null, "completed": {}, "notes": {"P01": 4}}\n',
                "invalid note values",
            ),
        )
        for malformed, diagnostic in malformed_states:
            with self.subTest(diagnostic=diagnostic):
                with tempfile.TemporaryDirectory() as temporary:
                    fixture = Path(temporary) / "repo"
                    self.create_fixture(fixture)
                    state_path = fixture / ".learning/progress.json"
                    state_path.parent.mkdir(parents=True)
                    state_path.write_bytes(malformed)

                    status = self.run_cli_in_fixture(fixture, "status")
                    self.assertNotEqual(status.returncode, 0)
                    self.assertIn(diagnostic, status.stderr)
                    self.assertEqual(state_path.read_bytes(), malformed)

    def test_atomic_save_preserves_previous_state_when_replace_is_interrupted(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            cli = self.load_cli_module(fixture)
            cli.STATE_DIR.mkdir(parents=True)
            original = '{"current": "P01", "completed": {}, "notes": {}}\n'
            cli.STATE_FILE.write_text(original, encoding="utf-8")

            with mock.patch.object(cli.os, "replace", side_effect=OSError("interrupted")):
                with self.assertRaisesRegex(OSError, "interrupted"):
                    cli.save_state(
                        {"current": "P02", "completed": {}, "notes": {}}
                    )

            self.assertEqual(cli.STATE_FILE.read_text(encoding="utf-8"), original)
            self.assertEqual(list(cli.STATE_DIR.glob(".progress-*.tmp")), [])

    def test_atomic_save_cancellation_preserves_state_and_cleans_temporary_file(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            cli = self.load_cli_module(fixture)
            cli.STATE_DIR.mkdir(parents=True)
            original = '{"current": "P01", "completed": {}, "notes": {}}\n'
            cli.STATE_FILE.write_text(original, encoding="utf-8")

            with self.assertRaises(KeyboardInterrupt):
                with cli.state_lock():
                    with mock.patch.object(
                        cli.os, "replace", side_effect=KeyboardInterrupt
                    ):
                        cli.save_state(
                            {"current": "P02", "completed": {}, "notes": {}}
                        )

            self.assertEqual(cli.STATE_FILE.read_text(encoding="utf-8"), original)
            self.assertEqual(list(cli.STATE_DIR.glob(".progress-*.tmp")), [])
            with cli.state_lock():
                pass

    def test_state_lock_times_out_without_mutating_progress(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            cli = self.load_cli_module(fixture)
            with cli.state_lock():
                blocked = self.run_cli_in_fixture(fixture, "start", "P02")

            self.assertNotEqual(blocked.returncode, 0)
            self.assertIn("Learner state is busy", blocked.stderr)
            self.assertFalse(cli.STATE_FILE.exists())

            recovered = self.run_cli_in_fixture(fixture, "start", "P02")
            self.assertEqual(recovered.returncode, 0, recovered.stderr)
            state = json.loads(cli.STATE_FILE.read_text(encoding="utf-8"))
            self.assertEqual(state["current"], "P02")

    def test_concurrent_completions_preserve_both_updates(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            environment = os.environ.copy()
            environment["PYTHONDONTWRITEBYTECODE"] = "1"
            commands = [
                [
                    str(fixture / "bin/learn"),
                    "complete",
                    module_id,
                    "--checks-passed",
                    "--teach-back",
                    f"Teach-back for {module_id}",
                ]
                for module_id in ("P01", "P02")
            ]
            processes = [
                subprocess.Popen(
                    command,
                    cwd=fixture,
                    text=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    env=environment,
                )
                for command in commands
            ]
            for process in processes:
                stdout, stderr = process.communicate(timeout=10)
                self.assertEqual(process.returncode, 0, stderr or stdout)

            state = json.loads(
                (fixture / ".learning/progress.json").read_text(encoding="utf-8")
            )
            self.assertEqual(set(state["completed"]), {"P01", "P02"})
            self.assertEqual(set(state["notes"]), {"P01", "P02"})

    def test_source_rollback_hides_but_preserves_dormant_completion(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            manifest_path = fixture / "curriculum/modules.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            p02 = next(module for module in manifest["modules"] if module["id"] == "P02")
            p02["status"] = "scaffolded"
            p02["evidence_level"] = "none"
            manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

            state_path = fixture / ".learning/progress.json"
            state_path.parent.mkdir(parents=True)
            dormant_note = "P02 teach-back retained across source rollback."
            state_path.write_text(
                json.dumps(
                    {
                        "current": "P02",
                        "completed": {"P01": True, "P02": True},
                        "notes": {"P01": "P01 note", "P02": dormant_note},
                    }
                )
                + "\n",
                encoding="utf-8",
            )

            resumed = self.run_cli_in_fixture(fixture, "continue")
            self.assertEqual(resumed.returncode, 0, resumed.stderr)
            self.assertIn("P01 —", resumed.stdout)
            preserved = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertEqual(preserved["current"], "P01")
            self.assertTrue(preserved["completed"]["P02"])
            self.assertEqual(preserved["notes"]["P02"], dormant_note)

            status = self.run_cli_in_fixture(fixture, "status")
            self.assertEqual(status.returncode, 0, status.stderr)
            self.assertIn("1 completed", status.stdout)
            listing = self.run_cli_in_fixture(fixture, "list")
            self.assertEqual(listing.returncode, 0, listing.stderr)
            p02_line = next(
                line for line in listing.stdout.splitlines() if " P02 " in line
            )
            self.assertTrue(p02_line.startswith("○ P02"), p02_line)

    def test_p03_frontier_rollback_recovers_to_p02_and_preserves_completion(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            manifest_path = fixture / "curriculum/modules.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            p03 = next(module for module in manifest["modules"] if module["id"] == "P03")
            self.assertEqual(p03["status"], "implemented")

            for module in manifest["modules"]:
                if module["number"] >= p03["number"]:
                    module["status"] = "scaffolded"
                    module["evidence_level"] = "none"
            manifest_path.write_text(
                json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
            )

            state_path = fixture / ".learning/progress.json"
            state_path.parent.mkdir(parents=True)
            dormant_note = "P03 teach-back retained across source rollback."
            state_path.write_text(
                json.dumps(
                    {
                        "current": "P03",
                        "completed": {"P01": True, "P02": True, "P03": True},
                        "notes": {
                            "P01": "P01 note",
                            "P02": "P02 note",
                            "P03": dormant_note,
                        },
                    }
                )
                + "\n",
                encoding="utf-8",
            )

            resumed = self.run_cli_in_fixture(fixture, "continue")
            self.assertEqual(resumed.returncode, 0, resumed.stderr)
            self.assertIn("P02 —", resumed.stdout)
            preserved = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertEqual(preserved["current"], "P02")
            self.assertTrue(preserved["completed"]["P03"])
            self.assertEqual(preserved["notes"]["P03"], dormant_note)

            status = self.run_cli_in_fixture(fixture, "status")
            self.assertEqual(status.returncode, 0, status.stderr)
            self.assertIn("2 implemented, 2 completed", status.stdout)
            listing = self.run_cli_in_fixture(fixture, "list")
            self.assertEqual(listing.returncode, 0, listing.stderr)
            p03_line = next(
                line for line in listing.stdout.splitlines() if " P03 " in line
            )
            self.assertTrue(p03_line.startswith("○ P03"), p03_line)

            rejected = self.run_cli_in_fixture(fixture, "start", "P03")
            self.assertEqual(rejected.returncode, 2, rejected.stderr)
            unchanged = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertEqual(unchanged["current"], "P02")
            self.assertTrue(unchanged["completed"]["P03"])
            self.assertEqual(unchanged["notes"]["P03"], dormant_note)

    def test_p04_frontier_rollback_recovers_to_p03_and_preserves_completion(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            manifest_path = fixture / "curriculum/modules.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            p04 = next(module for module in manifest["modules"] if module["id"] == "P04")
            self.assertEqual(p04["status"], "implemented")

            for module in manifest["modules"]:
                if module["number"] >= p04["number"]:
                    module["status"] = "scaffolded"
                    module["evidence_level"] = "none"
            manifest_path.write_text(
                json.dumps(manifest, indent=2) + "\n", encoding="utf-8"
            )

            state_path = fixture / ".learning/progress.json"
            state_path.parent.mkdir(parents=True)
            dormant_note = "P04 teach-back retained across source rollback."
            completed = {f"P{number:02d}": True for number in range(1, 5)}
            notes = {
                f"P{number:02d}": f"P{number:02d} note"
                for number in range(1, 4)
            }
            notes["P04"] = dormant_note
            state_path.write_text(
                json.dumps(
                    {
                        "current": "P04",
                        "completed": completed,
                        "notes": notes,
                    }
                )
                + "\n",
                encoding="utf-8",
            )

            resumed = self.run_cli_in_fixture(fixture, "continue")
            self.assertEqual(resumed.returncode, 0, resumed.stderr)
            self.assertIn("P03 —", resumed.stdout)
            preserved = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertEqual(preserved["current"], "P03")
            self.assertTrue(preserved["completed"]["P04"])
            self.assertEqual(preserved["notes"]["P04"], dormant_note)

            expected_implemented = sum(
                module["status"] == "implemented" for module in manifest["modules"]
            )
            expected_completed = sum(
                module["status"] == "implemented"
                and completed.get(module["id"]) is True
                for module in manifest["modules"]
            )
            status = self.run_cli_in_fixture(fixture, "status")
            self.assertEqual(status.returncode, 0, status.stderr)
            self.assertIn(
                f"{expected_implemented} implemented, {expected_completed} completed",
                status.stdout,
            )
            listing = self.run_cli_in_fixture(fixture, "list")
            self.assertEqual(listing.returncode, 0, listing.stderr)
            p04_line = next(
                line for line in listing.stdout.splitlines() if " P04 " in line
            )
            self.assertTrue(p04_line.startswith("○ P04"), p04_line)

            rejected = self.run_cli_in_fixture(fixture, "start", "P04")
            self.assertEqual(rejected.returncode, 2, rejected.stderr)
            unchanged = json.loads(state_path.read_text(encoding="utf-8"))
            self.assertEqual(unchanged["current"], "P03")
            self.assertTrue(unchanged["completed"]["P04"])
            self.assertEqual(unchanged["notes"]["P04"], dormant_note)

    def test_status_ignores_false_and_noncanonical_completion_entries(self):
        with tempfile.TemporaryDirectory() as temporary:
            fixture = Path(temporary) / "repo"
            self.create_fixture(fixture)
            state_path = fixture / ".learning/progress.json"
            state_path.parent.mkdir(parents=True)
            state_path.write_text(
                json.dumps(
                    {
                        "current": None,
                        "completed": {"P01": False, "P99": True},
                        "notes": {},
                    }
                )
                + "\n",
                encoding="utf-8",
            )

            status = self.run_cli_in_fixture(fixture, "status")
            self.assertEqual(status.returncode, 0, status.stderr)
            self.assertIn("0 completed", status.stdout)

    def test_unknown_module_is_rejected(self):
        unknown = self.run_cli("start", "P99")
        self.assertNotEqual(unknown.returncode, 0)
        self.assertIn("Unknown module: P99", unknown.stderr)


if __name__ == "__main__":
    unittest.main()
