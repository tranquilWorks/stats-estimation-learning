%% P03 - See Covariance as Shared Motion
% Guiding question:
% What inputs, observable effects, and failure modes matter when you see Covariance as Shared Motion?
%
% P02 summarized each sensor separately with a histogram. P03 preserves
% which Sensor A and Sensor B values occurred together, then asks whether
% their deviations share a direction.

%% Read the physical model
disp('Center each displacement record around its own mean.');
disp('Multiply paired deviations, then average: same-side motion contributes positive mm^2.');

%% Make one prediction before the baseline
disp('Prediction: if shared motion changes from positive to negative, how will the paired cloud tilt?');

%% Visualize exactly one baseline transition
p03_baseline;
disp('Pause here. Point to the signed pair products that create the cloud tilt before continuing.');

%% Continue one transition at a time
disp(['Next, open experiment.m in the Live Editor and run one section at a time: ' ...
    'rho sweep, explanation, reset, Sensor B scale sweep, explanation, broken case, then repair.']);
disp('Open interactive.m only after both sectioned sweeps; reset the first lever before moving the second.');
disp('Describe each changed view before reading the mechanism explanation that follows it.');

%% Check and teach back
disp(['From the repository root, run run_module_checks(''P03''), then explain ' ...
    'centering and signed products before describing the visible consequences.']);
