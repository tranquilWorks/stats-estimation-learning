from __future__ import annotations

import json
import math
import re
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_FOLDER = ROOT / "modules/05-watch-the-sample-mean-converge"
GUIDING_QUESTION = (
    "What inputs, observable effects, and failure modes matter when you watch "
    "the Sample Mean Converge?"
)
ARTIFACTS = (
    "README.md",
    "lesson.m",
    "model.m",
    "p05_baseline.m",
    "experiment.m",
    "interactive.m",
    "lesson.md",
    "walkthrough.md",
    "checks.md",
    "run_checks.m",
)


def _sample_mean_reference(sample_count, target, sigma, bias, standardized_noise):
    """Independent Python arithmetic; it does not execute or translate MATLAB."""
    scalar_inputs = (target, sigma, bias)
    if (
        not isinstance(sample_count, int)
        or isinstance(sample_count, bool)
        or sample_count < 1
        or sample_count > 50_000
    ):
        raise ValueError("sample count must be a bounded positive integer")
    if any(
        not isinstance(value, (int, float))
        or isinstance(value, bool)
        or not math.isfinite(value)
        for value in scalar_inputs
    ):
        raise ValueError("model scalars must be finite real numbers")
    if sigma < 0:
        raise ValueError("noise scale must be nonnegative")
    if any(abs(value) > 1_000_000 for value in scalar_inputs):
        raise ValueError("model scalars exceed resource bounds")
    if len(standardized_noise) != sample_count:
        raise ValueError("noise fixture length must match sample count")
    if any(
        not isinstance(value, (int, float))
        or isinstance(value, bool)
        or not math.isfinite(value)
        for value in standardized_noise
    ):
        raise ValueError("noise fixture must contain finite real numbers")

    measurement_center = target + bias
    measurements = [
        measurement_center + sigma * value for value in standardized_noise
    ]
    if any(not math.isfinite(value) for value in measurements):
        raise ValueError("validated inputs produced nonfinite measurements")
    running_means = []
    cumulative = 0.0
    for count, measurement in enumerate(measurements, start=1):
        cumulative += measurement
        running_means.append(cumulative / count)
    standard_errors = [sigma / math.sqrt(count) for count in range(1, sample_count + 1)]
    target_rmses = [
        math.sqrt(bias * bias + standard_error * standard_error)
        for standard_error in standard_errors
    ]
    return {
        "measurements": measurements,
        "running_means": running_means,
        "target_errors": [value - target for value in running_means],
        "random_errors": [value - measurement_center for value in running_means],
        "standard_errors": standard_errors,
        "target_rmses": target_rmses,
        "measurement_center": measurement_center,
    }


