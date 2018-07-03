display('******** Start tuto_falsify_TMCandTMNA.m ********')
tuto_falsify_TMCandTMNA;

display('******** Rename ChachFolder Name ********')
movefile('allLogFalsify','allLogFalsify_test')

display('******** Recreate Brlog ********')
curent_path = pwd;
filepath = [curent_path '\allLogFalsify_test'];
FalsificationProblem.load_runs('allLogFalsify_test',filepath)
BrLog = falsif_pb.BrSys;
falsif_pb.X_log = unique(falsif_pb.X_log','rows')';
BrLog.SetParam(falsif_pb.params, falsif_pb.X_log);
BrLog.Sim();
[v, V] = falsif_pb.Spec.Eval(BrLog);


