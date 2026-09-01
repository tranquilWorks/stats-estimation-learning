function baseline = p03_baseline(sampleCount, sharedMotionCoefficient, ...
    sigmaAMillimeters, sigmaBMillimeters, seed)
%P03_BASELINE Present exactly one deterministic shared-motion baseline.

if nargin < 1
    sampleCount = 400;
end
if nargin < 2
    sharedMotionCoefficient = 0.70;
end
if nargin < 3
    sigmaAMillimeters = 1.0;
end
if nargin < 4
    sigmaBMillimeters = 1.5;
end
if nargin < 5
    seed = 303;
end

baseline = model(sampleCount, sharedMotionCoefficient, ...
    sigmaAMillimeters, sigmaBMillimeters, seed);

p03Figures = findall(groot, 'Type', 'figure', '-regexp', 'Name', '^P03 ');
if ~isempty(p03Figures)
    close(p03Figures);
end
figure('Name', 'P03 baseline: centered motion becomes covariance');

visibleCount = min(sampleCount, 200);
subplot(2,2,[1 2]);
plot(1:visibleCount, baseline.centered_a_millimeters(1:visibleCount), ...
    'LineWidth', 1.0, 'DisplayName', 'Sensor A');
hold on;
plot(1:visibleCount, baseline.centered_b_millimeters(1:visibleCount), ...
    'LineWidth', 1.0, 'DisplayName', 'Sensor B');
yline(0, 'k--', 'zero deviation');
hold off; grid on;
xlabel('Observation index (sample)');
ylabel('Centered displacement (mm)');
title('Paired deviations reveal same-direction motion');
legend('Location', 'best');

subplot(2,2,3);
scatter(baseline.centered_a_millimeters, ...
    baseline.centered_b_millimeters, 16, 'filled');
hold on; xline(0, 'k--'); yline(0, 'k--'); hold off;
grid on; axis equal;
xlabel('Sensor A deviation (mm)');
ylabel('Sensor B deviation (mm)');
title(sprintf('Tilt: covariance = %.3f mm^2', ...
    baseline.covariance_millimeters_squared));

subplot(2,2,4);
plot(1:sampleCount, ...
    baseline.cumulative_centered_product_average_millimeters_squared, ...
    'LineWidth', 1.2);
hold on;
yline(baseline.target_covariance_millimeters_squared, 'k--', ...
    'target rho sigma_A sigma_B');
hold off; grid on;
xlabel('Paired observations included (samples)');
ylabel('Cumulative centered-product average (mm^2)');
title('Full-record-centered contributions accumulate to covariance');

fprintf(['Baseline: N = %d pairs, rho = %.2f, sigma_A = %.2f mm, ' ...
    'sigma_B = %.2f mm, covariance = %.3f mm^2, correlation = %.3f, ' ...
    'same-direction products = %.1f%%\n'], ...
    baseline.sample_count, baseline.shared_motion_coefficient, ...
    baseline.standard_deviation_a_millimeters, ...
    baseline.standard_deviation_b_millimeters, ...
    baseline.covariance_millimeters_squared, ...
    baseline.correlation_coefficient, ...
    100 * baseline.same_direction_fraction);
end
