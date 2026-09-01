%% P03 - See Covariance as Shared Motion
% Guiding question:
% What inputs, observable effects, and failure modes matter when you see Covariance as Shared Motion?
%
% Sensor A and Sensor B report paired platform displacements in millimetres.
% Covariance is the average centered pairwise product:
%   C_AB = sum((A - mean(A)) .* (B - mean(B))) / N
% Positive products mean the pair moved to the same side of its own mean;
% negative products mean opposite-side motion. Covariance has units mm^2.

% Replace only P03-owned figures so unrelated MATLAB work remains open.
p03Figures = findall(groot, 'Type', 'figure', '-regexp', 'Name', '^P03 ');
if ~isempty(p03Figures)
    close(p03Figures);
end
clc; clear model;

%% Read, then predict once
disp('Prediction: if shared motion changes from positive to negative, how will the paired cloud tilt?');
disp('Run the baseline before moving either lever.');

%% Deterministic baseline - paired deviations become one covariance
sample_count = 400;
shared_motion_coefficient = 0.70;
sigma_a_millimeters = 1.0;
sigma_b_millimeters = 1.5;
seed = 303;
baseline = p03_baseline(sample_count, shared_motion_coefficient, ...
    sigma_a_millimeters, sigma_b_millimeters, seed);
assert(abs(baseline.covariance_millimeters_squared - ...
    shared_motion_coefficient * sigma_a_millimeters * ...
    sigma_b_millimeters) < 1e-12, ...
    'The baseline covariance must equal rho*sigma_A*sigma_B.');
assert(abs(baseline.correlation_coefficient - ...
    shared_motion_coefficient) < 1e-12, ...
    'The baseline correlation must equal the controlled shared-motion coefficient.');
disp('Pause here: point to same-side products in the trace and the matching scatter-plot tilt.');

%% Parameter sweep 1 - shared-motion coefficient only
sample_count = 400;
sigma_a_millimeters = 1.0;
sigma_b_millimeters = 1.5;
seed = 303;
shared_motion_coefficients = [-0.80 0.00 0.80];
shared_motion_covariances = zeros(size(shared_motion_coefficients));
figure('Name', 'P03 sweep 1: shared-motion coefficient');
for sweep_index = 1:numel(shared_motion_coefficients)
    shared_motion_sweep = model(sample_count, ...
        shared_motion_coefficients(sweep_index), sigma_a_millimeters, ...
        sigma_b_millimeters, seed);
    shared_motion_covariances(sweep_index) = ...
        shared_motion_sweep.covariance_millimeters_squared;
    subplot(1,3,sweep_index);
    scatter(shared_motion_sweep.centered_a_millimeters, ...
        shared_motion_sweep.centered_b_millimeters, 12, 'filled');
    hold on; xline(0, 'k--'); yline(0, 'k--'); hold off;
    grid on; axis equal;
    xlabel('Sensor A deviation (mm)');
    ylabel('Sensor B deviation (mm)');
    title(sprintf('rho = %.2f; C = %.2f mm^2', ...
        shared_motion_coefficients(sweep_index), ...
        shared_motion_covariances(sweep_index)));
end
fprintf('Shared-motion sweep covariance (mm^2): %.2f, %.2f, %.2f\n', ...
    shared_motion_covariances);

%% Explain the first changed view
disp(['Mechanism: rho changes how much of Sensor A''s standardized driver enters Sensor B. ' ...
    'Its sign changes the cloud tilt and the signs of centered pairwise products.']);

%% Reset, then parameter sweep 2 - Sensor B scale only
sample_count = 400;
shared_motion_coefficient = 0.70;
sigma_a_millimeters = 1.0;
seed = 303;
sigma_b_values_millimeters = [0.50 1.50 3.00];
scale_covariances_millimeters_squared = zeros(size(sigma_b_values_millimeters));
scale_correlations = zeros(size(sigma_b_values_millimeters));
scale_limit_reference = model(sample_count, shared_motion_coefficient, ...
    sigma_a_millimeters, max(sigma_b_values_millimeters), seed);
scale_x_limit_millimeters = 1.05 * max(abs( ...
    scale_limit_reference.centered_a_millimeters));
scale_y_limit_millimeters = 1.05 * max(abs( ...
    scale_limit_reference.centered_b_millimeters));
