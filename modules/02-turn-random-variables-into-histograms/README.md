# P02 — Turn Random Variables into Histograms

**Track:** Probability, Statistics, Estimation, and Detection  
**Phase 1:** Probability you can see  
**Status:** implemented

## Guiding question

What inputs, observable effects, and failure modes matter when you turn Random Variables into Histograms?

## Compounds on

P01 showed that repeated random outcomes can reveal stable long-run structure. P02 keeps the
individual outcomes visible, then groups their numerical values into an empirical distribution.

## Physical mental model

Treat each outcome as a zero-mean sensor error measured in millivolts. A histogram partitions the
number line into intervals and counts how many errors land in each one. If bin `j` has width
`Delta x_j`, its probability mass and density height are

```text
p_j = count_j / N
h_j = count_j / (N * Delta x_j)
```

The density bar's area, `h_j * Delta x_j`, is probability. Raw heights are comparable only when
the intervals have equal widths.

## Controlled levers

- **Sample count `N` (samples):** changes how many independent observations support each bar while
  preserving the seeded prefix, generating spread, and bin width.
- **Bin width (mV):** changes the aggregation intervals while preserving the same seeded samples;
  the interactive choices also preserve the displayed -4 to 4 mV support.
- **Seed:** selects a repeatable realization so chance variation can be separated from lever effects.

## Observable views and metrics

- the measurement sequence before aggregation, in mV;
- empirical histogram density beside the transparent Gaussian generating density, in `1/mV`;
- bin counts, explicit underflow/overflow, included fraction, histogram area, sample mean,
  N-normalized empirical RMS spread, nominal bin-mass standard error, and a full L1
  probability-mass discrepancy that includes both tails.

## Deliberately broken case

Unequal-width bins are plotted first with raw count heights. Wide intervals collect more samples
simply because they cover more of the number line. The corrected view divides each probability mass
by its own width, restoring probability as area.

## Files and dependencies

- `model.m` performs seeded sampling, manual bin assignment, normalization, sign-stable Gaussian
  interval metrics, fail-fast validation, resource bounds, and caller-RNG restoration without plotting.
- `p02_baseline.m` presents the one deterministic baseline transition used by both entry paths.
- `experiment.m` contains the baseline, two independent sweeps, mechanism explanations, a broken
  case, and cleanup limited to P02-owned figures.
- `interactive.m` exposes bounded sample-count, fixed-support bin-width, and seed controls while
  retaining the resolved P02 model handle for its callbacks.
- `lesson.m`, `lesson.md`, and `walkthrough.md` implement the concept-first tutor flow.
- `checks.md` and `run_checks.m` contain interpretation prompts and executable invariants.

The implementation uses base MATLAB operations. See the retained P02 evidence for the validation
boundary; source inspection is not evidence of MATLAB runtime or UI behavior.
