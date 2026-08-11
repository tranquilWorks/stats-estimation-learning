function run_checks
a = model(200,0.5,84);
b = model(200,0.5,84);
assert(isequal(a.trials,b.trials),'Seeded model must be deterministic.');
assert(numel(a.running_probability)==200,'Running estimate length mismatch.');
assert(abs(mean(a.counts)-100) < 12,'Ensemble center is implausible.');
small = model(25,0.5,90);
large = model(900,0.5,90);
assert(large.standard_error < small.standard_error,'Standard error must shrink with n.');
disp('P01 checks passed.');
end
