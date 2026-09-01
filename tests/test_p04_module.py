from __future__ import annotations

import json
import math
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULE_FOLDER = ROOT / "modules/04-update-beliefs-with-bayes-rule"
GUIDING_QUESTION = (
    "What inputs, observable effects, and failure modes matter when you update "
    "Beliefs with Bayes' Rule?"
)
ARTIFACTS = (
    "README.md",
    "lesson.m",
    "model.m",
    "p04_baseline.m",
    "experiment.m",
    "interactive.m",
    "lesson.md",
    "walkthrough.md",
    "checks.md",
    "run_checks.m",
)


def _bayes_reference(prior, sensitivity, false_alarm, population=10000):
    """Independent Python arithmetic; it does not execute or translate MATLAB."""
    probabilities = (prior, sensitivity, false_alarm)
    if any(
        not isinstance(value, (int, float))
        or isinstance(value, bool)
        or not math.isfinite(value)
        for value in probabilities
    ):
        raise ValueError("probabilities must be finite real scalars")
    if any(value < 0 or value > 1 for value in probabilities):
        raise ValueError("probabilities must be in [0, 1]")
    if (
        not isinstance(population, int)
        or isinstance(population, bool)
        or population < 1
        or population > 10_000_000
    ):
        raise ValueError("population must be a bounded positive integer")

    healthy_prior = 1 - prior
    joint_fault_alarm = prior * sensitivity
    joint_fault_no_alarm = prior * (1 - sensitivity)
    joint_healthy_alarm = healthy_prior * false_alarm
    joint_healthy_no_alarm = healthy_prior * (1 - false_alarm)
    alarm_probability = joint_fault_alarm + joint_healthy_alarm
    if alarm_probability == 0:
        raise ValueError("the observed alarm is impossible")
    posterior_fault = joint_fault_alarm / alarm_probability
    posterior_healthy = joint_healthy_alarm / alarm_probability
    prior_odds = math.inf if healthy_prior == 0 else prior / healthy_prior
    likelihood_ratio = (
        math.inf if false_alarm == 0 else sensitivity / false_alarm
    )
    posterior_odds = (
        math.inf
        if posterior_healthy == 0
        else posterior_fault / posterior_healthy
    )
    joints = (
        joint_fault_alarm,
        joint_fault_no_alarm,
        joint_healthy_alarm,
        joint_healthy_no_alarm,
    )
    return {
        "joints": joints,
        "alarm_probability": alarm_probability,
        "posterior_fault": posterior_fault,
        "posterior_healthy": posterior_healthy,
        "prior_odds": prior_odds,
        "likelihood_ratio": likelihood_ratio,
        "posterior_odds": posterior_odds,
        "fault_alarm_count": population * joint_fault_alarm,
        "healthy_alarm_count": population * joint_healthy_alarm,
    }


