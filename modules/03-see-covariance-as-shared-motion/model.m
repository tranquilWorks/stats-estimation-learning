function out = model(sampleCount, sharedMotionCoefficient, ...
    sigmaAMillimeters, sigmaBMillimeters, seed, ...
    meanAMillimeters, meanBMillimeters)
%MODEL Build two deterministic displacement records with controlled covariance.
%   Sensor A uses one standardized driver. Sensor B mixes that same driver
%   with an orthogonal standardized driver. The N-normalized record
%   covariance is therefore rho*sigmaA*sigmaB, while mean offsets do not
%   affect centered covariance.

if nargin < 1 || isempty(sampleCount)
    sampleCount = 400;
end
if nargin < 2 || isempty(sharedMotionCoefficient)
    sharedMotionCoefficient = 0.70;
end
if nargin < 3 || isempty(sigmaAMillimeters)
    sigmaAMillimeters = 1.0;
end
if nargin < 4 || isempty(sigmaBMillimeters)
    sigmaBMillimeters = 1.5;
end
if nargin < 5 || isempty(seed)
    seed = 303;
end
if nargin < 6 || isempty(meanAMillimeters)
    meanAMillimeters = 0.0;
end
if nargin < 7 || isempty(meanBMillimeters)
    meanBMillimeters = 0.0;
end

validateattributes(sampleCount, {'numeric'}, ...
    {'scalar','real','finite','integer','positive'}, mfilename, 'sampleCount', 1);
validateattributes(sharedMotionCoefficient, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'sharedMotionCoefficient', 2);
validateattributes(sigmaAMillimeters, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'sigmaAMillimeters', 3);
validateattributes(sigmaBMillimeters, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'sigmaBMillimeters', 4);
validateattributes(seed, {'numeric'}, ...
    {'scalar','real','finite','integer','nonnegative'}, mfilename, 'seed', 5);
validateattributes(meanAMillimeters, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'meanAMillimeters', 6);
validateattributes(meanBMillimeters, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'meanBMillimeters', 7);

sampleCount = double(sampleCount);
sharedMotionCoefficient = double(sharedMotionCoefficient);
sigmaAMillimeters = double(sigmaAMillimeters);
sigmaBMillimeters = double(sigmaBMillimeters);
seed = double(seed);
meanAMillimeters = double(meanAMillimeters);
meanBMillimeters = double(meanBMillimeters);

if sampleCount < 3
    error('P03:InsufficientSamples', ...
        'sampleCount must be at least 3 to form two centered orthogonal drivers.');
end
if sampleCount > 50000
    error('P03:ResourceBound', 'sampleCount must not exceed 50000.');
end
if sharedMotionCoefficient < -1 || sharedMotionCoefficient > 1
    error('P03:InvalidCorrelation', ...
        'sharedMotionCoefficient must be between -1 and 1.');
end
minimumScaleMillimeters = 1e-6;
maximumScaleMillimeters = 1e6;
maximumMeanMagnitudeMillimeters = 1e6;
if sigmaAMillimeters < minimumScaleMillimeters || ...
        sigmaBMillimeters < minimumScaleMillimeters || ...
        sigmaAMillimeters > maximumScaleMillimeters || ...
        sigmaBMillimeters > maximumScaleMillimeters
    error('P03:ResourceBound', ...
        'Sensor RMS scales must be between 1e-6 and 1e6 mm.');
end
if abs(meanAMillimeters) > maximumMeanMagnitudeMillimeters || ...
        abs(meanBMillimeters) > maximumMeanMagnitudeMillimeters
    error('P03:ResourceBound', ...
        'The magnitude of either sensor mean must not exceed 1e6 mm.');
end
maximumMeanToScaleRatio = 1e9;
if abs(meanAMillimeters) > maximumMeanToScaleRatio * sigmaAMillimeters || ...
        abs(meanBMillimeters) > maximumMeanToScaleRatio * sigmaBMillimeters
    error('P03:ResourceBound', ...
        'Each mean-to-RMS-scale ratio must not exceed 1e9.');
end
if seed > 4294967295
    error('P03:InvalidSeed', 'seed must fit the uint32 range used by rng.');
end

callerRngState = rng;
restoreCallerRng = onCleanup(@() rng(callerRngState)); %#ok<NASGU>
rng(seed, 'twister');
baseDrivers = randn(2, sampleCount);

% Center and normalize the first driver using explicit N-normalized energy.
driverA = baseDrivers(1, :);
driverA = driverA - sum(driverA) / sampleCount;
driverAEnergy = sum(driverA .^ 2) / sampleCount;
if ~isfinite(driverAEnergy) || driverAEnergy <= 1e-12
    error('P03:DegenerateDrivers', ...
        'The seeded first driver cannot be standardized safely.');
end
driverA = driverA / sqrt(driverAEnergy);

% Remove both the mean and the projection on driver A from the second driver.
driverB = baseDrivers(2, :);
driverB = driverB - sum(driverB) / sampleCount;
projection = sum(driverA .* driverB) / sum(driverA .^ 2);
driverB = driverB - projection * driverA;
driverB = driverB - sum(driverB) / sampleCount;
driverBEnergy = sum(driverB .^ 2) / sampleCount;
if ~isfinite(driverBEnergy) || driverBEnergy <= 1e-12
    error('P03:DegenerateDrivers', ...
        'The seeded second driver cannot be orthogonalized safely.');
end
driverB = driverB / sqrt(driverBEnergy);

orthogonalWeight = sqrt(max(0, 1 - sharedMotionCoefficient ^ 2));
centeredAMillimeters = sigmaAMillimeters * driverA;
sharedBMillimeters = sigmaBMillimeters * ...
    sharedMotionCoefficient * driverA;
