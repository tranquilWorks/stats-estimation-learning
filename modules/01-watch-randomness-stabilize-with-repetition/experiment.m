%% P01 - Watch Randomness Stabilize with Repetition
% Guiding question:
% What does repetition reveal about random variation?

close all; clc;

%% Baseline controls
n = 200;
p = 0.50;
seed = 84;
out = model(n,p,seed);

%% Baseline views
figure('Name','P01 baseline');
subplot(2,1,1);
plot(1:n,out.running_probability,'LineWidth',1.3);
hold on; yline(p,'--','True probability');
grid on; xlabel('Trial'); ylabel('Running proportion');
title('One realization gradually stabilizes');

subplot(2,1,2);
histogram(out.counts,'BinMethod','integers','Normalization','probability');
hold on; xline(out.expected_count,'--','Expected count');
grid on; xlabel('Successes in n trials'); ylabel('Relative frequency');
title('Many independent repetitions form a sampling distribution');

%% Parameter sweep 1 - sample size
sample_sizes = [20 100 500];
figure('Name','P01 sweep: sample size'); hold on; grid on;
for k = 1:numel(sample_sizes)
    sweep = model(sample_sizes(k),p,seed+k);
    plot(1:sample_sizes(k),sweep.running_probability,'LineWidth',1.1, ...
        'DisplayName',sprintf('n = %d',sample_sizes(k)));
end
yline(p,'--','True p'); xlabel('Trial'); ylabel('Running proportion');
title('Longer records reduce estimator volatility'); legend('Location','best');

%% Parameter sweep 2 - underlying probability
probabilities = [0.2 0.5 0.8];
figure('Name','P01 sweep: probability'); hold on; grid on;
for k = 1:numel(probabilities)
    sweep = model(n,probabilities(k),seed+k);
    histogram(sweep.counts,'BinMethod','integers','DisplayStyle','stairs', ...
        'Normalization','probability','LineWidth',1.2, ...
        'DisplayName',sprintf('p = %.1f',probabilities(k)));
end
xlabel('Successes in n trials'); ylabel('Relative frequency');
title('The center and spread both depend on p'); legend('Location','best');

%% Deliberately broken case - repeat one lucky record
one_record = model(n,p,seed);
fake_ensemble = repmat(sum(one_record.trials),1000,1);
figure('Name','P01 broken case');
histogram(fake_ensemble,'BinMethod','integers');
grid on; xlabel('Successes in n trials'); ylabel('Count');
title('Broken: copying one record creates false certainty');

fprintf('Observed p-hat = %.4f, true p = %.4f, nominal SE = %.4f\n', ...
    out.observed_probability,p,out.standard_error);
assert(abs(mean(out.counts)-n*p) < 0.08*n, ...
    'The ensemble mean should remain near n*p.');
