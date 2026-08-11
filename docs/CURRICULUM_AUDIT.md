# Curriculum readiness audit

**Track:** Probability, Statistics, Estimation, and Detection

## Baseline conclusion

The repository has 24 uniquely identified modules in a six-phase, prerequisite-ordered sequence. P01 is the complete reference slice; P02-P24 are explicit non-runnable batch scaffolds. The learner flow is read → visualize → move one lever → visualize the delta → read/explain, followed by a broken case, checks, and teach-back.

Static structure and CLI behavior are verified in CI. MATLAB was not available during the 2026-08-11 baseline audit, so numerical execution, UI behavior, and instructional efficacy remain named validation gaps rather than implied evidence.

## Coverage and compounding order

### Phase 1: Probability you can see

- **P01 — Watch Randomness Stabilize with Repetition:** What does repetition reveal about random variation?
- **P02 — Turn Random Variables into Histograms:** What inputs, observable effects, and failure modes matter when you turn Random Variables into Histograms?
- **P03 — See Covariance as Shared Motion:** What inputs, observable effects, and failure modes matter when you see Covariance as Shared Motion?
- **P04 — Update Beliefs with Bayes' Rule:** What inputs, observable effects, and failure modes matter when you update Beliefs with Bayes' Rule?

### Phase 2: Sampling and inference

- **P05 — Watch the Sample Mean Converge:** What inputs, observable effects, and failure modes matter when you watch the Sample Mean Converge?
- **P06 — Make the Central Limit Theorem Visible:** What inputs, observable effects, and failure modes matter when you make the Central Limit Theorem Visible?
- **P07 — Build and Interpret Confidence Intervals:** What inputs, observable effects, and failure modes matter when you build and Interpret Confidence Intervals?
- **P08 — Test a Claim Without Confusing Significance and Importance:** What inputs, observable effects, and failure modes matter when you test a Claim Without Confusing Significance and Importance?

### Phase 3: Regression and estimation

- **P09 — Fit a Line with Least Squares:** What inputs, observable effects, and failure modes matter when you fit a Line with Least Squares?
- **P10 — Estimate Parameters by Maximum Likelihood:** What inputs, observable effects, and failure modes matter when you estimate Parameters by Maximum Likelihood?
- **P11 — Combine Prior Knowledge with Data:** What inputs, observable effects, and failure modes matter when you combine Prior Knowledge with Data?
- **P12 — See Regularization Trade Bias for Variance:** What inputs, observable effects, and failure modes matter when you see Regularization Trade Bias for Variance?

### Phase 4: Detection and decisions

- **P13 — Move a Threshold Along an ROC Curve:** What inputs, observable effects, and failure modes matter when you move a Threshold Along an ROC Curve?
- **P14 — Detect a Known Signal in Noise:** What inputs, observable effects, and failure modes matter when you detect a Known Signal in Noise?
- **P15 — Find a Change Point in a Data Stream:** What inputs, observable effects, and failure modes matter when you find a Change Point in a Data Stream?
- **P16 — Control False Discoveries Across Many Tests:** What inputs, observable effects, and failure modes matter when you control False Discoveries Across Many Tests?

### Phase 5: Time series and state estimation

- **P17 — Reveal Correlation Across Time:** What inputs, observable effects, and failure modes matter when you reveal Correlation Across Time?
- **P18 — Build an Autoregressive Process:** What inputs, observable effects, and failure modes matter when you build an Autoregressive Process?
- **P19 — Track a Hidden State with a Kalman Filter:** What inputs, observable effects, and failure modes matter when you track a Hidden State with a Kalman Filter?
- **P20 — Approximate a Nonlinear Posterior with Particles:** What inputs, observable effects, and failure modes matter when you approximate a Nonlinear Posterior with Particles?

### Phase 6: Engineering statistics

- **P21 — Propagate Measurement Uncertainty:** What inputs, observable effects, and failure modes matter when you propagate Measurement Uncertainty?
- **P22 — Design an Efficient Experiment:** What inputs, observable effects, and failure modes matter when you design an Efficient Experiment?
- **P23 — Model Reliability and Time to Failure:** What inputs, observable effects, and failure modes matter when you model Reliability and Time to Failure?
- **P24 — Run a Monte Carlo Engineering Trade Study:** What inputs, observable effects, and failure modes matter when you run a Monte Carlo Engineering Trade Study?

## Batch readiness gates

A scaffold may become `implemented` only when it has a deterministic model, a sectioned experiment, two independent parameter sweeps, one deliberately broken case, interactive controls, interpretation-focused tutor text, numerical checks, focused static tests, and evidence that says exactly what did and did not run.