orthogonalBMillimeters = sigmaBMillimeters * orthogonalWeight * driverB;
centeredBMillimeters = sharedBMillimeters + orthogonalBMillimeters;
samplesAMillimeters = meanAMillimeters + centeredAMillimeters;
samplesBMillimeters = meanBMillimeters + centeredBMillimeters;

observedMeanAMillimeters = sum(samplesAMillimeters) / sampleCount;
observedMeanBMillimeters = sum(samplesBMillimeters) / sampleCount;
observedCenteredAMillimeters = samplesAMillimeters - observedMeanAMillimeters;
observedCenteredBMillimeters = samplesBMillimeters - observedMeanBMillimeters;
centeredProductMillimetersSquared = ...
    observedCenteredAMillimeters .* observedCenteredBMillimeters;
varianceAMillimetersSquared = ...
    sum(observedCenteredAMillimeters .^ 2) / sampleCount;
varianceBMillimetersSquared = ...
    sum(observedCenteredBMillimeters .^ 2) / sampleCount;
covarianceMillimetersSquared = ...
    sum(centeredProductMillimetersSquared) / sampleCount;
standardDeviationAMillimeters = sqrt(varianceAMillimetersSquared);
standardDeviationBMillimeters = sqrt(varianceBMillimetersSquared);
correlationDenominator = ...
    standardDeviationAMillimeters * standardDeviationBMillimeters;
correlationCoefficient = covarianceMillimetersSquared / correlationDenominator;
cumulativeCenteredProductAverageMillimetersSquared = ...
    cumsum(centeredProductMillimetersSquared) ./ (1:sampleCount);
rawCrossMomentMillimetersSquared = ...
    sum(samplesAMillimeters .* samplesBMillimeters) / sampleCount;
targetCovarianceMillimetersSquared = ...
    sharedMotionCoefficient * sigmaAMillimeters * sigmaBMillimeters;
nMinusOneCovarianceMillimetersSquared = ...
    sum(centeredProductMillimetersSquared) / (sampleCount - 1);
covarianceMatrixMillimetersSquared = ...
    [varianceAMillimetersSquared covarianceMillimetersSquared; ...
    covarianceMillimetersSquared varianceBMillimetersSquared];
covarianceDeterminantMillimetersFourth = ...
    varianceAMillimetersSquared * varianceBMillimetersSquared - ...
    covarianceMillimetersSquared ^ 2;
analyticPsdMarginMillimetersFourth = ...
    sigmaAMillimeters ^ 2 * sigmaBMillimeters ^ 2 * ...
    (1 - sharedMotionCoefficient ^ 2);

if any(~isfinite(samplesAMillimeters)) || ...
        any(~isfinite(samplesBMillimeters)) || ...
        any(~isfinite(centeredProductMillimetersSquared)) || ...
        any(~isfinite(cumulativeCenteredProductAverageMillimetersSquared)) || ...
        ~isfinite(correlationCoefficient) || ...
        ~isfinite(rawCrossMomentMillimetersSquared) || ...
        ~isfinite(covarianceDeterminantMillimetersFourth) || ...
        ~isfinite(analyticPsdMarginMillimetersFourth)
    error('P03:NumericalFailure', ...
        'Validated inputs must produce finite covariance metrics.');
end

out = struct();
out.samples_a_millimeters = samplesAMillimeters;
out.samples_b_millimeters = samplesBMillimeters;
out.centered_a_millimeters = observedCenteredAMillimeters;
out.centered_b_millimeters = observedCenteredBMillimeters;
out.shared_b_millimeters = sharedBMillimeters;
out.orthogonal_b_millimeters = orthogonalBMillimeters;
out.centered_product_millimeters_squared = centeredProductMillimetersSquared;
out.cumulative_centered_product_average_millimeters_squared = ...
    cumulativeCenteredProductAverageMillimetersSquared;
out.mean_a_millimeters = observedMeanAMillimeters;
out.mean_b_millimeters = observedMeanBMillimeters;
out.variance_a_millimeters_squared = varianceAMillimetersSquared;
out.variance_b_millimeters_squared = varianceBMillimetersSquared;
out.standard_deviation_a_millimeters = standardDeviationAMillimeters;
out.standard_deviation_b_millimeters = standardDeviationBMillimeters;
out.covariance_millimeters_squared = covarianceMillimetersSquared;
out.target_covariance_millimeters_squared = ...
    targetCovarianceMillimetersSquared;
out.n_minus_one_covariance_millimeters_squared = ...
    nMinusOneCovarianceMillimetersSquared;
out.correlation_coefficient = correlationCoefficient;
out.raw_cross_moment_millimeters_squared = rawCrossMomentMillimetersSquared;
out.covariance_matrix_millimeters_squared = covarianceMatrixMillimetersSquared;
out.covariance_determinant_millimeters_fourth = ...
    covarianceDeterminantMillimetersFourth;
out.analytic_psd_margin_millimeters_fourth = ...
    analyticPsdMarginMillimetersFourth;
out.same_direction_fraction = ...
    sum(centeredProductMillimetersSquared > 0) / sampleCount;
out.sample_count = sampleCount;
out.shared_motion_coefficient = sharedMotionCoefficient;
out.sigma_a_millimeters = sigmaAMillimeters;
out.sigma_b_millimeters = sigmaBMillimeters;
out.seed = seed;
out.requested_mean_a_millimeters = meanAMillimeters;
out.requested_mean_b_millimeters = meanBMillimeters;
out.normalization = 'N-normalized record covariance';
end
