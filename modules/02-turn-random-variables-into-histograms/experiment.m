%% P02 - Turn Random Variables into Histograms
% Guiding question:
% What inputs, observable effects, and failure modes matter when you turn Random Variables into Histograms?
%
% A sensor error X is one number per measurement. A histogram partitions
% the number line into bins. For bin j,
%   probability mass p_j = count_j / N
%   density height h_j = count_j / (N * bin width_j)
% so bar area, not bar height alone, represents probability.

% Replace only P02-owned figures so unrelated MATLAB work remains open.
p02Figures = findall(groot, 'Type', 'figure', '-regexp', 'Name', '^P02 ');
if ~isempty(p02Figures)
    close(p02Figures);
end
clc; clear model;

%% Read, then predict once
disp('Prediction: if N grows while the bin width stays fixed, what changes and what stays fixed?');
disp('Run the baseline before changing either lever.');

%% Deterministic baseline - view numbers before bars
sample_count = 1000;
bin_width_millivolts = 0.5;
sigma_millivolts = 1.0;
seed = 202;
baseline = p02_baseline(sample_count, bin_width_millivolts, ...
    sigma_millivolts, seed);
assert(sum(baseline.counts) + baseline.underflow_count + ...
    baseline.overflow_count == sample_count, 'Every sample must be accounted for.');
assert(abs(baseline.normalization_area - baseline.included_fraction) < 1e-12, ...
    'Histogram area must equal the included probability fraction.');
disp('Pause here: describe the sample-to-bin transition before running sweep 1.');

%% Parameter sweep 1 - sample count only
bin_width_millivolts = 0.5;
sigma_millivolts = 1.0;
seed = 202;
sample_counts = [100 1000 5000];
sample_count_errors = zeros(size(sample_counts));
sample_count_uncertainties = zeros(size(sample_counts));
figure('Name', 'P02 sweep 1: sample count'); hold on; grid on;
for sweep_index = 1:numel(sample_counts)
    sample_sweep = model(sample_counts(sweep_index), ...
        bin_width_millivolts, sigma_millivolts, seed);
    stairs(sample_sweep.bin_edges_millivolts, ...
        [sample_sweep.density_per_millivolt sample_sweep.density_per_millivolt(end)], ...
        'LineWidth', 1.3, ...
        'DisplayName', sprintf('N = %d', sample_counts(sweep_index)));
    sample_count_errors(sweep_index) = sample_sweep.l1_probability_error;
    sample_count_uncertainties(sweep_index) = ...
        mean(sample_sweep.nominal_probability_mass_standard_error);
end
xlabel('Sensor error x (mV)');
ylabel('Probability density (1/mV)');
title('Lever 1: more samples reduce random bar-to-bar jitter');
legend('Location', 'best');
fprintf('Sample-count sweep L1 mass errors: %.4f, %.4f, %.4f\n', sample_count_errors);
fprintf(['Mean nominal bin-mass standard errors: %.4f, %.4f, %.4f ' ...
    '(probability)\n'], sample_count_uncertainties);

%% Explain the first changed view
disp(['Mechanism: N changes how many independent measurements support each count. ' ...
    'It does not change the generating sigma or the fixed 0.5 mV intervals.']);

%% Reset, then parameter sweep 2 - bin width only
sample_count = 1000;
sigma_millivolts = 1.0;
seed = 202;
bin_widths_millivolts = [0.25 0.5 1.0];
figure('Name', 'P02 sweep 2: bin width'); hold on; grid on;
for sweep_index = 1:numel(bin_widths_millivolts)
    width_sweep = model(sample_count, bin_widths_millivolts(sweep_index), ...
        sigma_millivolts, seed);
    stairs(width_sweep.bin_edges_millivolts, ...
        [width_sweep.density_per_millivolt width_sweep.density_per_millivolt(end)], ...
        'LineWidth', 1.3, ...
        'DisplayName', sprintf('bin width = %.2f mV', ...
        bin_widths_millivolts(sweep_index)));
end
xlabel('Sensor error x (mV)');
ylabel('Probability density (1/mV)');
title('Lever 2: bin width trades local detail for aggregation');
legend('Location', 'best');

%% Explain the second changed view
disp(['Mechanism: smaller intervals resolve more local detail but give each bar fewer samples. ' ...
    'Larger intervals pool more samples and hide local structure.']);

%% Deliberately broken case - compare raw counts across unequal widths
sigma_millivolts = 1.0;
seed = 202;
uniform_fixture_millivolts = -1.875:0.25:1.875;
unequal_edges_millivolts = [-2 -1 1 2];
broken = model(numel(uniform_fixture_millivolts), 1.0, sigma_millivolts, ...
    seed, uniform_fixture_millivolts, unequal_edges_millivolts);
figure('Name', 'P02 broken case: raw unequal-width counts');
hold on;
for bin_index = 1:numel(broken.counts)
    rectangle('Position', [broken.bin_edges_millivolts(bin_index) 0 ...
        broken.bin_widths_millivolts(bin_index) broken.counts(bin_index)], ...
        'FaceColor', [0.85 0.35 0.25], 'EdgeColor', 'white');
end
ylim([0 9]);
hold off; grid on; xlim([unequal_edges_millivolts(1) unequal_edges_millivolts(end)]);
xlabel('Sensor error x (mV)');
ylabel('Raw count (samples)');
title('Broken: raw heights reward wider intervals');
disp('Pause here: identify the violated equal-width assumption before revealing the repair.');

%% Repair the broken case - restore probability as area
sigma_millivolts = 1.0;
seed = 202;
uniform_fixture_millivolts = -1.875:0.25:1.875;
unequal_edges_millivolts = [-2 -1 1 2];
broken = model(numel(uniform_fixture_millivolts), 1.0, sigma_millivolts, ...
    seed, uniform_fixture_millivolts, unequal_edges_millivolts);
figure('Name', 'P02 repaired case: unequal-width density');
hold on;
for bin_index = 1:numel(broken.counts)
    rectangle('Position', [broken.bin_edges_millivolts(bin_index) 0 ...
        broken.bin_widths_millivolts(bin_index) ...
        broken.density_per_millivolt(bin_index)], ...
        'FaceColor', [0.25 0.65 0.40], 'EdgeColor', 'white');
end
yline(0.25, 'k--', 'Uniform reference');
hold off; grid on; xlim([unequal_edges_millivolts(1) unequal_edges_millivolts(end)]);
xlabel('Sensor error x (mV)');
ylabel('Probability density (1/mV)');
title('Corrected: divide mass by each interval width');

disp(['Broken symptom: equally concentrated values give counts [4 8 4] but densities ' ...
    '[0.25 0.25 0.25] per mV. Raw heights are comparable only for equal widths.']);
