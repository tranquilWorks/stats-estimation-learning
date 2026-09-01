# P05 checks: Watch the Sample Mean Converge

## Baseline observation

At 400 readings, identify the raw 4 mV noise scale and the sample mean's 0.2 mV theoretical standard
error. Why can the raw samples remain widely scattered while the running average occupies a
narrower scale around the 12 mV target?

## Lever checks

1. With target, noise, seed, and bias fixed, why does increasing sample count from 25 to 100 to 400
   reduce standard error from 0.8 to 0.4 to 0.2 mV? Why is monotone realized error not required?
2. After resetting the baseline, why does changing only noise RMS from 1 to 4 to 8 mV linearly
   stretch both the same standardized running-error path and `sigma/sqrt(n)`?

## Numerical and limiting-case interpretation

- Derive the running sample mean directly from cumulative sums and show that its final value equals
  `sum(X_i)/N`.
- Why does quadrupling `N` quarter the variance and halve standard error?
- What happens at `N = 1`?
- What happens when `sigma = 0` with zero bias? What changes when bias is 3 mV?
- Why does shifting the true signal translate all readings and means without changing random error?
- Which assumptions support the `sigma/sqrt(n)` scale, and why is normality not required for the law
  of large numbers?
- Why are the two-standard-error curves scales rather than deterministic bounds or intervals?

## Broken-case check

The `+3 mV` calibration case becomes stable near 15 mV even though the physical target is 12 mV.
Name the violated zero-mean measurement-error assumption. Explain why random standard error shrinks
to 0.2 mV while target RMSE retains a 3 mV floor, then describe the separate calibration information
needed for the repair.

## Prerequisite and transfer

Connect P04's exact expected alarm counts to P05's sampled numerical estimates. Explain why correct
averaging cannot repair either a wrong Bayes model or a wrong sensor-center assumption. Then name one
measurement system where repeated readings could hide common calibration bias.

## Executable check

From the repository root in MATLAB, run:

```matlab
run_module_checks('P05')
```

The checks cover deterministic repetition, independent supplied-noise fixtures, cumulative-mean
arithmetic, an explicit case where realized error worsens while theoretical standard error shrinks,
theoretical standard error and target RMSE, same-seed prefixes, both independent sweeps, translation,
zero-noise and one-sample limits, fixed-bias failure and repair, caller-RNG isolation, malformed
inputs, supplied-fixture failures, and accepted/rejected resource boundaries. All assertions must
pass before learner completion is recorded.

## Teach-back

In two sentences, answer: “What inputs, observable effects, and failure modes matter when you watch
the Sample Mean Converge?” State how sample count and noise RMS control `sigma/sqrt(n)` first; state
why realized error can wiggle and why fixed calibration bias survives averaging second.

After MATLAB checks pass and the teach-back is ready, record completion from the repository root:

```bash
./bin/learn complete P05 --checks-passed --teach-back "<mechanism and consequence>"
```
