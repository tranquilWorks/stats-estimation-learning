# P02 lesson: Turn Random Variables into Histograms

## Guiding question

What inputs, observable effects, and failure modes matter when you turn Random Variables into Histograms?

## Connection to P01

P01 showed that more independent repetitions make long-run structure easier to see without making
the next outcome predictable. P02 asks what to do when each repeated outcome is a number, such as a
sensor error in millivolts: preserve the measurements, partition their number line, and count them.

## Mental model

The random variable `X` maps each measurement outcome to one error value. A bin is an interval, not
a point. The model uses left-closed, right-open intervals and includes the final right edge so every
boundary value has one unambiguous home.

For `N` total samples and bin width `Delta x_j`,

```text
probability mass p_j = count_j / N
density height h_j = count_j / (N * Delta x_j)
bar area h_j * Delta x_j = p_j
```

Samples beyond the displayed edges are reported as underflow or overflow. They are never silently
discarded and the visible histogram is not silently renormalized.

## One prediction before the baseline

With the bin width fixed at 0.5 mV, predict what increasing `N` changes in the histogram and what it
cannot change about the zero-mean, 1 mV-spread generating model.

## Lever 1 — sample count

The same seed makes a larger record extend the smaller record. Increasing `N` supplies more samples
to each fixed interval, so random bar-to-bar jitter usually becomes less prominent. It does not
change the interval boundaries or the generating distribution. For theoretical bin mass `q_j`, the
nominal standard error `sqrt(q_j * (1 - q_j) / N)` makes the expected `1/sqrt(N)` reduction explicit.

## Lever 2 — bin width

Reset to the baseline record before moving this lever. Narrow bins expose local detail but divide the
same measurements among more intervals. Wide bins pool more measurements and produce a smoother,
coarser summary. Bin width changes the view, not the underlying samples. The interactive dropdown
uses widths that all divide the fixed -4 to 4 mV support, so moving this lever does not silently
change the displayed range.

## Broken assumption

Raw count heights are comparable across equal-width bins. With unequal widths, a wide interval can
be taller merely because it covers more possible values. Divide each mass by its own width and
interpret probability as area.

## Common mistakes

- A histogram is not the random variable; it is a sample- and bin-dependent summary of observations.
- More samples do not guarantee every bar moves monotonically toward its theoretical value.
- More bins do not automatically mean more information; narrow bins can expose sampling noise.
- A density height may exceed one. Its integral, not each height, must obey probability bounds.
- Dropped tail samples must remain visible through underflow and overflow counts.

## Completion standard

Run the experiment one transition at a time, manipulate each lever independently, diagnose the
unequal-width broken case, run `run_module_checks('P02')` from the repository root in MATLAB, and
give the two-sentence teach-back in `checks.md`. Static repository checks alone do not satisfy the
MATLAB-runtime step.
