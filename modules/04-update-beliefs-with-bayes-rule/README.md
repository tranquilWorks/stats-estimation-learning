# P04 — Update Beliefs with Bayes' Rule

**Track:** Probability, Statistics, Estimation, and Detection  
**Phase 1:** Probability you can see  
**Status:** implemented

## Guiding question

What inputs, observable effects, and failure modes matter when you update Beliefs with Bayes' Rule?

## Compounds on

P03 preserved paired observations so their joint motion remained visible. P04 also keeps a joint
structure: condition (`fault` or `healthy`) by observation (`alarm` or `no alarm`). Once an alarm is
observed, Bayes' rule normalizes the two paths into that alarm column. This keeps
`P(alarm | fault)` separate from the reversed question `P(fault | alarm)`.

## Physical mental model

A diagnostic alarm monitors a population of systems. Before an alarm, the **prior fault
probability** describes how common faults are. The alarm has a **sensitivity**
`P(alarm | fault)` and a **false-alarm probability** `P(alarm | healthy)`. These inputs first form
two joint alarm paths, then the observed alarm selects and renormalizes their column:

```text
P(fault and alarm)   = P(fault)   P(alarm | fault)
P(healthy and alarm) = P(healthy) P(alarm | healthy)

P(fault | alarm) = P(fault and alarm)
                   -----------------------------------------------
                   P(fault and alarm) + P(healthy and alarm)
```

The deterministic baseline uses 10,000 reference systems, a 1% fault prior, 90% sensitivity, and a
10% false-alarm probability. It produces 90 expected fault alarms and 990 expected healthy alarms,
so the updated fault probability is `90 / (90 + 990) = 1/12 = 8.33%`. Expected counts are a
frequency interpretation of the exact probabilities, not a random simulation or a claim that
fractional systems were physically observed.

## Controlled levers

- **Prior fault probability:** changes the relative sizes of the fault and healthy candidate
  populations while both alarm likelihoods remain fixed.
- **False-alarm probability:** changes only how much the much larger healthy population contributes
  to the alarm denominator after the prior and sensitivity reset to baseline.
- **Sensitivity:** is available in the interactive explorer to show how strongly faults contribute
  alarms; it remains fixed during both required sweeps.

## Observable views and metrics

- prior versus posterior fault probability in percent;
- expected fault-alarm and healthy-alarm sources per 10,000 systems;
- all four joint probabilities, total alarm probability, posterior normalization, prior/posterior
  odds, and the positive likelihood ratio (all dimensionless);
- fixed-input sweep views that make changes in posterior probability and alarm-source composition
  visible.

## Deliberately broken case

The shortcut `sensitivity / (sensitivity + falseAlarm)` reports 90% for the baseline alarm. It
silently gives fault and healthy equal 50/50 prior weight. With the actual 1% fault prior, healthy
systems are numerous enough to create 990 expected alarms, so the correct posterior is only 8.33%.
The repair weights both alarm paths by their priors before normalizing.

## Files and dependencies

- `model.m` performs bounded deterministic Bayes calculations and exposes the complete joint table
  without plotting, random draws, or toolbox calls.
- `p04_baseline.m` owns the one deterministic baseline transition used by both entry paths.
- `experiment.m` contains the baseline, two independent sweeps, mechanism explanations, broken
  equal-prior case, and repair.
- `interactive.m` exposes bounded prior, sensitivity, and false-alarm controls plus a baseline reset.
- `lesson.m`, `lesson.md`, and `walkthrough.md` implement the concept-first tutor flow.
- `checks.md` and `run_checks.m` contain interpretation prompts and executable invariants.

The implementation uses base MATLAB operations. Static source inspection and independent Python
reference arithmetic are not evidence that MATLAB figures, controls, or executable checks ran.
