# P05 — Watch the Sample Mean Converge

**Track:** Probability, Statistics, Estimation, and Detection  
**Phase 2:** Sampling and inference  
**Status:** implemented

## Guiding question

What inputs, observable effects, and failure modes matter when you watch the Sample Mean Converge?

## Compounds on

P04 carefully separated exact probability-scaled expected counts from sampled evidence. P05 now
generates actual noisy numerical observations and asks how their finite-sample average relates to a
fixed physical target. P04's model lesson carries forward too: correct arithmetic cannot rescue a
wrong assumption about the measurements.

## Physical mental model

A sensor repeatedly measures a constant 12 mV signal. Each reading has a zero-mean random component
with RMS scale `sigma`, and the sensor may also have a fixed calibration offset `b`:

```text
X_i = mu + b + sigma Z_i

Xbar_n = (X_1 + ... + X_n) / n
E[Xbar_n] = mu + b
SE(Xbar_n) = sigma / sqrt(n)
target RMSE = sqrt(b^2 + sigma^2/n)
```

The deterministic baseline uses 400 readings, `mu = 12 mV`, `sigma = 4 mV`, seed 505, and
`b = 0 mV`. Individual readings keep their 4 mV noise scale. The sample mean does not become
monotonically closer on every step, but its theoretical random-error scale falls from 4 mV at one
reading to 0.2 mV at 400 readings.

The standard normal driver is a transparent baseline convenience, not a requirement for the law of
large numbers. The convergence interpretation needs a stable measurement mean; the
`sigma/sqrt(n)` scale additionally uses independent readings with a finite, stable variance.

## Controlled levers

- **Sample count:** compares endpoints at 25, 100, and 400 observations using prefixes of the same
  seeded record. Four times as many independent observations halves standard error.
- **Noise RMS scale:** compares 1, 4, and 8 mV while preserving sample count, target, seed, bias, and
  standardized noise. It linearly stretches both readings and random mean error.
- **Calibration bias:** is exposed in the interactive explorer and the broken case. It changes the
  center the sample mean approaches without changing random standard error.

## Observable views and metrics

- sensor readings and running sample mean versus observation count;
- true 12 mV target and the expected measurement center in mV;
- theoretical standard error `sigma/sqrt(n)` and target RMSE in mV;
- final sample mean, target error, random error, and estimator scales in mV;
- fixed-input sweep views that separate sample-count and noise-scale effects.

The `+/-2 SE` curves are reference scales, not deterministic bounds or confidence intervals. One
seeded path illustrates the mechanism; it does not prove convergence or represent all paths.

## Deliberately broken case

A sensor with a fixed `+3 mV` calibration offset produces a running mean that becomes stable near
15 mV even though the true signal is 12 mV. The law of large numbers is not broken: it correctly
targets the biased measurement mean. The broken inference is assuming measurement error has zero
mean and treating precision as accuracy. More repeats shrink random error but cannot remove a common
offset. The repair subtracts an offset established by separate calibration data.

## Files and dependencies

- `model.m` explicitly constructs measurements, cumulative means, standard error, and target RMSE;
  validates all inputs before bounded allocation; supports exact supplied-noise fixtures; and
  restores the caller RNG state.
- `p05_baseline.m` owns one deterministic two-view baseline transition.
- `experiment.m` contains the baseline, independent sample-count and noise-scale sweeps,
  mechanism-first explanations, the biased case, and its calibration repair.
- `interactive.m` exposes bounded sample-count, noise, seed, and calibration-bias controls plus a
  baseline reset.
- `lesson.m`, `lesson.md`, and `walkthrough.md` implement the concept-first tutor flow.
- `checks.md` and `run_checks.m` contain interpretation prompts and executable invariants.

The implementation uses base MATLAB operations. Static source inspection and independent Python
reference arithmetic are not evidence that MATLAB figures, controls, or executable checks ran.
