# P04 checks: Update Beliefs with Bayes' Rule

## Baseline observation

In the baseline, identify the 90 expected fault alarms and 990 expected healthy alarms per 10,000
systems. Why does the alarm raise fault probability from 1% to 8.33% but still leave healthy as the
more likely source?

## Lever checks

1. With both likelihoods fixed, why does increasing the prior fault probability increase the
   posterior after the same alarm?
2. After resetting the baseline, why does raising only `P(alarm | healthy)` add healthy alarms,
   leave fault alarms fixed, and lower the posterior?

## Numerical and limiting-case interpretation

- Why must the four joint condition/alarm cells sum to one, and why must the two posterior alarm
  sources sum to one?
- Show that prior odds times `P(alarm | fault) / P(alarm | healthy)` equals posterior odds for the
  finite baseline.
- Why does an alarm with equal likelihood under fault and healthy leave posterior equal to prior?
- What posterior limits appear when false-alarm probability is zero or sensitivity is zero, provided
  the observed alarm remains possible?
- Why is conditioning undefined—not zero—when total alarm probability is zero?
- Why do expected counts scale with the reference population while every probability stays fixed?

## Broken-case check

The broken shortcut `sensitivity / (sensitivity + falseAlarm)` reports 90% for the baseline.
Name the equal-prior assumption it silently inserts. Then repair the calculation using the 1% fault prior,
99% healthy prior, and both prior-weighted alarm paths.

## Prerequisite and transfer

Connect P03's preserved observation pairs to P04's preserved joint cells. Explain why P03's warning
about shared motion also means two correlated alarms cannot automatically be treated as independent
evidence, then name one diagnostic system where base-rate neglect would matter.

## Executable check

From the repository root in MATLAB, run:

```matlab
run_module_checks('P04')
```

The checks cover deterministic repetition, independent joint and posterior arithmetic, mass
conservation, the law of total probability, odds form, exact baseline counts, uninformative and
endpoint limits, both independent sweeps, equal-prior failure and repair, count-scale invariance,
caller-RNG isolation, malformed inputs, impossible observations, and accepted/rejected resource
boundaries. All assertions must pass before learner completion is recorded.

## Teach-back

In two sentences, answer: “What inputs, observable effects, and failure modes matter when you update
Beliefs with Bayes' Rule?” State the prior-weighted alarm paths and normalization first; state how
the prior/false-alarm levers change the view and name base-rate neglect second.

After MATLAB checks pass and the teach-back is ready, record completion from the repository root:

```bash
./bin/learn complete P04 --checks-passed --teach-back "<mechanism and consequence>"
```
