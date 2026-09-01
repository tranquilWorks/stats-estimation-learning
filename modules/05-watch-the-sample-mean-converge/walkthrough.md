# P05 walkthrough: Watch the Sample Mean Converge

## Guiding question

What inputs, observable effects, and failure modes matter when you watch the Sample Mean Converge?

Move through one visual transition at a time. Return to the deterministic baseline before changing
the second lever.

1. Read the guiding question and P04 connection in `lesson.md`: expected population values and
   finite sampled estimates are not the same evidence.
2. Before plotting, predict whether quadrupling sample count halves raw-reading spread or the
   sample mean's theoretical standard error.
3. Run only the deterministic baseline section of `experiment.m`. Inspect noisy readings first and
   name both axis units.
4. Inspect the running mean. Identify the 12 mV target and the `sigma/sqrt(n)` scale, then state why
   the realized path can wiggle.
5. Run parameter sweep 1. Change only sample count, verify all records share one prefix, and compare
   the 0.8, 0.4, and 0.2 mV endpoint standard errors.
6. Reset to 400 samples, 12 mV target, 4 mV noise, seed 505, and zero bias.
7. Run parameter sweep 2. Change only noise RMS and explain why the same standardized path stretches
   linearly.
8. Open `interactive.m`. Move one lever at a time and use **Reset baseline** between comparisons.
9. Run the deliberately broken `+3 mV` calibration case. Name the zero-mean-error assumption and
   explain why a stable mean near 15 mV is precise but inaccurate for the 12 mV target.
10. Run the repair only after naming the failure. Explain why subtracting a separately known offset
    works and why more same-calibration repeats do not discover an unknown bias.
11. From the repository root, run `run_module_checks('P05')`. If MATLAB is unavailable, record the
    check as unperformed rather than inferred.
12. Answer the interpretation questions in `checks.md` and give the two-sentence teach-back:
    `sigma/sqrt(n)` mechanism first, calibration-bias limit second.
