# P05 lesson: Watch the Sample Mean Converge

## Guiding question

What inputs, observable effects, and failure modes matter when you watch the Sample Mean Converge?

## Compounds on

P04 used expected alarm counts to visualize exact probability mass and warned that those values were
not sampled observations. P05 takes the next step: repeated sensor readings are genuinely noisy, so
their finite average varies from one realization to another. P04's base-rate failure also carries a
modeling lesson forward—valid arithmetic can still answer the wrong physical question when an input
assumption is wrong.

## Mental model

Imagine repeatedly measuring a constant 12 mV reference signal. A reading contains a fixed target,
an optional common calibration offset, and fresh random noise:

```text
X_i = mu + b + sigma Z_i
Xbar_n = (1/n) sum_{i=1}^n X_i
```

For independent readings whose random component has zero mean and stable finite variance,

```text
E[Xbar_n] = mu + b
Var(Xbar_n) = sigma^2 / n
SE(Xbar_n) = sigma / sqrt(n)
```

All signal, error, bias, and standard-error values use millivolts. Observation count is measured in
samples; `Z_i` is dimensionless. Normal noise supplies a reproducible baseline, but normality is not
required for the law of large numbers. The plot shows one realization, so it illustrates the
mechanism rather than proving the theorem.

## One prediction before the baseline

At fixed `sigma = 4 mV`, predict what changes when sample count grows from 100 to 400. Does each raw
reading become less noisy, or does only the average's random-error scale change?

## Lever 1 — sample count

Keep the target, noise scale, seed, and bias fixed. Compare 25, 100, and 400 samples using prefixes
of one seeded record. The final theoretical standard errors are 0.8, 0.4, and 0.2 mV. Quadrupling
sample count halves standard error because variances of independent terms add while the average
divides by `n`.

The realized error need not decrease at every endpoint or every new reading. Convergence is a
probabilistic statement about concentration as `n` grows, not a promise of a smooth path.

## Lever 2 — noise RMS scale

Reset to 400 samples, 12 mV target, seed 505, and zero bias. Sweep `sigma` through 1, 4, and 8 mV.
The standardized noise values stay identical, so doubling `sigma` doubles each random deviation,
the entire running random-error path, and the theoretical standard error. Sample count did not
change in this sweep.

## Broken assumption — stable is not accurate

Set a common `+3 mV` calibration offset. The running mean tightens near the actual measurement mean
of 15 mV, not the 12 mV physical target. Its random standard error still reaches 0.2 mV, while its
target RMSE approaches the 3 mV bias floor:

```text
target RMSE = sqrt(b^2 + sigma^2/n)
```

This is precision without accuracy.

The law of large numbers still works: it targets `E[X] = mu + b`. The broken assumption is that
measurement error had zero mean. Repair a known bias by subtracting an offset established from
separate calibration data. If bias is unknown, gathering more readings under the same calibration
cannot identify or average it away.

## Common mistakes

- More samples do not make individual readings quieter; they reduce random error in their average.
- A running mean need not move monotonically toward its target.
- A stable estimate is precise, but it is accurate only if the measurement model is correctly
  centered on the physical target.
- The `+/-2 SE` curves are reference scales, not hard bounds and not confidence intervals.
- Changing the seed changes one realization, not the underlying target or noise scale.
- Dependence, drift, or common-mode errors can invalidate the independent stable-noise mechanism.
- The next module studies the shape of repeated sample-mean distributions; this module studies one
  running average and its scale only.

## Completion standard

Run the experiment one transition at a time, manipulate each lever independently, diagnose the
calibration-offset case, run `run_module_checks('P05')` from the repository root in MATLAB, and give
the two-sentence teach-back in `checks.md`. Static repository checks and independent reference
arithmetic do not satisfy the MATLAB-runtime step.
