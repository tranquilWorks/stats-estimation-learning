function out = model(sampleCount, binWidthMillivolts, sigmaMillivolts, seed, suppliedSamples, binEdgesMillivolts)
%MODEL Build a transparent histogram of seeded sensor-error samples.
%   Each generated sample is a zero-mean measurement error in millivolts.
%   Counts use left-closed, right-open bins, except the final bin includes
%   its right edge. Probability mass is normalized by every input sample;
%   samples outside the displayed edges remain visible as tail counts.

if nargin < 1 || isempty(sampleCount)
    sampleCount = 1000;
end
if nargin < 2 || isempty(binWidthMillivolts)
    binWidthMillivolts = 0.5;
end
if nargin < 3 || isempty(sigmaMillivolts)
    sigmaMillivolts = 1.0;
end
if nargin < 4 || isempty(seed)
    seed = 202;
end
if nargin < 5
    suppliedSamples = [];
end
if nargin < 6
    binEdgesMillivolts = [];
end

validateattributes(sampleCount, {'numeric'}, ...
    {'scalar','real','finite','integer','positive'}, mfilename, 'sampleCount', 1);
validateattributes(binWidthMillivolts, {'numeric'}, ...
    {'scalar','real','finite','positive'}, mfilename, 'binWidthMillivolts', 2);
validateattributes(sigmaMillivolts, {'numeric'}, ...
    {'scalar','real','finite','positive'}, mfilename, 'sigmaMillivolts', 3);
validateattributes(seed, {'numeric'}, ...
    {'scalar','real','finite','integer','nonnegative'}, mfilename, 'seed', 4);

if sampleCount > 50000
    error('P02:ResourceBound', 'sampleCount must not exceed 50000.');
end
if seed > 4294967295
    error('P02:InvalidSeed', 'seed must fit the uint32 range used by rng.');
end
minimumScaleMillivolts = 1e-9;
maximumScaleMillivolts = 1e6;
maximumMagnitudeMillivolts = 1e7;
if sigmaMillivolts < minimumScaleMillivolts || ...
        binWidthMillivolts < minimumScaleMillivolts || ...
        sigmaMillivolts > maximumScaleMillivolts || ...
        binWidthMillivolts > maximumScaleMillivolts
    error('P02:ResourceBound', ...
        'sigmaMillivolts and binWidthMillivolts must be between 1e-9 and 1e6 mV.');
end

sampleCount = double(sampleCount);
binWidthMillivolts = double(binWidthMillivolts);
sigmaMillivolts = double(sigmaMillivolts);
seed = double(seed);

if isempty(binEdgesMillivolts)
    binsPerSide = max(1, ceil(4 * (sigmaMillivolts / binWidthMillivolts)));
    if ~isfinite(binsPerSide) || binsPerSide > 100
        error('P02:ResourceBound', 'A histogram must not exceed 200 bins.');
    end
    binEdgesMillivolts = (-binsPerSide:binsPerSide) * binWidthMillivolts;
    if any(~isfinite(binEdgesMillivolts))
        error('P02:ResourceBound', 'Generated bin edges must remain finite.');
    end
else
    if numel(binEdgesMillivolts) > 201
        error('P02:ResourceBound', 'A histogram must not exceed 200 bins.');
    end
    validateattributes(binEdgesMillivolts, {'numeric'}, ...
        {'vector','real','finite'}, mfilename, 'binEdgesMillivolts', 6);
    binEdgesMillivolts = double(reshape(binEdgesMillivolts, 1, []));
    if numel(binEdgesMillivolts) < 2 || any(diff(binEdgesMillivolts) <= 0)
        error('P02:InvalidEdges', 'binEdgesMillivolts must be strictly increasing.');
    end
    if any(abs(binEdgesMillivolts) > maximumMagnitudeMillivolts)
        error('P02:ResourceBound', ...
            'The magnitude of a custom bin edge must not exceed 1e7 mV.');
    end
end

binWidthsMillivolts = diff(binEdgesMillivolts);
if any(~isfinite(binWidthsMillivolts)) || ...
        any(binWidthsMillivolts < minimumScaleMillivolts)
    error('P02:InvalidEdges', ...
        'Every derived bin width must be finite and at least 1e-9 mV.');
end
binCount = numel(binEdgesMillivolts) - 1;
if binCount > 200
    error('P02:ResourceBound', 'A histogram must not exceed 200 bins.');
end

if isempty(suppliedSamples)
    callerRngState = rng;
    restoreCallerRng = onCleanup(@() rng(callerRngState)); %#ok<NASGU>
    rng(seed, 'twister');
    samplesMillivolts = sigmaMillivolts * randn(1, sampleCount);
else
    if numel(suppliedSamples) ~= sampleCount
        error('P02:SampleCountMismatch', ...
            'sampleCount must equal the number of supplied samples.');
    end
    validateattributes(suppliedSamples, {'numeric'}, ...
        {'vector','real','finite'}, mfilename, 'suppliedSamples', 5);
    samplesMillivolts = double(reshape(suppliedSamples, 1, []));
    if any(abs(samplesMillivolts) > maximumMagnitudeMillivolts)
        error('P02:ResourceBound', ...
            'The magnitude of a supplied sample must not exceed 1e7 mV.');
    end
end

