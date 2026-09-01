%% P04 - Update Beliefs with Bayes' Rule
% Guiding question:
% What inputs, observable effects, and failure modes matter when you update Beliefs with Bayes' Rule?

%% Read, then predict once
disp('P03 preserved paired outcomes. P04 preserves the condition/alarm joint cells.');
disp('Prediction: with a 1% fault base rate, will a 90%-sensitive alarm make fault more likely than healthy?');
disp('Run one section at a time and describe the changed view before reading its explanation.');

%% Deterministic baseline
clear model p04_baseline;
prior_fault_probability = 0.01;
alarm_given_fault_probability = 0.90;
alarm_given_healthy_probability = 0.10;
reference_population_count = 10000;
baseline = p04_baseline(prior_fault_probability, ...
    alarm_given_fault_probability, alarm_given_healthy_probability, ...
    reference_population_count);
assert(abs(baseline.posterior_fault_given_alarm_probability - 1/12) < 1e-12, ...
    'The baseline posterior must be 90/(90+990) = 1/12.');
assert(abs(baseline.expected_fault_alarm_count - 90) < 1e-10 && ...
    abs(baseline.expected_healthy_alarm_count - 990) < 1e-10, ...
    'The baseline alarm sources must remain visible as expected counts.');
disp('Pause here: point to both sources in the observed alarm column before moving a lever.');

%% Parameter sweep 1 - prior fault probability only
clear model;
modelFcn = @model;
prior_fault_probabilities = [0.001 0.010 0.100];
alarm_given_fault_probability = 0.90;
alarm_given_healthy_probability = 0.10;
reference_population_count = 10000;
posterior_fault_probabilities = zeros(size(prior_fault_probabilities));
fault_alarm_counts = zeros(size(prior_fault_probabilities));
healthy_alarm_counts = zeros(size(prior_fault_probabilities));
for sweep_index = 1:numel(prior_fault_probabilities)
    sweep_result = modelFcn(prior_fault_probabilities(sweep_index), ...
        alarm_given_fault_probability, alarm_given_healthy_probability, ...
        reference_population_count);
    posterior_fault_probabilities(sweep_index) = ...
        sweep_result.posterior_fault_given_alarm_probability;
    fault_alarm_counts(sweep_index) = ...
        sweep_result.expected_fault_alarm_count;
    healthy_alarm_counts(sweep_index) = ...
        sweep_result.expected_healthy_alarm_count;
end
existingSweep = findall(groot, 'Type', 'figure', 'Name', ...
    'P04 sweep 1: prior probability only');
if ~isempty(existingSweep)
    close(existingSweep);
end
figure('Name', 'P04 sweep 1: prior probability only');
subplot(1,2,1);
plot(100 * prior_fault_probabilities, ...
    100 * posterior_fault_probabilities, 'o-', 'LineWidth', 1.5);
grid on;
xlabel('Prior fault probability (%)');
ylabel('Posterior fault probability after alarm (%)');
title('Same alarm, different starting belief');
subplot(1,2,2);
bar(100 * prior_fault_probabilities, ...
    [fault_alarm_counts(:) healthy_alarm_counts(:)], 'stacked');
grid on;
xlabel('Prior fault probability (%)');
ylabel('Expected positive alarms per 10000 systems (count)');
title('Prior changes both alarm-source populations');
legend({'Fault alarms', 'Healthy alarms'}, 'Location', 'best');
assert(all(diff(posterior_fault_probabilities) > 0), ...
    'Posterior fault probability must increase across this prior sweep.');

%% Explain the first changed view
disp(['Mechanism: the prior weights both possible alarm sources before normalization. ' ...
    'Sensitivity and false-alarm probability stayed fixed, so only the base rate changed.']);
disp('The alarm is identical in every panel; its meaning changes because the candidate populations change.');

%% Reset, then parameter sweep 2 - false-alarm probability only
clear model;
modelFcn = @model;
prior_fault_probability = 0.01;
alarm_given_fault_probability = 0.90;
alarm_given_healthy_probabilities = [0.01 0.10 0.30];
reference_population_count = 10000;
posterior_fault_probabilities = ...
    zeros(size(alarm_given_healthy_probabilities));
fault_alarm_counts = zeros(size(alarm_given_healthy_probabilities));
healthy_alarm_counts = zeros(size(alarm_given_healthy_probabilities));
for sweep_index = 1:numel(alarm_given_healthy_probabilities)
    sweep_result = modelFcn(prior_fault_probability, ...
        alarm_given_fault_probability, ...
        alarm_given_healthy_probabilities(sweep_index), ...
        reference_population_count);
    posterior_fault_probabilities(sweep_index) = ...
        sweep_result.posterior_fault_given_alarm_probability;
    fault_alarm_counts(sweep_index) = ...
        sweep_result.expected_fault_alarm_count;
    healthy_alarm_counts(sweep_index) = ...
        sweep_result.expected_healthy_alarm_count;
