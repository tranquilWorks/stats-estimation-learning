# P04 walkthrough: Update Beliefs with Bayes' Rule

## Guiding question

What inputs, observable effects, and failure modes matter when you update Beliefs with Bayes' Rule?

Move through one visual transition at a time. Return to the deterministic baseline before changing
the second lever.

1. Read the guiding question and the connection to P03 in `lesson.md`: preserve joint structure and
   keep the conditioning direction explicit.
2. Before plotting, predict whether a 90%-sensitive alarm makes a 1%-prior fault more likely than
   healthy when the false-alarm probability is 10%.
3. Run only the deterministic baseline section of `experiment.m`. Inspect prior versus posterior
   first and name the probability units.
4. Inspect the alarm-source view. Explain why 90 expected fault alarms compete with 990 expected
   healthy alarms per 10,000 systems and produce `90 / 1080 = 8.33%`.
5. Run parameter sweep 1. Change only the prior; describe the posterior transition before reading
   its mechanism explanation.
6. Reset to prior 1%, sensitivity 90%, false-alarm probability 10%, and 10,000 reference systems.
7. Run parameter sweep 2. Change only false-alarm probability; explain why healthy alarms change
   while fault alarms stay fixed.
8. Open `interactive.m`. Move one lever at a time and use **Reset baseline** between comparisons.
9. Run the deliberately broken equal-prior section and stop at its 90% report. Name the hidden 50/50
   prior before running the prior-weighted repair.
10. From the repository root, run `run_module_checks('P04')`. If MATLAB is unavailable, record the
    check as unperformed rather than inferred.
11. Answer the interpretation questions in `checks.md` and give the two-sentence teach-back:
    prior-weighted alarm paths first, observable consequences and failure mode second.
