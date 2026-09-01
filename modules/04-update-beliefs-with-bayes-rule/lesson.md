# P04 lesson: Update Beliefs with Bayes' Rule

## Guiding question

What inputs, observable effects, and failure modes matter when you update Beliefs with Bayes' Rule?

## Compounds on

P03 kept paired observations together because separate summaries lose joint structure. It also
showed that an association such as covariance does not determine causation or a conditional
direction. P04 keeps the four condition/alarm joint cells visible and carefully distinguishes the
forward likelihood `P(alarm | fault)` from the reverse belief `P(fault | alarm)`.

## Mental model

Imagine a diagnostic alarm on a large group of systems. There are two ways to enter the observed
alarm column: a faulty system can alarm, or a healthy system can false-alarm. First weight each path
by the size of its prior population:

```text
J_FA = P(fault)   P(alarm | fault)
J_HA = P(healthy) P(alarm | healthy)
P(alarm) = J_FA + J_HA
```

Only after those joint masses are visible do we normalize the selected column:

```text
P(fault | alarm)   = J_FA / (J_FA + J_HA)
P(healthy | alarm) = J_HA / (J_FA + J_HA)
```

All probabilities, odds, and likelihood ratios are dimensionless. Expected alarm counts use the
unit “expected systems per 10,000 opportunities” and are just the same probability masses on a
frequency scale. No random population is sampled in this deterministic lesson.

## One prediction before the baseline

The baseline fault is rare: 1% prior probability. The diagnostic has 90% sensitivity and a 10%
false-alarm probability. Before opening the plot, predict whether one alarm makes fault or healthy
the more likely source. Do not answer by reading sensitivity backward.

## Lever 1 — prior fault probability

Reset sensitivity to 90% and false-alarm probability to 10%, then sweep only the prior through
0.1%, 1%, and 10%. The same likelihood ratio of nine multiplies three different prior odds. As the
fault population grows, fault alarms occupy more of the alarm column and the posterior rises.

## Lever 2 — false-alarm probability

Reset the prior to 1% and sensitivity to 90%, then sweep only
`P(alarm | healthy)` through 1%, 10%, and 30%. The expected fault-alarm path stays at 90 per 10,000.
The healthy-alarm path grows from 99 to 990 to 2,970, so the posterior falls. A sensitive alarm is
not necessarily specific.

## Broken assumption

The shortcut

```text
sensitivity / (sensitivity + falseAlarm)
```

normalizes the likelihoods as though fault and healthy had equal prior probability. It gives the
correct posterior only for that special 50/50 prior. Applied to the 1% baseline it reports 90%
instead of 8.33%—a recognizable base-rate-neglect failure. Repair it by multiplying each likelihood
by its actual prior before normalizing.

## Limiting cases

- If both conditions alarm at the same rate, the alarm is uninformative and posterior equals prior.
- If healthy systems never alarm while faults sometimes do, an observed alarm has posterior one.
- If faults never alarm but healthy systems do, an observed alarm has posterior zero.
- A prior of zero or one stays at that endpoint when the observed alarm remains possible.
- If neither condition can produce an alarm in the prior population, `P(alarm)=0`; the requested
  conditional belief is undefined rather than zero.

## Common mistakes

- `P(alarm | fault)` is not `P(fault | alarm)`; conditioning direction changes the reference set.
- High sensitivity alone does not imply a trustworthy positive alarm. The base rate and false-alarm
  probability also control the posterior.
- Posterior probability is not automatically a decision rule; action costs and thresholds are a
  later decision problem.
- The two conditions must be mutually exclusive and exhaustive for this binary table. Missing a
  third condition leaves probability mass outside the model.
- Do not reuse and multiply marginal single-alarm likelihood ratios as if repeated alarms were
  independent. Use a calibrated joint or conditional likelihood for correlated evidence; P03's
  shared motion is a warning against silently counting the same evidence twice.
- Expected counts are exact probability-scaled values here, not observed integer data or evidence
  about estimator variability.

## Completion standard

Run the experiment one transition at a time, manipulate each lever independently, diagnose the
equal-prior broken case, run `run_module_checks('P04')` from the repository root in MATLAB, and give
the two-sentence teach-back in `checks.md`. Static repository checks and independent reference
arithmetic do not satisfy the MATLAB-runtime step.
