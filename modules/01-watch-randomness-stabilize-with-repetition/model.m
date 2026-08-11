function out = model(n, p, seed)
%MODEL Seeded Bernoulli trials and repeated-count ensemble.
arguments
    n (1,1) double {mustBeInteger,mustBePositive} = 200
    p (1,1) double {mustBeGreaterThanOrEqual(p,0),mustBeLessThanOrEqual(p,1)} = 0.5
    seed (1,1) double {mustBeInteger,mustBeNonnegative} = 84
end
rng(seed, 'twister');
trials = rand(1,n) < p;
running_probability = cumsum(trials)./(1:n);
ensemble_size = 1000;
counts = sum(rand(ensemble_size,n) < p, 2);
out = struct();
out.trials = trials;
out.running_probability = running_probability;
out.counts = counts;
out.expected_count = n*p;
out.observed_probability = mean(trials);
out.standard_error = sqrt(max(p*(1-p),0)/n);
out.n = n;
out.p = p;
out.seed = seed;
end
