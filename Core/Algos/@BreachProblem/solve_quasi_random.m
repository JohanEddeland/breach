function res = solve_quasi_random(this)
% solve_quasi_random works with quasi-random sampling   
% 

this.display_status_header();

BrQ = this.BrSet.copy();
BrQ.ResetParamSet();
BrQ.SetParamRanges(this.params, [this.lb this.ub])
seed = this.solver_options.quasi_rand_seed;
num_samples =  this.solver_options.num_quasi_rand_samples;
BrQ.QuasiRandomSample(num_samples, seed);
X0 = BrQ.GetParam(this.params);

res = this.FevalInit(X0);
this.add_res(res); 

end
