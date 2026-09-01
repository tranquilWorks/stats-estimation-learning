function baseline = p05_baseline(sampleCount, trueSignalMillivolts, ...
    noiseStandardDeviationMillivolts, seed, calibrationBiasMillivolts)
%P05_BASELINE Present one deterministic running-sample-mean transition.

if nargin < 1
    sampleCount = 400;
end
if nargin < 2
    trueSignalMillivolts = 12.0;
end
if nargin < 3
    noiseStandardDeviationMillivolts = 4.0;
end
if nargin < 4
    seed = 505;
end
if nargin < 5
    calibrationBiasMillivolts = 0.0;
end

baseline = model(sampleCount, trueSignalMillivolts, ...
    noiseStandardDeviationMillivolts, seed, ...
    calibrationBiasMillivolts);

baselineFigureName = 'P05 baseline: running sample mean';
existingBaseline = findall(groot, 'Type', 'figure', ...
    'Name', baselineFigureName);
if ~isempty(existingBaseline)
    close(existingBaseline);
end
figure('Name', baselineFigureName);

subplot(2,1,1);
plot(baseline.observation_counts, ...
    baseline.measurements_millivolts, '.', 'MarkerSize', 8);
hold on;
plot([1 baseline.sample_count], ...
    [baseline.true_signal_millivolts baseline.true_signal_millivolts], ...
    '--', 'LineWidth', 1.5);
hold off;
grid on;
xlabel('Observation count n (samples)');
ylabel('Sensor reading X_i (mV)');
title('Individual readings remain noisy');
legend({'Reading', 'True signal \mu'}, 'Location', 'best');

subplot(2,1,2);
plot(baseline.observation_counts, ...
    baseline.running_sample_mean_millivolts, ...
    'LineWidth', 1.5);
hold on;
plot([1 baseline.sample_count], ...
    [baseline.true_signal_millivolts baseline.true_signal_millivolts], ...
    '--', 'LineWidth', 1.5);
plot(baseline.observation_counts, ...
    baseline.two_standard_error_lower_millivolts, ':');
plot(baseline.observation_counts, ...
    baseline.two_standard_error_upper_millivolts, ':');
hold off;
grid on;
xlabel('Observation count n (samples)');
ylabel('Running sample mean (mV)');
title('Averaging narrows random error as 1/sqrt(n)');
legend({'Running sample mean', 'True signal \mu', ...
    '-2 theoretical SE', '+2 theoretical SE'}, ...
    'Location', 'best');

fprintf(['Baseline: n = %d samples, true signal = %.2f mV, ' ...
    'noise RMS sigma = %.2f mV, calibration bias = %.2f mV.\n'], ...
    baseline.sample_count, baseline.true_signal_millivolts, ...
    baseline.noise_standard_deviation_millivolts, ...
    baseline.calibration_bias_millivolts);
fprintf(['Final sample mean = %.4f mV, error from truth = %.4f mV, ' ...
    'theoretical standard error = %.4f mV.\n'], ...
    baseline.final_sample_mean_millivolts, ...
    baseline.final_error_from_true_millivolts, ...
    baseline.final_standard_error_millivolts);
end
