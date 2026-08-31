# P02 checks: Turn Random Variables into Histograms

## Baseline observation

Trace one sensor-error sample from its value in the sequence plot to the interval that counts it.
What do the histogram's horizontal and vertical units mean?

## Lever checks

1. With bin width and seed fixed, why does increasing `N` change bar jitter without changing the generating spread?
2. After resetting the baseline, why can a narrower bin width reveal both more detail and more sampling noise even though the samples did not change?

## Numerical and limiting-case interpretation

- Why must `sum(counts) + underflow + overflow` equal `N`?
- If one 20 mV-wide bin contains every sample, what are its probability mass, density height, and area?
- Why does the density area equal the included fraction when finite display edges leave tail samples outside?
- Why does nominal bin-mass uncertainty shrink in proportion to `1/sqrt(N)`?
- Why must a full L1 discrepancy compare underflow and overflow as well as the visible bins?

## Broken-case check

The middle interval in the deterministic broken fixture is twice as wide and gets twice as many
uniformly spaced samples. Why is its equal density—not its doubled raw count—the correct comparison?
Name the assumption violated before describing the symptom.

## Prerequisite and transfer

Connect P01's repetition result to P02's sample-count lever, then name one measured system where bin
width could hide a meaningful feature or exaggerate noise.

## Executable check

From the repository root in MATLAB, run:

```matlab
run_module_checks('P02')
```

The checks cover seeded determinism, conservation, full bin-plus-tail normalization and discrepancy,
exact edge behavior, central and far-tail Gaussian mass limits, one-bin and unequal-bin limiting
fixtures, independent lever effects and `1/sqrt(N)` uncertainty, caller-RNG isolation, malformed
inputs, and resource bounds. All assertions must pass before learner completion is recorded.

## Teach-back

In two sentences, answer: “What inputs, observable effects, and failure modes matter when you turn
Random Variables into Histograms?” State the counting and normalization mechanism first; state the
visible sample-count/bin-width consequences and unequal-width failure second.

After MATLAB checks pass and the teach-back is ready, record completion from the repository root:

```bash
./bin/learn complete P02 --checks-passed --teach-back "<mechanism and consequence>"
```
