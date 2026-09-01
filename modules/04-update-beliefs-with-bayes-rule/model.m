function out = model(priorFaultProbability, alarmGivenFaultProbability, ...
    alarmGivenHealthyProbability, referencePopulationCount)
%MODEL Update a binary fault belief after observing one alarm.
%   The four joint condition/alarm cells are formed explicitly. The
%   observed alarm column is then normalized to obtain P(fault | alarm).

if nargin < 1 || isempty(priorFaultProbability)
    priorFaultProbability = 0.01;
end
if nargin < 2 || isempty(alarmGivenFaultProbability)
    alarmGivenFaultProbability = 0.90;
end
if nargin < 3 || isempty(alarmGivenHealthyProbability)
    alarmGivenHealthyProbability = 0.10;
end
if nargin < 4 || isempty(referencePopulationCount)
    referencePopulationCount = 10000;
end

validateattributes(priorFaultProbability, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'priorFaultProbability', 1);
validateattributes(alarmGivenFaultProbability, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'alarmGivenFaultProbability', 2);
validateattributes(alarmGivenHealthyProbability, {'numeric'}, ...
    {'scalar','real','finite'}, mfilename, 'alarmGivenHealthyProbability', 3);
validateattributes(referencePopulationCount, {'numeric'}, ...
    {'scalar','real','finite','integer','positive'}, ...
    mfilename, 'referencePopulationCount', 4);

priorFaultProbability = double(priorFaultProbability);
alarmGivenFaultProbability = double(alarmGivenFaultProbability);
alarmGivenHealthyProbability = double(alarmGivenHealthyProbability);
referencePopulationCount = double(referencePopulationCount);

probabilityInputs = [priorFaultProbability, ...
    alarmGivenFaultProbability, alarmGivenHealthyProbability];
if any(probabilityInputs < 0) || any(probabilityInputs > 1)
    error('P04:InvalidProbability', ...
        'Prior, sensitivity, and false-alarm probabilities must be in [0, 1].');
end
if referencePopulationCount > 10000000
    error('P04:ResourceBound', ...
        'referencePopulationCount must not exceed 10000000.');
end

priorHealthyProbability = 1 - priorFaultProbability;
jointFaultAlarmProbability = ...
    priorFaultProbability * alarmGivenFaultProbability;
jointFaultNoAlarmProbability = ...
    priorFaultProbability * (1 - alarmGivenFaultProbability);
jointHealthyAlarmProbability = ...
    priorHealthyProbability * alarmGivenHealthyProbability;
jointHealthyNoAlarmProbability = ...
    priorHealthyProbability * (1 - alarmGivenHealthyProbability);

alarmProbability = ...
    jointFaultAlarmProbability + jointHealthyAlarmProbability;
noAlarmProbability = ...
    jointFaultNoAlarmProbability + jointHealthyNoAlarmProbability;
if alarmProbability == 0
    error('P04:ImpossibleObservation', ...
        'An alarm cannot be conditioned on when its total probability is zero.');
end

posteriorFaultGivenAlarmProbability = ...
    jointFaultAlarmProbability / alarmProbability;
posteriorHealthyGivenAlarmProbability = ...
    jointHealthyAlarmProbability / alarmProbability;

if priorHealthyProbability == 0
    priorFaultOdds = Inf;
else
    priorFaultOdds = priorFaultProbability / priorHealthyProbability;
end
if alarmGivenHealthyProbability == 0
    positiveLikelihoodRatio = Inf;
else
    positiveLikelihoodRatio = ...
        alarmGivenFaultProbability / alarmGivenHealthyProbability;
end
if posteriorHealthyGivenAlarmProbability == 0
    posteriorFaultOdds = Inf;
else
    posteriorFaultOdds = posteriorFaultGivenAlarmProbability / ...
        posteriorHealthyGivenAlarmProbability;
end

expectedFaultCount = ...
    referencePopulationCount * priorFaultProbability;
expectedHealthyCount = ...
    referencePopulationCount * priorHealthyProbability;
expectedFaultAlarmCount = ...
    referencePopulationCount * jointFaultAlarmProbability;
expectedFaultNoAlarmCount = ...
    referencePopulationCount * jointFaultNoAlarmProbability;
expectedHealthyAlarmCount = ...
    referencePopulationCount * jointHealthyAlarmProbability;
expectedHealthyNoAlarmCount = ...
    referencePopulationCount * jointHealthyNoAlarmProbability;
expectedAlarmCount = ...
    expectedFaultAlarmCount + expectedHealthyAlarmCount;

jointProbabilities = [jointFaultAlarmProbability, ...
    jointFaultNoAlarmProbability, jointHealthyAlarmProbability, ...
    jointHealthyNoAlarmProbability];
finiteOutputs = [jointProbabilities, alarmProbability, noAlarmProbability, ...
    posteriorFaultGivenAlarmProbability, ...
    posteriorHealthyGivenAlarmProbability, expectedFaultCount, ...
    expectedHealthyCount, expectedFaultAlarmCount, ...
    expectedFaultNoAlarmCount, expectedHealthyAlarmCount, ...
    expectedHealthyNoAlarmCount, expectedAlarmCount];
probabilityTolerance = 64 * eps;
if any(~isfinite(finiteOutputs)) || ...
        any(jointProbabilities < 0) || any(jointProbabilities > 1) || ...
        abs(sum(jointProbabilities) - 1) > probabilityTolerance || ...
        abs(posteriorFaultGivenAlarmProbability + ...
        posteriorHealthyGivenAlarmProbability - 1) > probabilityTolerance
    error('P04:NumericalFailure', ...
        'Validated inputs must produce finite, normalized probability masses.');
end

out = struct();
out.prior_fault_probability = priorFaultProbability;
out.prior_healthy_probability = priorHealthyProbability;
out.alarm_given_fault_probability = alarmGivenFaultProbability;
out.alarm_given_healthy_probability = alarmGivenHealthyProbability;
out.joint_fault_alarm_probability = jointFaultAlarmProbability;
out.joint_fault_no_alarm_probability = jointFaultNoAlarmProbability;
out.joint_healthy_alarm_probability = jointHealthyAlarmProbability;
out.joint_healthy_no_alarm_probability = jointHealthyNoAlarmProbability;
out.alarm_probability = alarmProbability;
out.no_alarm_probability = noAlarmProbability;
out.posterior_fault_given_alarm_probability = ...
    posteriorFaultGivenAlarmProbability;
out.posterior_healthy_given_alarm_probability = ...
    posteriorHealthyGivenAlarmProbability;
out.prior_fault_odds = priorFaultOdds;
out.positive_likelihood_ratio = positiveLikelihoodRatio;
out.posterior_fault_odds = posteriorFaultOdds;
out.expected_fault_count = expectedFaultCount;
out.expected_healthy_count = expectedHealthyCount;
out.expected_fault_alarm_count = expectedFaultAlarmCount;
out.expected_fault_no_alarm_count = expectedFaultNoAlarmCount;
out.expected_healthy_alarm_count = expectedHealthyAlarmCount;
out.expected_healthy_no_alarm_count = expectedHealthyNoAlarmCount;
out.expected_alarm_count = expectedAlarmCount;
out.reference_population_count = referencePopulationCount;
out.probability_units = 'dimensionless probability';
out.expected_count_units = sprintf( ...
    'expected systems per %d opportunities', referencePopulationCount);
out.normalization = 'Bayes rule over the observed alarm column';
end
