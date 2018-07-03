% 1. Just for making log "allLogFalsify"
display('******** Start tuto_falsify_TMCandTMNA.m ********')
tuto_falsify_TMCandTMNA;

% 2. Our one use-case is storing this log on file-sever 
display('******** Rename ChachFolder Name ********')
movefile('allLogFalsify','fileSeverFolder/allLogFalsify')
clear;

% 3. Use stored folder again
display('******** Recreate Brlog ********')
falsif_pb = FalsificationProblem.load_runs('fileSeverFolder/allLogFalsify');
BrLog = falsif_pb.BrSys;
falsif_pb.X_log = unique(falsif_pb.X_log','rows')';
BrLog.SetParam(falsif_pb.params, falsif_pb.X_log);
BrLog.Sim();
[v, V] = falsif_pb.Spec.Eval(BrLog);