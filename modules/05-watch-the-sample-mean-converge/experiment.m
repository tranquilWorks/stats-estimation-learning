%% P05 - Watch the Sample Mean Converge
% Guiding question:
% What inputs, observable effects, and failure modes matter when you watch the Sample Mean Converge?

%% Read, then predict once
disp('P04 separated exact expected counts from sampled evidence. P05 now averages repeated noisy sensor readings.');
disp('Prediction: if the sample count is multiplied by four, what happens to raw-reading spread and mean standard error?');
disp('Run one section at a time. A realized error may wiggle even while its theoretical scale shrinks.');

%% Deterministic baseline
clear model p05_baseline;
sample_count = 400;
true_signal_millivolts = 12.0;
noise_standard_deviation_millivolts = 4.0;
seed = 505;
calibration_bias_millivolts = 0.0;
baseline = p05_baseline(sample_count, true_signal_millivolts, ...
    noise_standard_deviation_millivolts, seed, ...
    calibration_bias_millivolts);
assert(abs(baseline.final_standard_error_millivolts - 0.2) < 1e-12, ...
    'The baseline theoretical standard error must be 4/sqrt(400) = 0.2 mV.');
assert(abs(baseline.final_sample_mean_millivolts - ...
    sum(baseline.measurements_millivolts) / sample_count) < 1e-12, ...
    'The final running mean must equal the ordinary sample mean.');
disp('Pause here: raw readings stay noisy, while the running mean wanders on a narrowing scale.');

%% Parameter sweep 1 - sample count only
clear model;
modelFcn = @model;
sample_counts = [25 100 400];
true_signal_millivolts = 12.0;
noise_standard_deviation_millivolts = 4.0;
seed = 505;
calibration_bias_millivolts = 0.0;
longest_record = modelFcn(max(sample_counts), ...
    true_signal_millivolts, noise_standard_deviation_millivolts, ...
    seed, calibration_bias_millivolts);
final_sample_means_millivolts = zeros(size(sample_counts));
final_errors_millivolts = zeros(size(sample_counts));
final_standard_errors_millivolts = zeros(size(sample_counts));
for sweep_index = 1:numel(sample_counts)
    sweep_result = modelFcn(sample_counts(sweep_index), ...
        true_signal_millivolts, noise_standard_deviation_millivolts, ...
        seed, calibration_bias_millivolts);
    assert(isequal(sweep_result.measurements_millivolts, ...
        longest_record.measurements_millivolts(1:sample_counts(sweep_index))), ...
        'The sample-count sweep must reuse one seeded realization prefix.');
    final_sample_means_millivolts(sweep_index) = ...
        sweep_result.final_sample_mean_millivolts;
    final_errors_millivolts(sweep_index) = ...
        sweep_result.final_error_from_true_millivolts;
    final_standard_errors_millivolts(sweep_index) = ...
        sweep_result.final_standard_error_millivolts;
end
sampleCountFigureName = 'P05 sweep 1: sample count only';
existingSampleCountSweep = findall(groot, 'Type', 'figure', ...
    'Name', sampleCountFigureName);
if ~isempty(existingSampleCountSweep)
    close(existingSampleCountSweep);
end
figure('Name', sampleCountFigureName);
subplot(1,2,1);
semilogx(sample_counts, final_sample_means_millivolts, ...
    'o-', 'LineWidth', 1.5);
hold on;
semilogx(sample_counts, ...
    true_signal_millivolts * ones(size(sample_counts)), '--');
hold off;
grid on;
xlabel('Sample count N (samples)');
ylabel('Final sample mean (mV)');
title('Same record, later averaging endpoints');
legend({'Realized sample mean', 'True signal \mu'}, ...
    'Location', 'best');
subplot(1,2,2);
loglog(sample_counts, abs(final_errors_millivolts), ...
    'o-', 'LineWidth', 1.5);
hold on;
loglog(sample_counts, final_standard_errors_millivolts, ...
    's--', 'LineWidth', 1.5);
hold off;
grid on;
xlabel('Sample count N (samples)');
ylabel('Error scale at endpoint (mV)');
title('Theory shrinks; realized error need not be monotone');
legend({'Absolute realized error', 'Theoretical SE sigma/sqrt(N)'}, ...
    'Location', 'best');