end
existingSweep = findall(groot, 'Type', 'figure', 'Name', ...
    'P04 sweep 2: false alarms only');
if ~isempty(existingSweep)
    close(existingSweep);
end
figure('Name', 'P04 sweep 2: false alarms only');
subplot(1,2,1);
plot(100 * alarm_given_healthy_probabilities, ...
    100 * posterior_fault_probabilities, 'o-', 'LineWidth', 1.5);
grid on;
xlabel('False-alarm probability P(alarm | healthy) (%)');
ylabel('Posterior fault probability after alarm (%)');
title('More false alarms weaken the same alarm');
subplot(1,2,2);
bar(100 * alarm_given_healthy_probabilities, ...
    [fault_alarm_counts(:) healthy_alarm_counts(:)], 'stacked');
grid on;
xlabel('False-alarm probability P(alarm | healthy) (%)');
ylabel('Expected positive alarms per 10000 systems (count)');
title('Healthy alarms grow; fault alarms stay fixed');
legend({'Fault alarms', 'Healthy alarms'}, 'Location', 'best');
assert(all(diff(posterior_fault_probabilities) < 0), ...
    'Posterior fault probability must decrease across this false-alarm sweep.');

%% Explain the second changed view
disp(['Mechanism: sensitivity and prior reset to baseline. Raising only P(alarm | healthy) ' ...
    'adds competing healthy alarms to the denominator, so the posterior falls.']);

%% Deliberately broken case - silently assume equal prior odds
clear model;
modelFcn = @model;
prior_fault_probability = 0.01;
alarm_given_fault_probability = 0.90;
alarm_given_healthy_probability = 0.10;
reference_population_count = 10000;
correct = modelFcn(prior_fault_probability, ...
    alarm_given_fault_probability, alarm_given_healthy_probability, ...
    reference_population_count);
broken_equal_prior_posterior = alarm_given_fault_probability / ...
    (alarm_given_fault_probability + alarm_given_healthy_probability);
existingBroken = findall(groot, 'Type', 'figure', 'Name', ...
    'P04 broken case: base-rate neglect');
if ~isempty(existingBroken)
    close(existingBroken);
end
figure('Name', 'P04 broken case: base-rate neglect');
bar(100 * [correct.posterior_fault_given_alarm_probability, ...
    broken_equal_prior_posterior]);
set(gca, 'XTick', 1:2, ...
    'XTickLabel', {'Bayes with 1% prior', 'Broken equal-prior shortcut'});
grid on;
xlabel('Calculation');
ylabel('Reported fault probability after alarm (%)');
title('Ignoring the base rate creates false confidence');
ylim([0 100]);
fprintf(['Broken shortcut reports %.1f%%; correct posterior is %.2f%%. ' ...
    'Name the hidden 50/50 prior assumption before repair.\n'], ...
    100 * broken_equal_prior_posterior, ...
    100 * correct.posterior_fault_given_alarm_probability);
assert(broken_equal_prior_posterior - ...
    correct.posterior_fault_given_alarm_probability > 0.80, ...
    'The broken case must expose a large base-rate-neglect symptom.');

%% Repair the broken case - weight both alarm paths by their priors
clear model;
modelFcn = @model;
prior_fault_probability = 0.01;
alarm_given_fault_probability = 0.90;
alarm_given_healthy_probability = 0.10;
reference_population_count = 10000;
repaired = modelFcn(prior_fault_probability, ...
    alarm_given_fault_probability, alarm_given_healthy_probability, ...
    reference_population_count);
existingRepair = findall(groot, 'Type', 'figure', 'Name', ...
    'P04 repair: normalize the alarm column');
if ~isempty(existingRepair)
    close(existingRepair);
end
figure('Name', 'P04 repair: normalize the alarm column');
bar([repaired.expected_fault_alarm_count, ...
    repaired.expected_healthy_alarm_count]);
set(gca, 'XTick', 1:2, ...
    'XTickLabel', {'P(fault and alarm)', 'P(healthy and alarm)'});
grid on;
xlabel('Prior-weighted path into the observed alarm');
ylabel('Expected alarms per 10000 systems (count)');
title('Repair: normalize both alarm sources');
fprintf(['Repair: %.0f / (%.0f + %.0f) = %.4f = %.2f%%.\n'], ...
    repaired.expected_fault_alarm_count, ...
    repaired.expected_fault_alarm_count, ...
    repaired.expected_healthy_alarm_count, ...
    repaired.posterior_fault_given_alarm_probability, ...
    100 * repaired.posterior_fault_given_alarm_probability);
assert(abs(repaired.posterior_fault_given_alarm_probability - ...
    repaired.expected_fault_alarm_count / repaired.expected_alarm_count) < 1e-12, ...
    'Repair must normalize the two prior-weighted alarm paths.');
