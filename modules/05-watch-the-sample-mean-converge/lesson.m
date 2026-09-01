%% P05 - Watch the Sample Mean Converge
% Guiding question:
% What inputs, observable effects, and failure modes matter when you watch the Sample Mean Converge?
%
% P04 distinguished exact expected counts from sampled evidence. P05 now
% watches a finite average estimate the mean of repeated noisy readings.

%% Read the physical model
disp('A fixed sensor signal is hidden under zero-mean random noise: X_i = mu + b + sigma Z_i.');
disp('The running mean averages random deviations, but a common calibration offset survives every repeat.');

%% Make one prediction before the baseline
disp('Prediction: if N grows from 100 to 400, which halves: raw-reading spread or sample-mean standard error?');

%% Visualize exactly one baseline transition
p05_baseline;
disp('Pause here. Raw readings remain noisy; point to the narrowing scale around the running mean.');

%% Continue one transition at a time
disp(['Next, open experiment.m in the Live Editor and run one section at a time: ' ...
    'sample-count sweep, explanation, reset, noise sweep, explanation, broken bias, then repair.']);
disp('Open interactive.m only after both sectioned sweeps; use Reset baseline between lever changes.');
disp('Describe each changed view before reading the mechanism explanation that follows it.');

%% Check and teach back
disp(['From the repository root, run run_module_checks(''P05''), then explain ' ...
    'why sigma/sqrt(n) shrinks and why a fixed calibration bias does not.']);
