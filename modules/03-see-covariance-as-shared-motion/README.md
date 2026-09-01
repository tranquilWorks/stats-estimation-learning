# P03 — See Covariance as Shared Motion

**Track:** Probability, Statistics, Estimation, and Detection  
**Phase 1:** Probability you can see  
**Status:** implemented

## Guiding question

What inputs, observable effects, and failure modes matter when you see Covariance as Shared Motion?

## Compounds on

P02 showed each sensor's distribution by grouping numerical outcomes into a histogram. P03 keeps
the observation pairs intact, centers both records, and asks whether their deviations move together.

## Physical mental model

Two displacement sensors observe a moving platform in millimetres. For paired observation `i`, a
positive centered product means both sensors are above their own means or both are below. A negative
product means they are on opposite sides. Averaging those signed contributions gives the
N-normalized record covariance

```text
C_AB = (1/N) sum((A_i - mean(A)) * (B_i - mean(B)))       [mm^2]
r_AB = C_AB / (sigma_A * sigma_B)                         [dimensionless]
```

The deterministic model builds two centered, unit-RMS, orthogonal seeded drivers. Sensor B combines
a shared part with an orthogonal sensor-specific part, making `C_AB = rho * sigma_A * sigma_B` and `r_AB = rho`
visible without a Statistics and Machine Learning Toolbox shortcut. This controlled record uses
`N` in the denominator; the common `N-1` sample-covariance estimate is larger by `N/(N-1)`.

## Controlled levers

- **Shared-motion coefficient `rho`:** changes the sign and linear tilt of paired motion while both
  RMS scales and the seeded base drivers stay fixed.
- **Sensor B RMS scale (mm):** stretches only Sensor B. Covariance changes in `mm^2`, while
  dimensionless correlation stays fixed.
- **Seed:** selects a repeatable arrangement of pairs; the model restores the caller's RNG state.

## Observable views and metrics

- paired centered displacement traces in `mm`;
- the Sensor A versus Sensor B deviation cloud in `mm` by `mm`;
- centered pairwise products and their cumulative full-record-centered average in `mm^2`;
- RMS scales, covariance, correlation, covariance-matrix determinant, and same-direction fraction.

The same-direction fraction is descriptive only. Covariance depends on the signed magnitudes of all
products, not on a majority vote over their signs.

## Deliberately broken case

The broken shortcut averages `A_i * B_i` without first centering either sensor. It assumes both
signals already have zero mean. Orthogonal zero-covariance records with 1 mm RMS scales placed on
40 mm and 30 mm offsets then produce a raw cross-moment near `1200 mm^2`. The
repair subtracts each record's own mean before multiplying.

## Files and dependencies

- `model.m` performs bounded seeded driver construction, manual centering, covariance/correlation
  calculations, raw cross-moment comparison, and caller-RNG restoration without plotting.
- `p03_baseline.m` owns the one deterministic baseline transition used by both entry paths.
- `experiment.m` contains the baseline, two independent sweeps, explanations, broken case, and repair.
- `interactive.m` exposes bounded `rho`, Sensor B scale, and seed controls while retaining the
  resolved P03 model handle for callbacks.
- `lesson.m`, `lesson.md`, and `walkthrough.md` implement the concept-first tutor flow.
- `checks.md` and `run_checks.m` contain interpretation prompts and executable invariants.

The implementation uses base MATLAB operations. Source inspection and independent Python reference
arithmetic are not evidence that MATLAB figures, controls, or executable checks ran.
