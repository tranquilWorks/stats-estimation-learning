%% P02 - Turn Random Variables into Histograms
% Guiding question:
% What inputs, observable effects, and failure modes matter when you turn Random Variables into Histograms?
%
% P01 used repetition to reveal stable proportions. Here each repeated
% outcome is a numerical sensor error, and intervals turn those numbers
% into an empirical distribution.

%% Read the physical model
disp('Each sensor reading produces one error X in millivolts.');
disp('A histogram counts which interval contains each X; probability is represented by bar area.');

%% Make one prediction before the baseline
disp('Prediction: if N grows while bin width stays fixed, what changes and what stays fixed?');

%% Visualize exactly one baseline transition
p02_baseline;
disp('Pause here. Describe how individual measurements became interval counts before continuing.');

%% Continue one transition at a time
disp(['Next, open experiment.m in the Live Editor and run one section at a time: ' ...
    'sample-count sweep, explanation, reset, bin-width sweep, explanation, broken case, then repair.']);
disp('Open interactive.m only after both sectioned sweeps; reset the first lever before moving the second.');
disp('Use each explanation section only after you have described the preceding plot in your own words.');

%% Check and teach back
disp(['From the repository root, run run_module_checks(''P02''), then explain the ' ...
    'mechanism first and the visible consequence second.']);
