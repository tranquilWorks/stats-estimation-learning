function out = model(sampleCount, trueSignalMillivolts, ...
    noiseStandardDeviationMillivolts, seed, ...
    calibrationBiasMillivolts, suppliedStandardizedNoise)
%MODEL Build a deterministic noisy record and its running sample mean.
%   Measurements follow X_i = mu + b + sigma*Z_i. The running sample mean
%   is formed explicitly with cumulative sums, while sigma/sqrt(n) shows
%   the theoretical random-error scale. A supplied standardized-noise
%   vector can replace the seeded realization for exact check fixtures.

if nargin < 1 || isempty(sampleCount)
    sampleCount = 400;
end
if nargin < 2 || isempty(trueSignalMillivolts)
    trueSignalMillivolts = 12.0;
end
if nargin < 3 || isempty(noiseStandardDeviationMillivolts)
    noiseStandardDeviationMillivolts = 4.0;
end
if nargin < 4 || isempty(seed)
    seed = 505;
end
if nargin < 5 || isempty(calibrationBiasMillivolts)
    calibrationBiasMillivolts = 0.0;
end
if nargin < 6
    suppliedStandardizedNoise = [];
end

validateattributes(sampleCount, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'sampleCount', 1);
validateattributes(trueSignalMillivolts, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'trueSignalMillivolts', 2);
validateattributes(noiseStandardDeviationMillivolts, {'numeric'}, ...
    {'scalar','real','finite'}, ...
    mfilename, 'noiseStandardDeviationMillivolts', 3);
validateattributes(seed, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'seed', 4);
validateattributes(calibrationBiasMillivolts, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'calibrationBiasMillivolts', 5);

sampleCount = double(sampleCount);
trueSignalMillivolts = double(trueSignalMillivolts);
noiseStandardDeviationMillivolts = ...
    double(noiseStandardDeviationMillivolts);
seed = double(seed);
calibrationBiasMillivolts = double(calibrationBiasMillivolts);

if sampleCount < 1 || sampleCount ~= floor(sampleCount)
    error('P05:InvalidSampleCount', ...
        'sampleCount must be a positive integer.');
end
maximumSampleCount = 50000;
if sampleCount > maximumSampleCount
    error('P05:ResourceBound', ...
        'sampleCount must not exceed 50000.');
end
if noiseStandardDeviationMillivolts < 0
    error('P05:InvalidNoiseScale', ...
        'noiseStandardDeviationMillivolts must be nonnegative.');
end
if seed < 0 || seed ~= floor(seed) || seed > 4294967295
    error('P05:InvalidSeed', ...
        'seed must be an integer in the uint32 range.');
end
maximumMagnitudeMillivolts = 1e6;
if abs(trueSignalMillivolts) > maximumMagnitudeMillivolts || ...
        noiseStandardDeviationMillivolts > maximumMagnitudeMillivolts || ...
        abs(calibrationBiasMillivolts) > maximumMagnitudeMillivolts
    error('P05:ResourceBound', ...
        'Signal, noise scale, and calibration bias must not exceed 1e6 mV in magnitude.');
end

if isempty(suppliedStandardizedNoise)
    callerRngState = rng;
    restoreCallerRng = onCleanup(@() rng(callerRngState)); %#ok<NASGU>
    rng(seed, 'twister');
    standardizedNoise = randn(1, sampleCount);
else
    if ~isnumeric(suppliedStandardizedNoise) || ...
            ~isreal(suppliedStandardizedNoise) || ...
            ~isvector(suppliedStandardizedNoise)
        error('P05:InvalidNoiseFixture', ...
            'suppliedStandardizedNoise must be a finite real numeric vector.');
    end
    if numel(suppliedStandardizedNoise) ~= sampleCount
        error('P05:SampleCountMismatch', ...
            'suppliedStandardizedNoise must contain exactly sampleCount values.');
    end
    if any(~isfinite(suppliedStandardizedNoise(:)))
        error('P05:InvalidNoiseFixture', ...
            'suppliedStandardizedNoise must contain only finite values.');
    end
    standardizedNoise = reshape(double(suppliedStandardizedNoise), 1, []);
