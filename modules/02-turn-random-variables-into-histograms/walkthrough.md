# P02 walkthrough: Turn Random Variables into Histograms

## Guiding question

What inputs, observable effects, and failure modes matter when you turn Random Variables into Histograms?

Move through one visual transition at a time. Return to the deterministic baseline before changing
the second lever.

1. Read the guiding question and the connection to P01 in `lesson.md`.
2. Before plotting, predict what a larger sample count changes when bin width and generating spread stay fixed.
3. Run only the deterministic baseline section of `experiment.m`. First inspect the measurement sequence; name both axes and their units.
4. Inspect the baseline histogram. Explain how individual errors became interval counts and why density has units `1/mV`.
5. Run parameter sweep 1. Change only sample count and describe the changed view before reading its mechanism explanation.
6. Reset to `N = 1000`, width `0.5 mV`, sigma `1.0 mV`, and seed `202`.
7. Run parameter sweep 2. Change only bin width and describe which detail appears or disappears before reading its mechanism explanation.
8. Open `interactive.m`. Repeat each lever independently; use the seed only to distinguish a lever effect from a lucky realization.
9. Run the deliberately broken unequal-width section and stop at the raw-count symptom. Name the violated assumption before running the separate density-repair section.
10. From the repository root, run `run_module_checks('P02')`. If MATLAB is unavailable, record the check as unperformed rather than inferred.
11. Answer the interpretation questions in `checks.md` and give the two-sentence teach-back: mechanism first, consequence second.