assert(all(diff(final_standard_errors_millivolts) < 0), ...
    'The sample-count sweep must reduce theoretical standard error.');
assert(max(abs(final_standard_errors_millivolts - ...
    noise_standard_deviation_millivolts ./ sqrt(sample_counts))) < 1e-12, ...
    'The sample-count sweep must retain the sigma/sqrt(N) mechanism.');

%% Explain the first changed view
disp(['Mechanism: all three endpoints use the same realization prefix. ' ...
    'Raw noise stays at 4 mV RMS, but averaging N independent terms makes the mean scale 4/sqrt(N).']);
disp('Four times as many observations halves theoretical standard error; it does not force every realized step closer.');

%% Reset, then parameter sweep 2 - noise standard deviation only
clear model;
modelFcn = @model;
sample_count = 400;
true_signal_millivolts = 12.0;
noise_standard_deviations_millivolts = [1.0 4.0 8.0];
seed = 505;
calibration_bias_millivolts = 0.0;
noise_sweep_results = cell(size(noise_standard_deviations_millivolts));
final_errors_millivolts = zeros(size(noise_standard_deviations_millivolts));
final_standard_errors_millivolts = ...
    zeros(size(noise_standard_deviations_millivolts));
noiseFigureName = 'P05 sweep 2: noise scale only';
existingNoiseSweep = findall(groot, 'Type', 'figure', ...
    'Name', noiseFigureName);
if ~isempty(existingNoiseSweep)
    close(existingNoiseSweep);
end
figure('Name', noiseFigureName);
subplot(1,2,1);
hold on;
for sweep_index = 1:numel(noise_standard_deviations_millivolts)
    noise_sweep_results{sweep_index} = modelFcn(sample_count, ...
        true_signal_millivolts, ...
        noise_standard_deviations_millivolts(sweep_index), ...
        seed, calibration_bias_millivolts);
    plot(noise_sweep_results{sweep_index}.observation_counts, ...
        noise_sweep_results{sweep_index}.running_error_from_true_millivolts, ...
        'LineWidth', 1.2);
    final_errors_millivolts(sweep_index) = ...
        noise_sweep_results{sweep_index}.final_error_from_true_millivolts;
    final_standard_errors_millivolts(sweep_index) = ...
        noise_sweep_results{sweep_index}.final_standard_error_millivolts;
end
hold off;
grid on;
xlabel('Observation count n (samples)');
ylabel('Running-mean error (mV)');
title('The same standardized noise at three scales');
legend({'sigma = 1 mV', 'sigma = 4 mV', 'sigma = 8 mV'}, ...
    'Location', 'best');
subplot(1,2,2);
plot(noise_standard_deviations_millivolts, ...
    abs(final_errors_millivolts), 'o-', 'LineWidth', 1.5);
hold on;
plot(noise_standard_deviations_millivolts, ...
    final_standard_errors_millivolts, 's--', 'LineWidth', 1.5);
hold off;
grid on;
xlabel('Noise RMS sigma (mV)');
ylabel('Final uncertainty or error (mV)');
title('Noise scale multiplies the mean-error scale');
legend({'Absolute realized error', 'Theoretical SE'}, ...
    'Location', 'best');
assert(isequal(noise_sweep_results{1}.standardized_noise, ...
    noise_sweep_results{3}.standardized_noise), ...
    'The noise sweep must preserve the standardized realization.');
assert(max(abs(noise_sweep_results{3}.running_random_error_millivolts - ...
    8 * noise_sweep_results{1}.running_random_error_millivolts)) < 1e-10, ...
    'Eight times the noise scale must produce eight times the same running random error.');

%% Explain the second changed view
disp(['Mechanism: N, target, seed, and bias reset. Changing sigma only stretches ' ...
    'the same standardized readings, so both realized mean error and sigma/sqrt(n) scale linearly.']);

