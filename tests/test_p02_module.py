from __future__ import annotations

import json
import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_FOLDER = ROOT / "modules/02-turn-random-variables-into-histograms"
GUIDING_QUESTION = (
    "What inputs, observable effects, and failure modes matter when you turn "
    "Random Variables into Histograms?"
)
ARTIFACTS = (
    "README.md",
    "lesson.m",
    "model.m",
    "p02_baseline.m",
    "experiment.m",
    "interactive.m",
    "lesson.md",
    "walkthrough.md",
    "checks.md",
    "run_checks.m",
)


def _histogram_reference(samples, edges):
    """Independent Python reference; it does not execute or translate MATLAB."""
    if not samples:
        raise ValueError("samples must not be empty")
    if len(edges) < 2 or any(right <= left for left, right in zip(edges, edges[1:])):
        raise ValueError("edges must be strictly increasing")

    counts = [0] * (len(edges) - 1)
    underflow = 0
    overflow = 0
    for sample in samples:
        if sample < edges[0]:
            underflow += 1
            continue
        if sample > edges[-1]:
            overflow += 1
            continue
        for index, (left, right) in enumerate(zip(edges, edges[1:])):
            is_final = index == len(counts) - 1
            if sample >= left and (sample < right or (is_final and sample <= right)):
                counts[index] += 1
                break
        else:  # pragma: no cover - guarded by the ordered-edge and tail cases above
            raise AssertionError(f"unassigned sample: {sample}")

    sample_count = len(samples)
    widths = [right - left for left, right in zip(edges, edges[1:])]
    probability_mass = [count / sample_count for count in counts]
    density = [mass / width for mass, width in zip(probability_mass, widths)]
    return {
        "counts": counts,
        "widths": widths,
        "probability_mass": probability_mass,
        "density": density,
        "underflow": underflow,
        "overflow": overflow,
        "included_fraction": sum(counts) / sample_count,
        "area": sum(height * width for height, width in zip(density, widths)),
    }