class P05ModuleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        manifest = json.loads(
            (ROOT / "curriculum/modules.json").read_text(encoding="utf-8")
        )
        cls.module = next(
            module for module in manifest["modules"] if module["id"] == "P05"
        )

    def read(self, name: str) -> str:
        return (MODULE_FOLDER / name).read_text(encoding="utf-8")

    def test_manifest_identity_and_permanent_implemented_state(self):
        self.assertEqual(self.module["number"], 5)
        self.assertEqual(self.module["title"], "Watch the Sample Mean Converge")
        self.assertEqual(self.module["guiding_question"], GUIDING_QUESTION)
        self.assertEqual(self.module["phase"], 2)
        self.assertEqual(
            self.module["folder"], str(MODULE_FOLDER.relative_to(ROOT))
        )
        self.assertEqual(self.module["implementation_batch"], "P05")
        self.assertEqual(self.module["prerequisites"], ["P04"])
        self.assertEqual(self.module["status"], "implemented")
        self.assertEqual(self.module["evidence_level"], "simulated")
        self.assertIn("**Status:** implemented", self.read("README.md"))
        module_table = (ROOT / "modules/README.md").read_text(encoding="utf-8")
        p05_row = next(
            line for line in module_table.splitlines() if line.startswith("| P05 |")
        )
        self.assertTrue(p05_row.endswith("| implemented |"), p05_row)

    def test_complete_artifact_set_and_guiding_question(self):
        for name in ARTIFACTS:
            with self.subTest(artifact=name):
                self.assertTrue((MODULE_FOLDER / name).is_file(), name)
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

    def test_model_is_transparent_bounded_and_presentation_free(self):
        model = self.read("model.m")
        normalized = " ".join(model.replace("...", "").split())
        for formula in (
            "expectedMeasurementCenterMillivolts = trueSignalMillivolts + calibrationBiasMillivolts",
            "measurementsMillivolts = expectedMeasurementCenterMillivolts + noiseStandardDeviationMillivolts * standardizedNoise",
            "cumsum(measurementsMillivolts) ./ observationCounts",
            "runningSampleMeanMillivolts - trueSignalMillivolts",
            "noiseStandardDeviationMillivolts ./ sqrt(observationCounts)",
            "calibrationBiasMillivolts ^ 2 + theoreticalStandardErrorMillivolts .^ 2",
        ):
            self.assertIn(formula, normalized)
        for contract in (
            "validateattributes",
            "P05:InvalidSampleCount",
            "P05:InvalidNoiseScale",
            "P05:InvalidSeed",
            "P05:InvalidNoiseFixture",
            "P05:SampleCountMismatch",
            "P05:ResourceBound",
            "P05:NumericalFailure",
            "maximumSampleCount = 50000",
            "seed > 4294967295",
            "onCleanup",
            "rng(seed, 'twister')",
            "randn(1, sampleCount)",
        ):
            self.assertIn(contract, model)
        self.assertLess(
            model.index("sampleCount > maximumSampleCount"),
            model.index("randn(1, sampleCount)"),
            "the sample cap must precede random allocation",
        )
        self.assertLess(
            model.index("sampleCount > maximumSampleCount"),
            model.index("observationCounts = 1:sampleCount"),
            "the sample cap must precede count-vector allocation",
        )
        self.assertLess(
            model.index("sampleCount > maximumSampleCount"),
            model.index("any(~isfinite(suppliedStandardizedNoise(:)))"),
            "the sample cap must precede supplied-vector scanning",
        )
        for presentation_call in (
            "figure",
            "plot",
            "bar",
            "uiaxes",
            "uifigure",
        ):
            self.assertIsNone(
                re.search(rf"\b{presentation_call}\s*\(", model, re.IGNORECASE),
                presentation_call,
            )

    def test_experiment_has_ordered_flow_two_independent_sweeps_and_broken_case(self):
        experiment = self.read("experiment.m")
        baseline = self.read("p05_baseline.m")
        lesson_script = self.read("lesson.m")
        lowered = experiment.lower()
        ordered_markers = (
            "%% read, then predict once",
            "%% deterministic baseline",
            "%% parameter sweep 1 - sample count only",
            "%% explain the first changed view",
            "%% reset, then parameter sweep 2 - noise standard deviation only",
            "%% explain the second changed view",
            "%% deliberately broken case - stable but biased calibration",
            "%% repair the broken case - remove the known calibration offset",
        )
        positions = [lowered.index(marker) for marker in ordered_markers]
        self.assertEqual(positions, sorted(positions))
        self.assertIn("sample_counts = [25 100 400]", experiment)
        self.assertIn(
            "noise_standard_deviations_millivolts = [1.0 4.0 8.0]",
            experiment,
        )
        self.assertIn("sample_counts(sweep_index)", experiment)
        self.assertIn(
            "noise_standard_deviations_millivolts(sweep_index)", experiment
        )
        self.assertIn("longest_record.measurements_millivolts(1:", experiment)
        self.assertIn("calibration_bias_millivolts = 3.0", experiment)
        self.assertIn("theoretical_target_rmse_millivolts", experiment)
        self.assertIn(
            "biased.measurements_millivolts - calibration_bias_millivolts",
            " ".join(experiment.split()),
        )
        for figure_name in (
            "P05 sweep 1: sample count only",
            "P05 sweep 2: noise scale only",
            "P05 broken case: calibration bias",
            "P05 repair: subtract known calibration offset",
            "P05 baseline: running sample mean",
        ):
            self.assertIn(figure_name, experiment + baseline)
        for label in (
            "Observation count n (samples)",
            "Sensor reading X_i (mV)",
            "Running sample mean (mV)",
            "Sample count N (samples)",
            "Noise RMS sigma (mV)",
            "Running-mean error (mV)",
            "Error scale at endpoint (mV)",
        ):
            self.assertIn(label, experiment + baseline)
        self.assertNotIn("close all", lowered)
        self.assertIn("findall(groot", experiment)
        self.assertEqual(experiment.count("Prediction:"), 1)
        self.assertEqual(lesson_script.count("Prediction:"), 1)
        self.assertIn("p05_baseline;", lesson_script)
        self.assertNotIn("experiment;", lesson_script)
        self.assertNotIn("interactive;", lesson_script)
        self.assertIn("Pause here", lesson_script)
        self.assertIn("need not be monotone", lowered)
        self.assertNotRegex(lowered, r"assert\([^\n]*abs\([^\n]*diff")

    def test_interactive_exposes_bounded_meaningful_controls(self):
        interactive = self.read("interactive.m")
        self.assertGreaterEqual(interactive.count("uispinner("), 2)
        self.assertGreaterEqual(interactive.count("uislider("), 2)
        self.assertIn("uibutton(", interactive)
        self.assertIn("Sample count N (samples)", interactive)
        self.assertIn("Noise RMS sigma (mV)", interactive)
        self.assertIn("Realization seed", interactive)
        self.assertIn("Calibration bias b (mV)", interactive)
        self.assertIn("'Limits', [25 1000]", interactive)
        self.assertIn("'Limits', [0.0 8.0]", interactive)
        self.assertIn("'Limits', [0 10000]", interactive)
        self.assertIn("'Limits', [-5.0 5.0]", interactive)
        self.assertGreaterEqual(
            interactive.count("'RoundFractionalValues', 'on'"), 2
        )
        self.assertIn("Reset baseline", interactive)
        self.assertIn("resetBaseline", interactive)
        self.assertIn("clear model", interactive)
        self.assertIn("modelFcn = @model", interactive)
        self.assertIn("existingUi = findall(groot", interactive)
        self.assertIn("out = modelFcn(", interactive)
        self.assertIn("stableSampleLimitsMillivolts = [-45 70]", interactive)
        self.assertIn("ylim(sampleAxes, sampleYLimitsMillivolts)", interactive)
        self.assertIn("stableMeanLimitsMillivolts = [-10 35]", interactive)
        self.assertIn("ylim(meanAxes, meanYLimitsMillivolts)", interactive)
        self.assertIn("theoretical SE", interactive)
        self.assertIn("target RMSE", interactive)

    def test_checks_cover_limits_failures_isolation_and_resource_bounds(self):
        checks = self.read("run_checks.m")
        for invariant in (
            "isequal(baselineA, baselineB)",
            "checkCallerRngState = rng",
            "restoreCheckCallerRng = onCleanup",
            "independentRunningMean",
            "independentMeasurements = [4 8 12 16 20]",
            "independentMeans = [4 6 8 10 12]",
            "wiggleNoise = [1 -1 1 -1]",
            "independentWiggleMeans = [16 12 40/3 12]",
            "Realized error may increase after another sample",
            "model(1, 12.0, 4.0",
            "model(25, 12.0, 0.0",
            "model(25, 12.0, 0.0, 505, 3.0",
            "prefix25",
            "prefix100",
            "prefix400",
            "quarter mean variance",
            "noiseOne",
            "noiseFour",
            "noiseEight",
            "translated",
            "independentBiasedRmse",
            "Subtracting a known calibration offset",
            "model must leave the caller RNG state unchanged",
            "P05:InvalidSampleCount",
            "P05:InvalidNoiseScale",
            "P05:InvalidSeed",
            "P05:SampleCountMismatch",
            "P05:InvalidNoiseFixture",
            "P05:ResourceBound",
            "1000000, realmax), 'P05:NumericalFailure'",
            "model(50000, 12.0, 0.0, 4294967295",
            "P05 checks passed.",
        ):
            self.assertIn(invariant, checks)

    def test_independent_sample_mean_behavior_and_limiting_cases(self):
        fixture = _sample_mean_reference(5, 12.0, 4.0, 0.0, [-2, -1, 0, 1, 2])
        self.assertEqual(fixture["measurements"], [4, 8, 12, 16, 20])
        self.assertEqual(fixture["running_means"], [4, 6, 8, 10, 12])
        self.assertEqual(fixture["target_errors"], [-8, -6, -4, -2, 0])
        self.assertAlmostEqual(fixture["standard_errors"][-1], 4 / math.sqrt(5))
        self.assertEqual(fixture["target_rmses"], fixture["standard_errors"])

        one_sample = _sample_mean_reference(1, 12.0, 4.0, 0.0, [2])
        self.assertEqual(one_sample["running_means"], [20])
        self.assertEqual(one_sample["standard_errors"], [4])

        zero_noise = _sample_mean_reference(4, 12.0, 0.0, 0.0, [9, -4, 2, 7])
        self.assertEqual(zero_noise["measurements"], [12.0] * 4)
        self.assertEqual(zero_noise["running_means"], [12.0] * 4)
        self.assertEqual(zero_noise["standard_errors"], [0.0] * 4)

        biased_zero_noise = _sample_mean_reference(
            4, 12.0, 0.0, 3.0, [9, -4, 2, 7]
        )
        self.assertEqual(biased_zero_noise["running_means"], [15.0] * 4)
        self.assertEqual(biased_zero_noise["target_errors"], [3.0] * 4)
        self.assertEqual(biased_zero_noise["target_rmses"], [3.0] * 4)

        low_noise = _sample_mean_reference(5, 12.0, 1.0, 0.0, [-2, -1, 0, 1, 2])
        high_noise = _sample_mean_reference(5, 12.0, 8.0, 0.0, [-2, -1, 0, 1, 2])
        for low_error, high_error in zip(
            low_noise["random_errors"], high_noise["random_errors"]
        ):
            self.assertAlmostEqual(high_error, 8 * low_error)
        for low_se, high_se in zip(
            low_noise["standard_errors"], high_noise["standard_errors"]
        ):
            self.assertAlmostEqual(high_se, 8 * low_se)

        biased = _sample_mean_reference(5, 12.0, 4.0, 3.0, [-2, -1, 0, 1, 2])
        for unbiased_mean, biased_mean in zip(
            fixture["running_means"], biased["running_means"]
        ):
            self.assertAlmostEqual(biased_mean - unbiased_mean, 3.0)
        self.assertAlmostEqual(
            biased["target_rmses"][-1], math.sqrt(3**2 + 4**2 / 5)
        )

        translated = _sample_mean_reference(5, 22.0, 4.0, 0.0, [-2, -1, 0, 1, 2])
        for original, shifted in zip(
            fixture["measurements"], translated["measurements"]
        ):
            self.assertEqual(shifted - original, 10.0)
        self.assertEqual(translated["target_errors"], fixture["target_errors"])

        self.assertAlmostEqual(4 / math.sqrt(400), (4 / math.sqrt(100)) / 2)
        self.assertAlmostEqual((4 / math.sqrt(400)) ** 2, (4 / math.sqrt(100)) ** 2 / 4)

        for malformed in (
            (0, 12.0, 4.0, 0.0, []),
            (2.5, 12.0, 4.0, 0.0, [0, 1]),
            (50_001, 12.0, 4.0, 0.0, [0]),
            (1, math.nan, 4.0, 0.0, [0]),
            (1, 12.0, math.inf, 0.0, [0]),
            (1, 12.0, -1.0, 0.0, [0]),
            (1, 12.0, 4.0, math.inf, [0]),
            (1, 1_000_001.0, 4.0, 0.0, [0]),
            (2, 12.0, 4.0, 0.0, [0]),
            (2, 12.0, 4.0, 0.0, [0, math.nan]),
            (1, 1_000_000.0, 1_000_000.0, 1_000_000.0, [sys.float_info.max]),
        ):
            with self.subTest(malformed=malformed):
                with self.assertRaises(ValueError):
                    _sample_mean_reference(*malformed)

    def test_realized_error_can_worsen_while_standard_error_shrinks(self):
        wiggle = _sample_mean_reference(
            4, 12.0, 4.0, 0.0, [1, -1, 1, -1]
        )
        self.assertEqual(wiggle["measurements"], [16.0, 8.0, 16.0, 8.0])
        self.assertEqual(wiggle["running_means"][0:2], [16.0, 12.0])
        self.assertAlmostEqual(wiggle["running_means"][2], 40 / 3)
        self.assertEqual(wiggle["running_means"][3], 12.0)
        self.assertGreater(
            abs(wiggle["target_errors"][2]),
            abs(wiggle["target_errors"][1]),
        )
        self.assertLess(
            wiggle["standard_errors"][2],
            wiggle["standard_errors"][1],
        )

    def test_tutor_text_is_concept_first_and_connects_prerequisite(self):
        readme = self.read("README.md")
        lesson = self.read("lesson.md")
        walkthrough = self.read("walkthrough.md")
        checks = self.read("checks.md")
        self.assertIn("P04 carefully separated exact", readme)
        self.assertIn("P04 used expected alarm counts", lesson)
        self.assertIn("X_i = mu + b + sigma Z_i", lesson)
        self.assertIn("SE(Xbar_n) = sigma / sqrt(n)", lesson)
        normalized_lesson = " ".join(lesson.lower().split())
        self.assertIn("normality is not required", normalized_lesson)
        self.assertIn("need not move monotonically", lesson)
        self.assertIn("precision", lesson)
        self.assertIn("accuracy", lesson)
        self.assertIn("zero-mean measurement-error assumption", checks)
        self.assertIn("one visual transition at a time", walkthrough)
        self.assertIn("## Teach-back", checks)
        self.assertIn("--checks-passed --teach-back", checks)
        self.assertIn("run_module_checks('P05')", lesson)
        self.assertIn(
            "not hard bounds and not confidence intervals", normalized_lesson
        )
        self.assertNotIn("central limit theorem", lesson.lower())

    def test_no_placeholder_or_opaque_toolbox_shortcut_remains(self):
        combined = "\n".join(self.read(name) for name in ARTIFACTS).lower()
        for placeholder in (
            "this module is curriculum-scaffolded",
            "p05 is scaffolded",
            "not implemented yet",
            "todo",
            "placeholder",
        ):
            self.assertNotIn(placeholder, combined)
        for opaque_call in (
            "normrnd",
            "fitdist",
            "makedist",
            "random",
            "datasample",
            "normfit",
            "bootstrp",
            "ttest",
            "movmean",
        ):
            self.assertIsNone(
                re.search(rf"\b{opaque_call}\s*\(", combined), opaque_call
            )

    def test_owned_text_files_have_exactly_one_terminal_newline(self):
        for name in ARTIFACTS:
            with self.subTest(artifact=name):
                content = (MODULE_FOLDER / name).read_bytes()
                self.assertTrue(content.endswith(b"\n"), name)
                self.assertFalse(content.endswith(b"\n\n"), name)
                self.assertNotIn(b"\r\n", content, name)

    def test_retained_evidence_has_required_claim_boundaries(self):
        evidence_path = ROOT / "docs/evidence/P05-2026-09-01.md"
        self.assertTrue(evidence_path.is_file(), "missing retained P05 evidence")
        evidence = evidence_path.read_text(encoding="utf-8")
        for heading in (
            "## Acceptance map",
            "## Exact validation commands and results",
            "## Figure, control, metric, and unit inventory",
            "## Changed invariants",
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
