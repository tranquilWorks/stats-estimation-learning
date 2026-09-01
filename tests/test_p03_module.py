from __future__ import annotations

import json
import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_FOLDER = ROOT / "modules/03-see-covariance-as-shared-motion"
GUIDING_QUESTION = (
    "What inputs, observable effects, and failure modes matter when you see "
    "Covariance as Shared Motion?"
)
ARTIFACTS = (
    "README.md",
    "lesson.m",
    "model.m",
    "p03_baseline.m",
    "experiment.m",
    "interactive.m",
    "lesson.md",
    "walkthrough.md",
    "checks.md",
    "run_checks.m",
)


def _covariance_reference(values_a, values_b):
    """Independent Python arithmetic; it does not execute or translate MATLAB."""
    if len(values_a) != len(values_b):
        raise ValueError("paired records must have equal lengths")
    if len(values_a) < 2:
        raise ValueError("at least two pairs are required")
    if any(not math.isfinite(value) for value in (*values_a, *values_b)):
        raise ValueError("paired records must be finite")

    count = len(values_a)
    mean_a = sum(values_a) / count
    mean_b = sum(values_b) / count
    centered_a = [value - mean_a for value in values_a]
    centered_b = [value - mean_b for value in values_b]
    products = [a * b for a, b in zip(centered_a, centered_b)]
    variance_a = sum(value * value for value in centered_a) / count
    variance_b = sum(value * value for value in centered_b) / count
    covariance = sum(products) / count
    denominator = math.sqrt(variance_a * variance_b)
    correlation = None if denominator == 0 else covariance / denominator
    return {
        "mean_a": mean_a,
        "mean_b": mean_b,
        "variance_a": variance_a,
        "variance_b": variance_b,
        "covariance": covariance,
        "correlation": correlation,
        "raw_cross_moment": sum(
            a * b for a, b in zip(values_a, values_b)
        )
        / count,
        "products": products,
        "determinant": variance_a * variance_b - covariance * covariance,
        "n_minus_one_covariance": sum(products) / (count - 1),
    }


