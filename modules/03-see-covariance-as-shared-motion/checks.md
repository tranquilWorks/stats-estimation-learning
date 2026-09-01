# P03 checks: See Covariance as Shared Motion

## Baseline observation

Choose one paired observation in the baseline. What sign does its centered product have, what are its
units, and how does that contribution agree with the trace and scatter views?

## Lever checks

1. With seed and RMS scales fixed, why does changing `rho` reverse the cloud tilt and covariance sign?
2. After resetting the baseline, why does multiplying only Sensor B's RMS scale multiply covariance while leaving correlation unchanged?

## Numerical and limiting-case interpretation

- Why must `abs(C_AB) <= sigma_A * sigma_B`, and what happens at `rho = -1` and `rho = 1`?
- Why is the covariance-matrix determinant nonnegative, reaching zero at perfect linear co-motion?
- Why is the common `N-1` sample-covariance value `N/(N-1)` times this lesson's N-normalized record moment?
- Why does adding a constant offset to either record leave centered covariance unchanged?
- How can `B = A^2` be dependent on A while a symmetric record still has zero covariance?
- Why can separate P02-style marginal histograms not recover which A and B readings were paired?

## Broken-case check

The two broken-case motions have `rho = 0`, but their 40 mm and 30 mm offsets make `mean(A .* B)`
about `1200 mm^2`. Name the zero-mean assumption that the shortcut violates. Then explain why
subtracting each record's own mean repairs the result without changing either motion's spread.

## Prerequisite and transfer

Connect P02's numerical outcomes and histogram spread to P03's paired deviations, then name one
measured system where a gain or unit change would alter covariance but not correlation.

## Executable check

From the repository root in MATLAB, run:

```matlab
run_module_checks('P03')
```

The checks cover seeded determinism, manual covariance/correlation identities, symmetry,
Cauchy-Schwarz and analytic positive-semidefinite bounds, N versus `N-1` normalization, zero and perfect-motion limits, translation and
scale behavior, both independent sweeps, the uncentered-offset failure, a nonlinear zero-covariance
fixture, caller-RNG isolation, malformed inputs, and resource bounds. All assertions must pass before
learner completion is recorded.

## Teach-back

In two sentences, answer: “What inputs, observable effects, and failure modes matter when you see
Covariance as Shared Motion?” State centering, signed paired products, and units first; state the
`rho`/scale consequences and one failure mode second.

After MATLAB checks pass and the teach-back is ready, record completion from the repository root:

```bash
./bin/learn complete P03 --checks-passed --teach-back "<mechanism and consequence>"
```