figure('Name', 'P03 sweep 2: Sensor B scale');
for sweep_index = 1:numel(sigma_b_values_millimeters)
    scale_sweep = model(sample_count, shared_motion_coefficient, ...
        sigma_a_millimeters, sigma_b_values_millimeters(sweep_index), seed);
    scale_covariances_millimeters_squared(sweep_index) = ...
        scale_sweep.covariance_millimeters_squared;
    scale_correlations(sweep_index) = scale_sweep.correlation_coefficient;
    subplot(1,3,sweep_index);
    scatter(scale_sweep.centered_a_millimeters, ...
        scale_sweep.centered_b_millimeters, 12, 'filled');
    hold on; xline(0, 'k--'); yline(0, 'k--'); hold off;
    grid on;
    xlim([-scale_x_limit_millimeters scale_x_limit_millimeters]);
    ylim([-scale_y_limit_millimeters scale_y_limit_millimeters]);
    xlabel('Sensor A deviation (mm)');
    ylabel('Sensor B deviation (mm)');
    title(sprintf('sigma_B = %.2f mm; C = %.2f mm^2', ...
        sigma_b_values_millimeters(sweep_index), ...
        scale_covariances_millimeters_squared(sweep_index)));
end
fprintf('Scale sweep correlation (dimensionless): %.2f, %.2f, %.2f\n', ...
    scale_correlations);

%% Explain the second changed view
disp(['Mechanism: multiplying Sensor B deviations stretches the cloud vertically and ' ...
    'multiplies covariance in mm^2. Correlation divides out both RMS scales, so it stays fixed.']);

%% Deliberately broken case - skip centering before multiplying
sample_count = 400;
shared_motion_coefficient = 0.00;
sigma_a_millimeters = 1.0;
sigma_b_millimeters = 1.0;
seed = 303;
mean_a_millimeters = 40.0;
mean_b_millimeters = 30.0;
broken = model(sample_count, shared_motion_coefficient, ...
    sigma_a_millimeters, sigma_b_millimeters, seed, ...
    mean_a_millimeters, mean_b_millimeters);
figure('Name', 'P03 broken case: uncentered cross-product');
plot(1:sample_count, broken.samples_a_millimeters .* ...
    broken.samples_b_millimeters, '.', 'MarkerSize', 8);
hold on;
yline(broken.raw_cross_moment_millimeters_squared, 'r-', ...
    'wrong mean(A B)');
hold off; grid on;
xlabel('Paired observation index (sample)');
ylabel('Uncentered product A_i B_i (mm^2)');
title('Broken: constant offsets masquerade as shared motion');
disp('Pause here: name the false zero-mean assumption before revealing the centered repair.');

%% Repair the broken case - subtract each sensor's own mean
sample_count = 400;
shared_motion_coefficient = 0.00;
sigma_a_millimeters = 1.0;
sigma_b_millimeters = 1.0;
seed = 303;
mean_a_millimeters = 40.0;
mean_b_millimeters = 30.0;
repaired = model(sample_count, shared_motion_coefficient, ...
    sigma_a_millimeters, sigma_b_millimeters, seed, ...
    mean_a_millimeters, mean_b_millimeters);
figure('Name', 'P03 repaired case: centered pairwise products');
subplot(2,1,1);
plot(1:sample_count, repaired.centered_product_millimeters_squared, ...
    '.', 'MarkerSize', 8);
hold on; yline(0, 'k--'); hold off; grid on;
xlabel('Paired observation index (sample)');
ylabel('Centered pair product (mm^2)');
title('Correct: positive and negative orthogonal-record products balance');
subplot(2,1,2);
plot(1:sample_count, ...
    repaired.cumulative_centered_product_average_millimeters_squared, ...
    'LineWidth', 1.2);
hold on; yline(0, 'k--', 'zero-covariance limit'); hold off; grid on;
xlabel('Paired observations included (samples)');
ylabel('Cumulative centered-product average (mm^2)');
title('Center the full records, then average their pairwise products');

fprintf(['Broken raw mean(A B) = %.3f mm^2; repaired covariance = %.3g mm^2. ' ...
    'The %.1f mm and %.1f mm offsets are not shared variation.\n'], ...
    broken.raw_cross_moment_millimeters_squared, ...
    repaired.covariance_millimeters_squared, ...
    mean_a_millimeters, mean_b_millimeters);