class P03ModuleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        manifest = json.loads(
            (ROOT / "curriculum/modules.json").read_text(encoding="utf-8")
        )
        cls.module = next(
            module for module in manifest["modules"] if module["id"] == "P03"
        )

    def read(self, name: str) -> str:
        return (MODULE_FOLDER / name).read_text(encoding="utf-8")

    def test_manifest_identity_and_permanent_implemented_state(self):
        self.assertEqual(self.module["number"], 3)
        self.assertEqual(self.module["title"], "See Covariance as Shared Motion")
        self.assertEqual(self.module["guiding_question"], GUIDING_QUESTION)
        self.assertEqual(self.module["phase"], 1)
        self.assertEqual(self.module["folder"], str(MODULE_FOLDER.relative_to(ROOT)))
        self.assertEqual(self.module["implementation_batch"], "P03")
        self.assertEqual(self.module["prerequisites"], ["P02"])
        self.assertEqual(self.module["status"], "implemented")
        self.assertEqual(self.module["evidence_level"], "simulated")
        self.assertIn("**Status:** implemented", self.read("README.md"))

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
        for formula in (
            "driverA = driverA - sum(driverA) / sampleCount",
            "projection = sum(driverA .* driverB) / sum(driverA .^ 2)",
            "driverB = driverB - projection * driverA",
            "orthogonalWeight = sqrt(max(0, 1 - sharedMotionCoefficient ^ 2))",
            "centeredProductMillimetersSquared =",
            "observedCenteredAMillimeters .* observedCenteredBMillimeters",
            "sum(centeredProductMillimetersSquared) / sampleCount",
            "correlationCoefficient = covarianceMillimetersSquared / correlationDenominator",
            "sharedMotionCoefficient * sigmaAMillimeters * sigmaBMillimeters",
            "sigmaAMillimeters ^ 2 * sigmaBMillimeters ^ 2",
            "(1 - sharedMotionCoefficient ^ 2)",
            "sum(centeredProductMillimetersSquared) / (sampleCount - 1)",
        ):
            self.assertIn(formula, model)
        for contract in (
            "validateattributes",
            "P03:InsufficientSamples",
            "P03:InvalidCorrelation",
            "P03:InvalidSeed",
            "P03:DegenerateDrivers",
            "P03:ResourceBound",
            "P03:NumericalFailure",
            "sampleCount > 50000",
            "maximumMeanToScaleRatio",
            "onCleanup",
            "randn(2, sampleCount)",
        ):
            self.assertIn(contract, model)
        self.assertLess(
            model.index("sampleCount > 50000"),
            model.index("randn(2, sampleCount)"),
            "the sample resource bound must precede random allocation",
        )
        self.assertLess(
            model.index("sharedMotionCoefficient < -1"),
            model.index("sqrt(max(0, 1 - sharedMotionCoefficient ^ 2))"),
            "rho validation must precede the square root",
        )
        for presentation_call in (
            "figure",
            "plot",
            "scatter",
            "uiaxes",
            "uifigure",
        ):
            self.assertIsNone(
                re.search(rf"\b{presentation_call}\s*\(", model, flags=re.IGNORECASE),
                presentation_call,
            )

    def test_experiment_has_ordered_flow_two_independent_sweeps_and_broken_case(self):
        experiment = self.read("experiment.m")
        baseline = self.read("p03_baseline.m")
        lesson_script = self.read("lesson.m")
        lowered = experiment.lower()
        ordered_markers = (
            "%% read, then predict once",
            "%% deterministic baseline",
            "%% parameter sweep 1 - shared-motion coefficient only",
            "%% explain the first changed view",
            "%% reset, then parameter sweep 2 - sensor b scale only",
            "%% explain the second changed view",
            "%% deliberately broken case",
            "%% repair the broken case",
        )
        positions = [lowered.index(marker) for marker in ordered_markers]
        self.assertEqual(positions, sorted(positions))
        self.assertIn("shared_motion_coefficients = [-0.80 0.00 0.80]", experiment)
        self.assertIn(
            "sigma_b_values_millimeters = [0.50 1.50 3.00]", experiment
        )
        self.assertIn("shared_motion_coefficients(sweep_index)", experiment)
        self.assertIn("sigma_b_values_millimeters(sweep_index)", experiment)
        self.assertIn("mean_a_millimeters = 40.0", experiment)
        self.assertIn("mean_b_millimeters = 30.0", experiment)
        self.assertIn("raw_cross_moment_millimeters_squared", experiment)
        self.assertIn("centered_product_millimeters_squared", experiment)
        self.assertIn("scale_limit_reference = model(", experiment)
        self.assertIn("max(sigma_b_values_millimeters)", experiment)
        self.assertIn(
            "xlim([-scale_x_limit_millimeters scale_x_limit_millimeters])",
            experiment,
        )
        self.assertIn(
            "ylim([-scale_y_limit_millimeters scale_y_limit_millimeters])",
            experiment,
        )
        self.assertGreaterEqual(experiment.count("figure("), 4)
        self.assertIn("baseline = p03_baseline(", experiment)
        for label in (
            "Observation index (sample)",
            "Centered displacement (mm)",
            "Sensor A deviation (mm)",
            "Sensor B deviation (mm)",
            "Cumulative centered-product average (mm^2)",
            "Uncentered product A_i B_i (mm^2)",
        ):
            self.assertIn(label, experiment + baseline)
        self.assertIn("covariance = %.3f mm^2", baseline)
        self.assertIn("correlation = %.3f", baseline)
        self.assertNotIn("close all", lowered)
        self.assertIn("findall(groot", experiment)
        self.assertIn("'^P03 '", experiment)
        self.assertIn("'^P03 '", baseline)
        self.assertEqual(experiment.count("Prediction:"), 1)
        self.assertEqual(lesson_script.count("Prediction:"), 1)
        self.assertIn("p03_baseline;", lesson_script)
        self.assertNotIn("experiment;", lesson_script)
        self.assertNotIn("interactive;", lesson_script)
        self.assertIn("Pause here", lesson_script)
        self.assertGreaterEqual(experiment.count("sample_count = 400;"), 5)
        self.assertGreaterEqual(experiment.count("seed = 303;"), 5)

    def test_interactive_exposes_bounded_meaningful_controls(self):
        interactive = self.read("interactive.m")
        self.assertIn("uislider(", interactive)
        self.assertGreaterEqual(interactive.count("uispinner("), 2)
        self.assertIn("Shared-motion coefficient rho (dimensionless)", interactive)
        self.assertIn("rho changes the signed weight", interactive)
        self.assertIn("Sensor B RMS scale (mm)", interactive)
        self.assertIn("Realization seed", interactive)
        self.assertIn("'Limits', [-0.95 0.95]", interactive)
        self.assertIn("'Limits', [0.25 4.00]", interactive)
        self.assertIn("'Limits', [0 10000]", interactive)
        self.assertIn("clear model", interactive)
        self.assertIn("modelFcn = @model", interactive)
        self.assertIn("existingUi = findall(groot", interactive)
        self.assertIn("out = modelFcn(", interactive)
        self.assertIn("visibleCount = min(sampleCount, 160)", interactive)
        self.assertIn("maximumInteractiveSigmaBMillimeters = 4.00", interactive)
        self.assertIn("unitScaleB = out.centered_b_millimeters", interactive)
        self.assertIn("stableYLimitMillimeters", interactive)
        self.assertIn("covariance = %.3f mm^2", interactive)
        self.assertIn("correlation = %.3f", interactive)

    def test_checks_cover_limits_failures_isolation_and_resource_bounds(self):
        checks = self.read("run_checks.m")
        self.assertGreaterEqual(checks.count("assert("), 20)
        for invariant in (
            "checkCallerRngState = rng",
            "restoreCheckCallerRng = onCleanup",
            "independentCovariance",
            "independentCorrelation",
            "Cauchy-Schwarz",
            "analytic_psd_margin_millimeters_fourth",
            "N/(N-1)",
            "model(400, 1.0",
            "model(400, -1.0",
            "model(400, 0.0",
            "4 * smallScale.centered_b_millimeters",
            "translation invariant",
            "raw_cross_moment_millimeters_squared - 1200.0",
            "covariance plus the product of means",
            "nonlinearB = nonlinearA .^ 2",
            "model must restore the caller RNG state for uniform and normal draws",
            "P03:InvalidCorrelation",
            "P03:InvalidSeed",
            "P03:ResourceBound",
            "model(3",
            "model(50000",
            "P03 checks passed.",
        ):
            self.assertIn(invariant, checks)

    def test_independent_covariance_behavior_and_limiting_cases(self):
        with self.assertRaisesRegex(ValueError, "equal lengths"):
            _covariance_reference((0.0, 1.0), (0.0,))
        with self.assertRaisesRegex(ValueError, "at least two"):
            _covariance_reference((0.0,), (0.0,))
        with self.assertRaisesRegex(ValueError, "finite"):
            _covariance_reference((0.0, math.nan), (0.0, 1.0))

        values_a = (-2.0, -1.0, 0.0, 1.0, 2.0)
        positive = _covariance_reference(
            values_a, (-4.0, -2.0, 0.0, 2.0, 4.0)
        )
        negative = _covariance_reference(
            values_a, (4.0, 2.0, 0.0, -2.0, -4.0)
        )
        self.assertEqual(positive, _covariance_reference(values_a, tuple(2 * x for x in values_a)))
        self.assertEqual(positive["variance_a"], 2.0)
        self.assertEqual(positive["variance_b"], 8.0)
        self.assertEqual(positive["covariance"], 4.0)
        self.assertEqual(positive["correlation"], 1.0)
        self.assertEqual(positive["determinant"], 0.0)
        self.assertEqual(positive["n_minus_one_covariance"], 5.0)
        self.assertEqual(
            positive["n_minus_one_covariance"],
            len(values_a) / (len(values_a) - 1) * positive["covariance"],
        )
        self.assertEqual(negative["covariance"], -4.0)
        self.assertEqual(negative["correlation"], -1.0)

        orthogonal_a = (-1.0, -1.0, 1.0, 1.0)
        orthogonal_b = (-1.0, 1.0, -1.0, 1.0)
        orthogonal = _covariance_reference(orthogonal_a, orthogonal_b)
        self.assertEqual(orthogonal["covariance"], 0.0)
        self.assertEqual(orthogonal["correlation"], 0.0)
        self.assertGreaterEqual(orthogonal["determinant"], 0.0)

        shifted = _covariance_reference(
            tuple(40.0 + x for x in orthogonal_a),
            tuple(30.0 + y for y in orthogonal_b),
        )
        self.assertEqual(shifted["covariance"], orthogonal["covariance"])
        self.assertEqual(shifted["correlation"], orthogonal["correlation"])
        self.assertEqual(shifted["raw_cross_moment"], 1200.0)
        self.assertEqual(
            shifted["n_minus_one_covariance"],
            len(orthogonal_a) / (len(orthogonal_a) - 1) * shifted["covariance"],
        )

        scaled = _covariance_reference(values_a, tuple(6 * x for x in values_a))
        self.assertEqual(scaled["covariance"], 3 * positive["covariance"])
        self.assertEqual(scaled["correlation"], positive["correlation"])

        nonlinear_a = tuple(range(-3, 4))
        nonlinear_b = tuple(value * value for value in nonlinear_a)
        nonlinear = _covariance_reference(nonlinear_a, nonlinear_b)
        self.assertEqual(nonlinear["covariance"], 0.0)
        self.assertEqual(nonlinear_b[0], nonlinear_b[-1])
        self.assertNotEqual(len(set(nonlinear_b)), 1)

        constant = _covariance_reference((1.0, 1.0), (0.0, 2.0))
        self.assertIsNone(constant["correlation"])

    def test_tutor_text_is_concept_first_and_connects_prerequisite(self):
        readme = self.read("README.md")
        lesson = self.read("lesson.md")
        walkthrough = self.read("walkthrough.md")
        checks = self.read("checks.md")
        self.assertIn("P02 showed", readme)
        self.assertIn("separate histograms discard", lesson)
        self.assertIn("C_AB = (1/N) sum(a_i * b_i)", lesson)
        self.assertIn("N/(N-1)", lesson)
        self.assertIn("Zero covariance rules out", lesson)
        self.assertIn("one visual transition at a time", walkthrough)
        self.assertIn("mechanism first", walkthrough)
        self.assertIn("## Teach-back", checks)
        self.assertIn("Name the zero-mean assumption", checks)
        self.assertIn("--checks-passed --teach-back", checks)
        self.assertIn("run_module_checks('P03')", lesson)

    def test_no_placeholder_or_opaque_toolbox_shortcut_remains(self):
        combined = "\n".join(self.read(name) for name in ARTIFACTS).lower()
        for placeholder in (
            "this module is curriculum-scaffolded",
            "p03 is scaffolded",
            "not implemented yet",
            "todo",
            "placeholder",
        ):
            self.assertNotIn(placeholder, combined)
        for opaque_call in (
            "cov",
            "corrcoef",
            "mvnrnd",
            "chol",
            "zscore",
            "normalize",
            "pca",
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
        evidence_path = ROOT / "docs/evidence/P03-2026-08-31.md"
        self.assertTrue(evidence_path.is_file(), "missing retained P03 evidence")
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
