# P03 lesson: See Covariance as Shared Motion

## Guiding question

What inputs, observable effects, and failure modes matter when you see Covariance as Shared Motion?

## Compounds on

P02 turned repeated numerical outcomes into marginal histograms. A histogram can show Sensor A's
spread and another can show Sensor B's spread, but separate histograms discard which readings arrived
together. P03 preserves each pair so shared motion remains observable.

## Mental model

Imagine two displacement sensors on one platform. First subtract each sensor's own record mean. For
pair `i`, the centered product is positive when both deviations point to the same side of their means
and negative when they point to opposite sides. Covariance averages those signed contributions:

```text
a_i = A_i - mean(A)                                      [mm]
b_i = B_i - mean(B)                                      [mm]
C_AB = (1/N) sum(a_i * b_i)                              [mm^2]
r_AB = C_AB / (sigma_A * sigma_B)                        [dimensionless]
```

This lesson uses the N-normalized covariance of the displayed finite record. The deterministic
drivers have exactly zero record mean, unit RMS, and zero cross-product before mixing, so the
controlled relation is visible: `C_AB = rho * sigma_A * sigma_B` and `r_AB = rho`. A common
unbiased sample-covariance estimator for IID sampling uses `N-1` instead; for this same
record its value is `N/(N-1)` times the displayed N-normalized moment.

## One prediction before the baseline

Predict how the paired-deviation cloud changes when `rho` moves from positive to negative. Name the
sign of most centered pairwise products before you run the baseline.

## Lever 1 — shared-motion coefficient

Reset all other inputs, then sweep `rho` through negative, zero, and positive values. Negative `rho`
makes opposite-side products dominate and tilts the cloud downward. Zero `rho` makes the two linear
drivers orthogonal. Positive `rho` makes same-side products dominate and tilts the cloud upward.
At `rho = -1` or `rho = 1`, the covariance matrix reaches its singular limiting case because one
centered record is an exact scaled copy of the other.

## Lever 2 — Sensor B RMS scale

Reset `rho` and the seed, then change only Sensor B's RMS scale. Stretching B multiplies every
centered pairwise product and therefore covariance in `mm^2`. Correlation divides by both RMS scales,
so it stays fixed. This is why covariance magnitude cannot be compared across unit or gain changes
without also inspecting scale.

## Broken assumption

The shortcut `mean(A .* B)` equals covariance only when both records already have zero mean. In the
broken fixture the centered records are orthogonal and have zero covariance, but their constant
40 mm and 30 mm offsets make the raw cross-moment about `1200 mm^2`. Centering removes the offsets
and recovers zero covariance; that result does not claim statistical independence.

## Common mistakes

- Positive covariance describes linear co-motion in paired data; it does not establish causation.
- Zero covariance rules out a linear centered-product trend, not every nonlinear dependence.
- Covariance carries the product of the input units; correlation is dimensionless.
- Separate histograms cannot recover covariance after observation pairing is discarded.
- Reordering or time-shifting one record changes the pairs and can change covariance.
- The sign of one product is not the result; covariance averages all centered pair contributions.
- Even a majority of positive products does not determine covariance; their signed magnitudes matter.
- The exact finite-record moments here come from a constructed controlled experiment, not from
  sampling-variability evidence about a covariance estimator.

## Completion standard

Run the experiment one transition at a time, manipulate each lever independently, diagnose the
uncentered broken case, run `run_module_checks('P03')` from the repository root in MATLAB, and give
the two-sentence teach-back in `checks.md`. Static repository checks and independent reference
arithmetic do not satisfy the MATLAB-runtime step.
