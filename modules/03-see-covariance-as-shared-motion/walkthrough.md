# P03 walkthrough: See Covariance as Shared Motion

## Guiding question

What inputs, observable effects, and failure modes matter when you see Covariance as Shared Motion?

Move through one visual transition at a time. Return to the deterministic baseline before changing
the second lever.

1. Read the guiding question and the connection to P02 in `lesson.md`: separate histograms lose pair identity.
2. Before plotting, predict the cloud tilt and signed-product balance for positive versus negative shared motion.
3. Run only the deterministic baseline section of `experiment.m`. Inspect the paired centered traces first; name both axes and their units.
4. Inspect the deviation cloud, then the cumulative full-record-centered product average. Explain how signed products in `mm^2` produce the final covariance.
5. Run parameter sweep 1. Change only `rho`; describe the sign and tilt transition before reading its mechanism explanation.
6. Reset to `N = 400`, `rho = 0.70`, `sigma_A = 1.0 mm`, `sigma_B = 1.5 mm`, and seed `303`.
7. Run parameter sweep 2. Change only Sensor B's RMS scale; explain why covariance changes while correlation does not.
8. Open `interactive.m`. Repeat each lever independently; use the seed only to change the repeatable arrangement of pairs.
9. Run the deliberately broken uncentered-product section and stop at the false large value. Name the zero-mean assumption before running the centered repair.
10. From the repository root, run `run_module_checks('P03')`. If MATLAB is unavailable, record the check as unperformed rather than inferred.
11. Answer the interpretation questions in `checks.md` and give the two-sentence teach-back: centering/product mechanism first, consequences and failure second.