end

observationCounts = 1:sampleCount;
expectedMeasurementCenterMillivolts = ...
    trueSignalMillivolts + calibrationBiasMillivolts;
measurementsMillivolts = expectedMeasurementCenterMillivolts + ...
    noiseStandardDeviationMillivolts * standardizedNoise;
runningSampleMeanMillivolts = ...
    cumsum(measurementsMillivolts) ./ observationCounts;
runningErrorFromTrueMillivolts = ...
    runningSampleMeanMillivolts - trueSignalMillivolts;
runningRandomErrorMillivolts = ...
    runningSampleMeanMillivolts - expectedMeasurementCenterMillivolts;
theoreticalStandardErrorMillivolts = ...
    noiseStandardDeviationMillivolts ./ sqrt(observationCounts);
theoreticalTargetRmseMillivolts = sqrt( ...
    calibrationBiasMillivolts ^ 2 + ...
    theoreticalStandardErrorMillivolts .^ 2);
twoStandardErrorLowerMillivolts = ...
    expectedMeasurementCenterMillivolts - ...
    2 * theoreticalStandardErrorMillivolts;
twoStandardErrorUpperMillivolts = ...
    expectedMeasurementCenterMillivolts + ...
    2 * theoreticalStandardErrorMillivolts;

finiteOutputs = [standardizedNoise, measurementsMillivolts, ...
    runningSampleMeanMillivolts, runningErrorFromTrueMillivolts, ...
    runningRandomErrorMillivolts, theoreticalStandardErrorMillivolts, ...
    theoreticalTargetRmseMillivolts, ...
    twoStandardErrorLowerMillivolts, ...
    twoStandardErrorUpperMillivolts];
if any(~isfinite(finiteOutputs))
    error('P05:NumericalFailure', ...
        'Validated inputs must produce finite sample-mean outputs.');
end

out = struct();
out.observation_counts = observationCounts;
out.standardized_noise = standardizedNoise;
out.measurements_millivolts = measurementsMillivolts;
out.running_sample_mean_millivolts = runningSampleMeanMillivolts;
out.running_error_from_true_millivolts = ...
    runningErrorFromTrueMillivolts;
out.running_random_error_millivolts = runningRandomErrorMillivolts;
out.theoretical_standard_error_millivolts = ...
    theoreticalStandardErrorMillivolts;
out.theoretical_target_rmse_millivolts = ...
    theoreticalTargetRmseMillivolts;
out.two_standard_error_lower_millivolts = ...
    twoStandardErrorLowerMillivolts;
out.two_standard_error_upper_millivolts = ...
    twoStandardErrorUpperMillivolts;
out.final_sample_mean_millivolts = ...
    runningSampleMeanMillivolts(end);
out.final_error_from_true_millivolts = ...
    runningErrorFromTrueMillivolts(end);
out.final_random_error_millivolts = runningRandomErrorMillivolts(end);
out.final_standard_error_millivolts = ...
    theoreticalStandardErrorMillivolts(end);
out.final_target_rmse_millivolts = ...
    theoreticalTargetRmseMillivolts(end);
out.sample_count = sampleCount;
out.true_signal_millivolts = trueSignalMillivolts;
out.noise_standard_deviation_millivolts = ...
    noiseStandardDeviationMillivolts;
out.seed = seed;
out.calibration_bias_millivolts = calibrationBiasMillivolts;
out.expected_measurement_center_millivolts = ...
    expectedMeasurementCenterMillivolts;
out.measurement_units = 'millivolts (mV)';
out.count_units = 'samples';
out.random_error_scale = 'sigma/sqrt(n)';
out.target_error_model = 'sqrt(bias^2 + sigma^2/n)';
end