class P02ModuleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        manifest = json.loads((ROOT / "curriculum/modules.json").read_text(encoding="utf-8"))
        cls.module = next(module for module in manifest["modules"] if module["id"] == "P02")

    def read(self, name: str) -> str:
        return (MODULE_FOLDER / name).read_text(encoding="utf-8")

    def test_manifest_identity_and_permanent_implemented_state(self):
        self.assertEqual(self.module["number"], 2)
        self.assertEqual(self.module["title"], "Turn Random Variables into Histograms")
        self.assertEqual(self.module["guiding_question"], GUIDING_QUESTION)
        self.assertEqual(self.module["phase"], 1)
        self.assertEqual(self.module["folder"], str(MODULE_FOLDER.relative_to(ROOT)))
        self.assertEqual(self.module["implementation_batch"], "P02")
        self.assertEqual(self.module["prerequisites"], ["P01"])
        self.assertEqual(self.module["status"], "implemented")
        self.assertEqual(self.module["evidence_level"], "simulated")

    def test_complete_artifact_set_and_guiding_question(self):
        for name in ARTIFACTS:
            with self.subTest(artifact=name):
                path = MODULE_FOLDER / name
                self.assertTrue(path.is_file(), name)
        for name in (
            "README.md",
            "lesson.m",
            "experiment.m",
            "lesson.md",
            "walkthrough.md",
            "checks.md",
        ):
            with self.subTest(guiding_question=name):
                normalized = " ".join(self.read(name).split())
                self.assertIn(GUIDING_QUESTION, normalized)
        self.assertIn("**Status:** implemented", self.read("README.md"))

    def test_model_is_transparent_bounded_and_presentation_free(self):
        model = self.read("model.m")
        for formula in (
            "counts(binIndex) = sum(inBin)",
            "probabilityMass = counts / sampleCount",
            "densityPerMillivolt = probabilityMass ./ binWidthsMillivolts",
            "scaledEdges = binEdgesMillivolts / (sigmaMillivolts * sqrt(2))",
            "erfc(leftScaledEdge) - erfc(rightScaledEdge)",
            "erfc(-rightScaledEdge) - erfc(-leftScaledEdge)",
            "erf(rightScaledEdge) - erf(leftScaledEdge)",
            "theoreticalUnderflowProbabilityMass = 0.5 * erfc(-scaledEdges(1))",
            "theoreticalOverflowProbabilityMass = 0.5 * erfc(scaledEdges(end))",
            "nominalProbabilityMassStandardError = sqrt(theoreticalProbabilityMass",
            "abs(underflowProbabilityMass - theoreticalUnderflowProbabilityMass)",
            "abs(overflowProbabilityMass - theoreticalOverflowProbabilityMass)",
        ):
            self.assertIn(formula, model)
        for contract in (
            "validateattributes",
            "P02:InvalidEdges",
            "P02:SampleCountMismatch",
            "P02:InvalidSeed",
            "P02:ResourceBound",
            "sampleCount > 50000",
            "binCount > 200",
            "binsPerSide = max(1",
            "maximumMagnitudeMillivolts",
            "P02:NumericalFailure",
            "onCleanup",
        ):
            self.assertIn(contract, model)
        self.assertLess(
            model.index("binsPerSide > 100"),
            model.index("(-binsPerSide:binsPerSide)"),
            "the bin resource bound must be checked before edge allocation",
        )
        self.assertLess(
            model.index("numel(binEdgesMillivolts) > 201"),
            model.index("validateattributes(binEdgesMillivolts"),
            "custom edge count must be bounded before validation scans the input",
        )
        self.assertLess(
            model.index("numel(binEdgesMillivolts) > 201"),
            model.index("reshape(binEdgesMillivolts"),
            "custom edge count must be bounded before reshaping or differencing",
        )
        self.assertLess(
            model.index("numel(suppliedSamples) ~= sampleCount"),
            model.index("validateattributes(suppliedSamples"),
            "a mismatched supplied vector must be rejected before a full validation scan",
        )
        for presentation_call in ("figure", "plot", "bar", "uiaxes", "uifigure"):
            self.assertIsNone(
                re.search(rf"\b{presentation_call}\s*\(", model, flags=re.IGNORECASE),
                presentation_call,
            )

    def test_experiment_has_ordered_flow_two_independent_sweeps_and_broken_case(self):
        experiment = self.read("experiment.m")
        lesson_script = self.read("lesson.m")
        lowered = experiment.lower()
        ordered_markers = (
            "%% read, then predict once",
            "%% deterministic baseline",
            "%% parameter sweep 1 - sample count only",
            "%% explain the first changed view",
            "%% reset, then parameter sweep 2 - bin width only",
            "%% explain the second changed view",
            "%% deliberately broken case",
            "%% repair the broken case",
        )
        positions = [lowered.index(marker) for marker in ordered_markers]
        self.assertEqual(positions, sorted(positions))
        self.assertIn("model(sample_counts(sweep_index)", experiment)
        self.assertIn("model(sample_count, bin_widths_millivolts(sweep_index)", experiment)
        self.assertIn("uniform_fixture_millivolts", experiment)
        self.assertIn("unequal_edges_millivolts = [-2 -1 1 2]", experiment)
        self.assertIn("counts [4 8 4]", experiment)
        self.assertIn("density_per_millivolt", experiment)
        baseline = self.read("p02_baseline.m")
        self.assertGreaterEqual(experiment.count("figure("), 4)
        self.assertIn("baseline = p02_baseline(", experiment)
        for label in (
            "Measurement index (sample)",
            "Sensor error X (mV)",
            "Sensor error x (mV)",
            "Probability density (1/mV)",
            "Raw count (samples)",
        ):
            self.assertIn(label, experiment + baseline)
        self.assertIn("underflow = %d samples", baseline)
        self.assertIn("overflow = %d samples", baseline)
        self.assertNotIn("close all", lowered)
        self.assertIn("findall(groot", experiment)
        self.assertIn("'^P02 '", experiment)
        self.assertEqual(experiment.count("Prediction:"), 1)
        self.assertEqual(lesson_script.count("Prediction:"), 1)
        self.assertIn("p02_baseline;", lesson_script)
        self.assertNotIn("experiment;", lesson_script)
        self.assertNotIn("interactive;", lesson_script)
        self.assertNotIn("N changes the evidence", lesson_script)
        self.assertNotIn("density = count / (N * width)", lesson_script)
        self.assertIn("Pause here", lesson_script)
        self.assertIn("'^P02 '", baseline)
        self.assertIn("close(p02Figures)", baseline)
        self.assertLess(
            experiment.index("baseline = p02_baseline("),
            experiment.index("Every sample must be accounted for."),
        )
        self.assertGreaterEqual(experiment.count("sigma_millivolts = 1.0;"), 5)
        self.assertGreaterEqual(experiment.count("seed = 202;"), 5)

    def test_interactive_exposes_bounded_meaningful_controls(self):
        interactive = self.read("interactive.m")
        self.assertGreaterEqual(interactive.count("uispinner("), 2)
        self.assertIn("uidropdown(", interactive)
        self.assertIn("Sample count N (samples)", interactive)
        self.assertIn("Bin width (mV)", interactive)
        self.assertIn("Realization seed", interactive)
        self.assertIn("'Limits', [50 5000]", interactive)
        self.assertIn("{'0.25', '0.50', '1.00', '2.00'}", interactive)
        self.assertIn("str2double(widthDropdown.Value)", interactive)
        self.assertIn("displayed -4 to 4 mV support", interactive)
        self.assertIn("underflow = %d samples", interactive)
        self.assertIn("overflow = %d samples", interactive)
        self.assertIn("clear model", interactive)
        self.assertIn("modelFcn = @model", interactive)
        self.assertIn("existingUi = findall(groot", interactive)
        self.assertIn("out = modelFcn(", interactive)
        self.assertIn("visibleCount = min(sampleCount, 250)", interactive)

    def test_checks_cover_exact_limits_failures_isolation_and_resource_bounds(self):
        checks = self.read("run_checks.m")
        self.assertGreaterEqual(checks.count("assert("), 15)
        for invariant in (
            "checkCallerRngState = rng",
            "restoreCheckCallerRng = onCleanup",
            "[1 3 2 2]",
            "[2 3]",
            "0.05",
            "expectedTheoryMass",
            "expectedTheoryDensity",
            "expectedNominalMassStandardError",
            "expectedFarTailMass",
            "Valid far-tail bin masses must not cancel to zero",
            "expectedFullL1Error",
            "[4 8 4]",
            "largeN.samples_millivolts(1:50)",
            "shrink in proportion to 1/sqrt(N)",
            "controlledBinWidths = [0.25 0.5 1.0 2.0]",
            "model must restore the caller RNG state for uniform and normal draws",
            "P02:SampleCountMismatch",
            "P02:InvalidEdges",
            "P02:ResourceBound",
            "P02 checks passed.",
        ):
            self.assertIn(invariant, checks)

    def test_independent_histogram_behavior_and_limiting_cases(self):
        with self.assertRaisesRegex(ValueError, "samples must not be empty"):
            _histogram_reference((), (-1, 1))
        with self.assertRaisesRegex(ValueError, "edges must be strictly increasing"):
            _histogram_reference((0,), (-1, 0, 0, 1))

        known_samples = (-2, -1, -0.9, -0.1, 0, 0.4, 1, 2)
        known_edges = (-2, -1, 0, 1, 2)
        known = _histogram_reference(known_samples, known_edges)
        self.assertEqual(known, _histogram_reference(known_samples, known_edges))
        self.assertEqual(known["counts"], [1, 3, 2, 2])
        self.assertEqual(known["underflow"], 0)
        self.assertEqual(known["overflow"], 0)
        self.assertEqual(sum(known["counts"]), len(known_samples))
        self.assertAlmostEqual(known["area"], known["included_fraction"])

        boundary = _histogram_reference((-3, -2, -1, 0, 1, 2, 3), (-2, 0, 2))
        self.assertEqual(boundary["counts"], [2, 3])
        self.assertEqual((boundary["underflow"], boundary["overflow"]), (1, 1))

        one_bin = _histogram_reference((-1, -0.5, 0, 0.5, 1), (-10, 10))
        self.assertEqual(one_bin["counts"], [5])
        self.assertEqual(one_bin["probability_mass"], [1.0])
        self.assertEqual(one_bin["density"], [0.05])
        self.assertEqual(one_bin["area"], 1.0)

        expected_theory_mass = 0.5 * math.erf(1.0 / math.sqrt(2.0))
        expected_theory_density = math.exp(-0.5 * 0.5**2) / math.sqrt(2.0 * math.pi)
        self.assertAlmostEqual(expected_theory_mass, 0.3413447460685429)
        self.assertAlmostEqual(expected_theory_density, 0.3520653267642995)

        far_tail_mass = 0.5 * (
            math.erfc(9.0 / math.sqrt(2.0))
            - math.erfc(10.0 / math.sqrt(2.0))
        )
        cancelled_far_tail_mass = 0.5 * (
            math.erf(10.0 / math.sqrt(2.0))
            - math.erf(9.0 / math.sqrt(2.0))
        )
        self.assertAlmostEqual(far_tail_mass, 1.1285122074236006e-19)
        self.assertGreater(far_tail_mass, 0.0)
        self.assertEqual(cancelled_far_tail_mass, 0.0)

        uniform_samples = tuple(-1.875 + 0.25 * index for index in range(16))
        unequal = _histogram_reference(uniform_samples, (-2, -1, 1, 2))
        self.assertEqual(unequal["counts"], [4, 8, 4])
        self.assertEqual(unequal["density"], [0.25, 0.25, 0.25])
        naive_raw_height_area = sum(
            mass * width
            for mass, width in zip(unequal["probability_mass"], unequal["widths"])
        )
        self.assertGreater(abs(naive_raw_height_area - 1.0), 0.1)
        self.assertEqual(unequal["area"], 1.0)

        asymmetric = _histogram_reference((-3, 0, 1, 4, 5), (-2, 2))
        gaussian_tail_mass = 0.5 * math.erfc(2.0 / math.sqrt(2.0))
        gaussian_interior_mass = 1.0 - 2.0 * gaussian_tail_mass
        expected_full_l1 = (
            abs(asymmetric["underflow"] / 5.0 - gaussian_tail_mass)
            + abs(asymmetric["probability_mass"][0] - gaussian_interior_mass)
            + abs(asymmetric["overflow"] / 5.0 - gaussian_tail_mass)
        )
        visible_bin_only_l1 = abs(
            asymmetric["probability_mass"][0] - gaussian_interior_mass
        )
        self.assertGreater(expected_full_l1, visible_bin_only_l1)
        self.assertAlmostEqual(
            gaussian_tail_mass + gaussian_interior_mass + gaussian_tail_mass,
            1.0,
        )

    def test_tutor_text_is_concept_first_and_connects_prerequisite(self):
        lesson = self.read("lesson.md")
        walkthrough = self.read("walkthrough.md")
        checks = self.read("checks.md")
        self.assertIn("Connection to P01", lesson)
        self.assertIn("bar area h_j * Delta x_j = p_j", lesson)
        self.assertIn("1/sqrt(N)", lesson)
        self.assertIn("run_module_checks('P02')", lesson)
        self.assertIn("one visual transition at a time", walkthrough)
        self.assertIn("mechanism first", walkthrough)
        self.assertIn("## Teach-back", checks)
        self.assertIn("Name the assumption violated", checks)
        self.assertIn("--checks-passed --teach-back", checks)

    def test_no_placeholder_or_opaque_toolbox_shortcut_remains(self):
        combined = "\n".join(self.read(name) for name in ARTIFACTS).lower()
        for placeholder in (
            "this module is curriculum-scaffolded",
            "p02 is scaffolded",
            "not implemented yet",
            "todo",
            "placeholder",
        ):
            self.assertNotIn(placeholder, combined)
        for opaque_call in (
            "histcounts(",
            "histfit(",
            "fitdist(",
            "ksdensity(",
            "makedist(",
            "normcdf(",
            "normpdf(",
            "normrnd(",
        ):
            self.assertNotIn(opaque_call, combined)

    def test_owned_text_files_have_exactly_one_terminal_newline(self):
        for name in ARTIFACTS:
            with self.subTest(artifact=name):
                content = (MODULE_FOLDER / name).read_bytes()
                self.assertTrue(content.endswith(b"\n"), name)
                self.assertFalse(content.endswith(b"\n\n"), name)
                self.assertNotIn(b"\r\n", content, name)

    def test_retained_evidence_has_required_claim_boundaries(self):
        evidence_path = ROOT / "docs/evidence/P02-2026-08-31.md"
        self.assertTrue(evidence_path.is_file(), "missing retained P02 evidence")
        evidence = evidence_path.read_text(encoding="utf-8")
        for heading in (
            "## Acceptance map",
            "## Exact validation commands and results",
            "## Figure, control, metric, and unit inventory",
            "## Preserved invariants",
            "## Residual risks",
            "## Rollback",
            "## Unperformed validation",
        ):
            self.assertIn(heading, evidence)
        self.assertIn("MATLAB runtime: not performed", evidence)
        self.assertIn("production: not performed", evidence)
        self.assertIn("independent Python reference arithmetic", evidence)


if __name__ == "__main__":
    unittest.main()
