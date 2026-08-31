function baseline = p02_baseline(sampleCount, binWidthMillivolts, sigmaMillivolts, seed)
%P02_BASELINE Present exactly one deterministic P02 baseline transition.

if nargin < 1
    sampleCount = 1000;
end
if nargin < 2
    binWidthMillivolts = 0.5;
end
if nargin < 3
    sigmaMillivolts = 1.0;
end
if nargin < 4
    seed = 202;
end

baseline = model(sampleCount, binWidthMillivolts, sigmaMillivolts, seed);

p02Figures = findall(groot, 'Type', 'figure', '-regexp', 'Name', '^P02 ');
if ~isempty(p02Figures)
    close(p02Figures);
end
figure('Name', 'P02 baseline: samples become a histogram');
subplot(2,1,1);
plot(1:sampleCount, baseline.samples_millivolts, '.', 'MarkerSize', 6);
hold on; yline(0, '--', 'True mean'); hold off;
grid on;
xlabel('Measurement index (sample)');
ylabel('Sensor error X (mV)');
title('Each outcome is a number before it is assigned to a bin');

subplot(2,1,2);
bar(baseline.bin_centers_millivolts, baseline.density_per_millivolt, 1, ...
    'FaceColor', [0.25 0.55 0.85], 'DisplayName', 'Empirical density');
hold on;
plot(baseline.bin_centers_millivolts, ...
    baseline.theoretical_density_per_millivolt, 'k-', 'LineWidth', 1.5, ...
    'DisplayName', 'Generating density');
hold off; grid on;
xlabel('Sensor error x (mV)');
ylabel('Probability density (1/mV)');
title('The histogram compresses samples into interval counts');
legend('Location', 'best');

fprintf(['Baseline: N = %d, requested bin width = %.2f mV, bins = %d, ' ...
    'mean = %.3f mV, empirical RMS spread = %.3f mV, area = %.6f, ' ...
    'underflow = %d samples, overflow = %d samples\n'], ...
    baseline.sample_count, baseline.requested_bin_width_millivolts, ...
    numel(baseline.counts), baseline.sample_mean_millivolts, ...
    baseline.sample_standard_deviation_millivolts, baseline.normalization_area, ...
    baseline.underflow_count, baseline.overflow_count);
end
