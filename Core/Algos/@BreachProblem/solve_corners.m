function res = solve_corners(this)
% solve_corners works with quasi-random sampling   
% 

this.display_status_header();

BrC = this.BrSet.copy();
BrC.ResetParamSet();
BrC.SetParamRanges(this.params, [this.lb this.ub])
num_corners =  this.solver_options.num_corners;
BrC.CornerSample(num_corners);
X0 = BrC.GetParam(this.params);

res = this.FevalInit(X0);
this.add_res(res); 

end
