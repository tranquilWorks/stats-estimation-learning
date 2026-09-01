%% P04 - Update Beliefs with Bayes' Rule
% Guiding question:
% What inputs, observable effects, and failure modes matter when you update Beliefs with Bayes' Rule?
%
% P03 preserved paired outcomes instead of reducing both records to
% separate summaries. P04 preserves the condition/alarm joint cells, then
% normalizes only the column matching the observed alarm.

%% Read the physical model
disp('An alarm has two possible sources: a fault that alarms and a healthy system that false-alarms.');
disp('Weight both paths by their prior populations, then normalize the observed alarm column.');

%% Make one prediction before the baseline
disp('Prediction: can a 90%-sensitive alarm still leave a rare 1% fault less likely than healthy?');

%% Visualize exactly one baseline transition
p04_baseline;
disp('Pause here. Point to the 90 fault alarms and 990 healthy alarms that create the 8.33% posterior.');

%% Continue one transition at a time
disp(['Next, open experiment.m in the Live Editor and run one section at a time: ' ...
    'prior sweep, explanation, reset, false-alarm sweep, explanation, broken case, then repair.']);
disp('Open interactive.m only after both sectioned sweeps; use Reset baseline before comparing levers.');
disp('Describe each changed view before reading the mechanism explanation that follows it.');

%% Check and teach back
disp(['From the repository root, run run_module_checks(''P04''), then explain ' ...
    'the two prior-weighted alarm paths before naming the base-rate failure.']);