%% Deliberately broken case - stable but biased calibration
clear model;
modelFcn = @model;
sample_count = 400;
true_signal_millivolts = 12.0;
noise_standard_deviation_millivolts = 4.0;
seed = 505;
calibration_bias_millivolts = 3.0;
unbiased = modelFcn(sample_count, true_signal_millivolts, ...
    noise_standard_deviation_millivolts, seed, 0.0);
biased = modelFcn(sample_count, true_signal_millivolts, ...
    noise_standard_deviation_millivolts, seed, ...
    calibration_bias_millivolts);
biasFigureName = 'P05 broken case: calibration bias';
existingBiasCase = findall(groot, 'Type', 'figure', ...
    'Name', biasFigureName);
if ~isempty(existingBiasCase)
    close(existingBiasCase);
end
figure('Name', biasFigureName);
subplot(1,2,1);
plot(unbiased.observation_counts, ...
    unbiased.running_sample_mean_millivolts, 'LineWidth', 1.2);
hold on;
plot(biased.observation_counts, ...
    biased.running_sample_mean_millivolts, 'LineWidth', 1.5);
plot([1 sample_count], ...
    [true_signal_millivolts true_signal_millivolts], '--');
plot([1 sample_count], ...
    [biased.expected_measurement_center_millivolts ...
    biased.expected_measurement_center_millivolts], ':', ...
    'LineWidth', 1.5);
hold off;
grid on;
xlabel('Observation count n (samples)');
ylabel('Running sample mean (mV)');
title('A stable mean can converge to the wrong target');
legend({'Zero bias', 'Broken +3 mV calibration', ...
    'True signal 12 mV', 'Biased measurement mean 15 mV'}, ...
    'Location', 'best');
subplot(1,2,2);
loglog(biased.observation_counts, ...
    abs(biased.running_error_from_true_millivolts), ...
    'LineWidth', 1.5);
hold on;
loglog(biased.observation_counts, ...
    biased.theoretical_standard_error_millivolts, '--', ...
    'LineWidth', 1.5);
loglog(biased.observation_counts, ...
    biased.theoretical_target_rmse_millivolts, ':', ...
    'LineWidth', 1.5);
hold off;
grid on;
xlabel('Observation count n (samples)');
ylabel('Target-error scale (mV)');
title('Precision improves while fixed bias remains');
legend({'Absolute realized target error', 'Random-error SE', ...
    'Target RMSE including bias'}, 'Location', 'best');
assert(max(abs((biased.running_sample_mean_millivolts - ...
    unbiased.running_sample_mean_millivolts) - ...
    calibration_bias_millivolts)) < 1e-10, ...
    'A common calibration offset must shift the entire running mean by 3 mV.');
assert(abs(biased.final_standard_error_millivolts - ...
    unbiased.final_standard_error_millivolts) < 1e-12, ...
    'A fixed calibration bias must not masquerade as random standard error.');
disp('Broken assumption: measurement error was assumed to have zero mean. Stability alone does not establish accuracy.');

%% Repair the broken case - remove the known calibration offset
calibrated_measurements_millivolts = ...
    biased.measurements_millivolts - calibration_bias_millivolts;
repaired_running_mean_millivolts = ...
    cumsum(calibrated_measurements_millivolts) ./ biased.observation_counts;
repairFigureName = 'P05 repair: subtract known calibration offset';
existingRepair = findall(groot, 'Type', 'figure', ...
    'Name', repairFigureName);
if ~isempty(existingRepair)
    close(existingRepair);
end
figure('Name', repairFigureName);
bar([abs(biased.final_error_from_true_millivolts), ...
    abs(repaired_running_mean_millivolts(end) - true_signal_millivolts), ...
    biased.final_standard_error_millivolts]);
set(gca, 'XTick', 1:3, 'XTickLabel', ...
    {'Before calibration', 'After calibration', 'Random-error SE'});
grid on;
xlabel('Estimator condition');
ylabel('Final error scale (mV)');
title('Repair the model before trusting more samples');
assert(max(abs(repaired_running_mean_millivolts - ...
    unbiased.running_sample_mean_millivolts)) < 1e-10, ...
    'Subtracting the known calibration offset must recover the unbiased record.');
disp('Repair: subtract a separately established calibration offset; unknown bias needs calibration data, not more repeats.');