class P04ModuleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        manifest = json.loads(
            (ROOT / "curriculum/modules.json").read_text(encoding="utf-8")
        )
        cls.module = next(
            module for module in manifest["modules"] if module["id"] == "P04"
        )

    def read(self, name: str) -> str:
        return (MODULE_FOLDER / name).read_text(encoding="utf-8")

    def test_manifest_identity_and_permanent_implemented_state(self):
        self.assertEqual(self.module["number"], 4)
        self.assertEqual(self.module["title"], "Update Beliefs with Bayes' Rule")
        self.assertEqual(self.module["guiding_question"], GUIDING_QUESTION)
        self.assertEqual(self.module["phase"], 1)
        self.assertEqual(
            self.module["folder"], str(MODULE_FOLDER.relative_to(ROOT))
        )
        self.assertEqual(self.module["implementation_batch"], "P04")
        self.assertEqual(self.module["prerequisites"], ["P03"])
        self.assertEqual(self.module["status"], "implemented")
        self.assertEqual(self.module["evidence_level"], "simulated")
        self.assertIn("**Status:** implemented", self.read("README.md"))
        module_table = (ROOT / "modules/README.md").read_text(encoding="utf-8")
        p04_row = next(
            line for line in module_table.splitlines() if line.startswith("| P04 |")
        )
        self.assertTrue(p04_row.endswith("| implemented |"), p04_row)

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
            "priorFaultProbability * alarmGivenFaultProbability",
            "priorFaultProbability * (1 - alarmGivenFaultProbability)",
            "priorHealthyProbability * alarmGivenHealthyProbability",
            "priorHealthyProbability * (1 - alarmGivenHealthyProbability)",
            "jointFaultAlarmProbability + jointHealthyAlarmProbability",
            "jointFaultAlarmProbability / alarmProbability",
            "jointHealthyAlarmProbability / alarmProbability",
            "alarmGivenFaultProbability / alarmGivenHealthyProbability",
            "referencePopulationCount * jointFaultAlarmProbability",
            "sum(jointProbabilities) - 1",
        ):
            self.assertIn(formula, model)
        for contract in (
            "validateattributes",
            "P04:InvalidProbability",
            "P04:ImpossibleObservation",
            "P04:ResourceBound",
            "P04:NumericalFailure",
            "referencePopulationCount > 10000000",
            "alarmProbability == 0",
            "positiveLikelihoodRatio = Inf",
            "posteriorFaultOdds = Inf",
        ):
            self.assertIn(contract, model)
        self.assertLess(
            model.index("referencePopulationCount > 10000000"),
            model.index("expectedFaultCount ="),
            "the resource bound must precede count calculations",
        )
        self.assertLess(
            model.index("probabilityInputs < 0"),
            model.index("jointFaultAlarmProbability ="),
            "probability validation must precede Bayes arithmetic",
        )
        for forbidden_call in (
            "figure",
            "plot",
            "bar",
            "uiaxes",
            "uifigure",
            "rng",
            "rand",
            "randn",
        ):
            self.assertIsNone(
                re.search(rf"\b{forbidden_call}\s*\(", model, re.IGNORECASE),
                forbidden_call,
            )

    def test_experiment_has_ordered_flow_two_independent_sweeps_and_broken_case(self):
        experiment = self.read("experiment.m")
        baseline = self.read("p04_baseline.m")
        lesson_script = self.read("lesson.m")
        lowered = experiment.lower()
        ordered_markers = (
            "%% read, then predict once",
            "%% deterministic baseline",
            "%% parameter sweep 1 - prior fault probability only",
            "%% explain the first changed view",
            "%% reset, then parameter sweep 2 - false-alarm probability only",
            "%% explain the second changed view",
            "%% deliberately broken case - silently assume equal prior odds",
            "%% repair the broken case - weight both alarm paths by their priors",
        )
        positions = [lowered.index(marker) for marker in ordered_markers]
        self.assertEqual(positions, sorted(positions))
        self.assertIn(
            "prior_fault_probabilities = [0.001 0.010 0.100]", experiment
        )
        self.assertIn(
            "alarm_given_healthy_probabilities = [0.01 0.10 0.30]",
            experiment,
        )
        self.assertIn("prior_fault_probabilities(sweep_index)", experiment)
        self.assertIn(
            "alarm_given_healthy_probabilities(sweep_index)", experiment
        )
        self.assertGreaterEqual(
            experiment.count("alarm_given_fault_probability = 0.90;"), 5
        )
        self.assertGreaterEqual(
            experiment.count("reference_population_count = 10000;"), 5
        )
        self.assertIn("broken_equal_prior_posterior", experiment)
        self.assertIn("alarm_given_fault_probability /", experiment)
        self.assertIn("expected_fault_alarm_count / repaired.expected_alarm_count", experiment)
        self.assertGreaterEqual(experiment.count("figure("), 4)
        self.assertIn("baseline = p04_baseline(", experiment)
        for label in (
            "Prior fault probability (%)",
            "Posterior fault probability after alarm (%)",
            "False-alarm probability P(alarm | healthy) (%)",
            "Expected positive alarms per 10000 systems (count)",
            "Expected alarms per 10000 systems (count)",
        ):
            self.assertIn(label, experiment + baseline)
        self.assertIn("posterior fault = %.2f%%", baseline)
        self.assertIn("fault alarms +", baseline)
        presentation = experiment + baseline + self.read("interactive.m")
        self.assertNotIn("close all", presentation.lower())
        self.assertIn("findall(groot", experiment)
        self.assertIn(
            "baselineFigureName = 'P04 baseline: alarm sources update belief';",
            baseline,
        )
        self.assertIn("'Name', baselineFigureName", baseline)
        self.assertNotIn("'-regexp'", baseline)
        self.assertEqual(experiment.count("Prediction:"), 1)
        self.assertEqual(lesson_script.count("Prediction:"), 1)
        self.assertIn("p04_baseline;", lesson_script)
        self.assertNotIn("experiment;", lesson_script)
        self.assertNotIn("interactive;", lesson_script)
        self.assertIn("Pause here", lesson_script)

    def test_interactive_exposes_bounded_meaningful_controls(self):
        interactive = self.read("interactive.m")
        self.assertGreaterEqual(interactive.count("uislider("), 3)
        self.assertIn("uibutton(", interactive)
        self.assertIn("Prior fault probability (dimensionless)", interactive)
        self.assertIn(
            "Sensitivity P(alarm | fault) (dimensionless)", interactive
        )
        self.assertIn(
            "False-alarm P(alarm | healthy) (dimensionless)", interactive
        )
        self.assertIn("'Limits', [0.001 0.50]", interactive)
        self.assertIn("'Limits', [0.05 1.00]", interactive)
        self.assertIn("'Limits', [0.00 0.50]", interactive)
        self.assertIn("Reset baseline", interactive)
        self.assertIn("resetBaseline", interactive)
        self.assertIn("clear model", interactive)
        self.assertIn("modelFcn = @model", interactive)
        self.assertIn("existingUi = findall(groot", interactive)
        self.assertIn("out = modelFcn(", interactive)
        self.assertIn("referencePopulationCount = 10000", interactive)
        self.assertIn("ylim(sourceAxes, [0 5500])", interactive)
        self.assertIn("Fault probability (%)", interactive)
        self.assertIn("Expected alarms per 10000 systems (count)", interactive)
        self.assertIn("posterior P(fault | alarm)", interactive)

    def test_checks_cover_limits_failures_isolation_and_resource_bounds(self):
        checks = self.read("run_checks.m")
        self.assertGreaterEqual(checks.count("assert("), 25)
        for invariant in (
            "isequal(baselineA, baselineB)",
            "checkCallerRngState = rng",
            "restoreCheckCallerRng = onCleanup",
            "independentJointFaultAlarm",
            "jointTotal",
            "law of total probability",
            "posterior alarm sources must sum to one",
            "1/12",
            "abs(baselineA.expected_alarm_count - 1080) < 1e-10",
            "prior_fault_odds *",
            "positive_likelihood_ratio",
            "model(0.37, 0.25, 0.25",
            "model(0.0, 0.90, 0.10",
            "model(1.0, 0.90, 0.10",
            "model(0.01, 0.90, 0.0",
            "model(0.01, 0.0, 0.10",
            "priorLow",
            "falseAlarmLow",
            "brokenEqualPriorPosterior",
            "doublePopulation",
            "model must leave the caller RNG state unchanged",
            "P04:InvalidProbability",
            "P04:ImpossibleObservation",
            "P04:ResourceBound",
            "model(0.01, 0.90, 0.10, 1)",
            "model(0.01, 0.90, 0.10, 10000000)",
            "P04 checks passed.",
        ):
            self.assertIn(invariant, checks)

    def test_independent_bayes_behavior_and_limiting_cases(self):
        for malformed in (
            (math.nan, 0.9, 0.1, 10000),
            (0.01, math.inf, 0.1, 10000),
            (-0.01, 0.9, 0.1, 10000),
            (0.01, 1.01, 0.1, 10000),
            (0.01, 0.9, -0.1, 10000),
            (0.01, 0.9, 0.1, 0),
            (0.01, 0.9, 0.1, 1.5),
            (0.01, 0.9, 0.1, 10_000_001),
        ):
            with self.subTest(malformed=malformed):
                with self.assertRaises(ValueError):
                    _bayes_reference(*malformed)
        with self.assertRaisesRegex(ValueError, "impossible"):
            _bayes_reference(0.4, 0.0, 0.0)
        with self.assertRaisesRegex(ValueError, "impossible"):
            _bayes_reference(1.0, 0.0, 0.5)

        baseline = _bayes_reference(0.01, 0.90, 0.10)
        self.assertAlmostEqual(sum(baseline["joints"]), 1.0)
        self.assertAlmostEqual(baseline["alarm_probability"], 0.108)
        self.assertAlmostEqual(baseline["posterior_fault"], 1 / 12)
        self.assertAlmostEqual(baseline["posterior_healthy"], 11 / 12)
        self.assertAlmostEqual(baseline["fault_alarm_count"], 90.0)
        self.assertAlmostEqual(baseline["healthy_alarm_count"], 990.0)
        self.assertAlmostEqual(
            baseline["prior_odds"] * baseline["likelihood_ratio"],
            baseline["posterior_odds"],
        )

        uninformative = _bayes_reference(0.37, 0.25, 0.25)
        self.assertAlmostEqual(uninformative["posterior_fault"], 0.37)
        self.assertEqual(_bayes_reference(0.0, 0.9, 0.1)["posterior_fault"], 0)
        self.assertEqual(_bayes_reference(1.0, 0.9, 0.1)["posterior_fault"], 1)
        perfect_specificity = _bayes_reference(0.01, 0.9, 0.0)
        self.assertEqual(perfect_specificity["posterior_fault"], 1)
        self.assertTrue(math.isinf(perfect_specificity["likelihood_ratio"]))
        self.assertEqual(_bayes_reference(0.01, 0.0, 0.1)["posterior_fault"], 0)

        prior_sweep = [
            _bayes_reference(prior, 0.9, 0.1)["posterior_fault"]
            for prior in (0.001, 0.01, 0.1)
        ]
        self.assertLess(prior_sweep[0], prior_sweep[1])
        self.assertLess(prior_sweep[1], prior_sweep[2])
        false_alarm_sweep = [
            _bayes_reference(0.01, 0.9, rate)["posterior_fault"]
            for rate in (0.01, 0.1, 0.3)
        ]
        self.assertGreater(false_alarm_sweep[0], false_alarm_sweep[1])
        self.assertGreater(false_alarm_sweep[1], false_alarm_sweep[2])

        equal_prior = _bayes_reference(0.5, 0.9, 0.1)
        broken_shortcut = 0.9 / (0.9 + 0.1)
        self.assertAlmostEqual(equal_prior["posterior_fault"], broken_shortcut)
        self.assertGreater(
            broken_shortcut - baseline["posterior_fault"], 0.80
        )
        doubled = _bayes_reference(0.01, 0.9, 0.1, 20000)
        self.assertEqual(
            doubled["fault_alarm_count"], 2 * baseline["fault_alarm_count"]
        )
        self.assertEqual(
            doubled["healthy_alarm_count"], 2 * baseline["healthy_alarm_count"]
        )
        self.assertEqual(doubled["posterior_fault"], baseline["posterior_fault"])

    def test_tutor_text_is_concept_first_and_connects_prerequisite(self):
        readme = self.read("README.md")
        lesson = self.read("lesson.md")
        walkthrough = self.read("walkthrough.md")
        checks = self.read("checks.md")
        self.assertIn("P03 preserved paired observations", readme)
        self.assertIn("association such as covariance", lesson)
        self.assertIn("P(alarm | fault)", lesson)
        self.assertIn("P(fault | alarm)", lesson)
        self.assertIn("J_FA = P(fault)", lesson)
        self.assertIn("1/12 = 8.33%", readme)
        self.assertIn("Do not reuse and multiply marginal single-alarm", lesson)
        self.assertIn("calibrated joint or conditional likelihood", lesson)
        self.assertIn("one visual transition at a time", walkthrough)
        self.assertIn("Name the equal-prior assumption", checks)
        self.assertIn("## Teach-back", checks)
        self.assertIn("--checks-passed --teach-back", checks)
        self.assertIn("run_module_checks('P04')", lesson)

    def test_no_placeholder_or_opaque_toolbox_shortcut_remains(self):
        combined = "\n".join(self.read(name) for name in ARTIFACTS).lower()
        for placeholder in (
            "this module is curriculum-scaffolded",
            "p04 is scaffolded",
            "not implemented yet",
            "todo",
            "placeholder",
        ):
            self.assertNotIn(placeholder, combined)
        for opaque_call in (
            "bayesopt",
            "fitdist",
            "makedist",
            "binopdf",
            "betapdf",
            "binocdf",
            "mnrnd",
            "confusionmat",
            "perfcurve",
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
        evidence_path = ROOT / "docs/evidence/P04-2026-09-01.md"
        self.assertTrue(evidence_path.is_file(), "missing retained P04 evidence")
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