counts = zeros(1, binCount);
for binIndex = 1:binCount
    leftEdge = binEdgesMillivolts(binIndex);
    rightEdge = binEdgesMillivolts(binIndex + 1);
    if binIndex == binCount
        inBin = samplesMillivolts >= leftEdge & samplesMillivolts <= rightEdge;
    else
        inBin = samplesMillivolts >= leftEdge & samplesMillivolts < rightEdge;
    end
    counts(binIndex) = sum(inBin);
end

binCentersMillivolts = binEdgesMillivolts(1:end-1) + binWidthsMillivolts / 2;
underflowCount = sum(samplesMillivolts < binEdgesMillivolts(1));
overflowCount = sum(samplesMillivolts > binEdgesMillivolts(end));
includedCount = sum(counts);
probabilityMass = counts / sampleCount;
densityPerMillivolt = probabilityMass ./ binWidthsMillivolts;
underflowProbabilityMass = underflowCount / sampleCount;
overflowProbabilityMass = overflowCount / sampleCount;

scaledEdges = binEdgesMillivolts / (sigmaMillivolts * sqrt(2));
theoreticalProbabilityMass = zeros(1, binCount);
for binIndex = 1:binCount
    leftScaledEdge = scaledEdges(binIndex);
    rightScaledEdge = scaledEdges(binIndex + 1);
    if leftScaledEdge >= 0
        % erfc preserves a small difference between two positive-tail CDFs.
        theoreticalProbabilityMass(binIndex) = 0.5 * ...
            (erfc(leftScaledEdge) - erfc(rightScaledEdge));
    elseif rightScaledEdge <= 0
        % Reflect a negative-tail interval before taking the erfc difference.
        theoreticalProbabilityMass(binIndex) = 0.5 * ...
            (erfc(-rightScaledEdge) - erfc(-leftScaledEdge));
    else
        % An interval crossing zero does not subtract two nearly equal values.
        theoreticalProbabilityMass(binIndex) = 0.5 * ...
            (erf(rightScaledEdge) - erf(leftScaledEdge));
    end
end
theoreticalUnderflowProbabilityMass = 0.5 * erfc(-scaledEdges(1));
theoreticalOverflowProbabilityMass = 0.5 * erfc(scaledEdges(end));
theoreticalDensityPerMillivolt = exp(-0.5 * ...
    (binCentersMillivolts / sigmaMillivolts).^2) / ...
    (sigmaMillivolts * sqrt(2 * pi));
nominalProbabilityMassStandardError = sqrt(theoreticalProbabilityMass .* ...
    (1 - theoreticalProbabilityMass) / sampleCount);

sampleMeanMillivolts = sum(samplesMillivolts) / sampleCount;
% Use N because this is the RMS spread of the displayed empirical mass,
% not the N-1 unbiased estimator of an unknown population variance.
sampleVarianceMillivoltsSquared = sum((samplesMillivolts - ...
    sampleMeanMillivolts).^2) / sampleCount;
if ~isfinite(sampleMeanMillivolts) || ...
        ~isfinite(sampleVarianceMillivoltsSquared) || ...
        any(~isfinite(densityPerMillivolt)) || ...
        any(~isfinite(theoreticalDensityPerMillivolt)) || ...
        any(~isfinite(nominalProbabilityMassStandardError)) || ...
        ~isfinite(theoreticalUnderflowProbabilityMass) || ...
        ~isfinite(theoreticalOverflowProbabilityMass)
    error('P02:NumericalFailure', ...
        'Validated inputs must produce finite histogram metrics.');
end
[sortedSamplesMillivolts, ~] = sort(samplesMillivolts);

out = struct();
out.samples_millivolts = samplesMillivolts;
out.sorted_samples_millivolts = sortedSamplesMillivolts;
out.empirical_cdf = (1:sampleCount) / sampleCount;
out.bin_edges_millivolts = binEdgesMillivolts;
out.bin_centers_millivolts = binCentersMillivolts;
out.bin_widths_millivolts = binWidthsMillivolts;
out.counts = counts;
out.probability_mass = probabilityMass;
out.density_per_millivolt = densityPerMillivolt;
out.underflow_probability_mass = underflowProbabilityMass;
out.overflow_probability_mass = overflowProbabilityMass;
out.theoretical_probability_mass = theoreticalProbabilityMass;
out.theoretical_underflow_probability_mass = theoreticalUnderflowProbabilityMass;
out.theoretical_overflow_probability_mass = theoreticalOverflowProbabilityMass;
out.theoretical_density_per_millivolt = theoreticalDensityPerMillivolt;
out.nominal_probability_mass_standard_error = ...
    nominalProbabilityMassStandardError;
out.underflow_count = underflowCount;
out.overflow_count = overflowCount;
out.included_count = includedCount;
out.included_fraction = includedCount / sampleCount;
out.normalization_area = sum(densityPerMillivolt .* binWidthsMillivolts);
out.l1_probability_error = ...
    abs(underflowProbabilityMass - theoreticalUnderflowProbabilityMass) + ...
    sum(abs(probabilityMass - theoreticalProbabilityMass)) + ...
    abs(overflowProbabilityMass - theoreticalOverflowProbabilityMass);
out.sample_mean_millivolts = sampleMeanMillivolts;
out.sample_standard_deviation_millivolts = sqrt(sampleVarianceMillivoltsSquared);
out.sample_count = sampleCount;
out.requested_bin_width_millivolts = binWidthMillivolts;
out.sigma_millivolts = sigmaMillivolts;
out.seed = seed;
out.edge_convention = 'left-closed/right-open; final bin right-closed';
end
