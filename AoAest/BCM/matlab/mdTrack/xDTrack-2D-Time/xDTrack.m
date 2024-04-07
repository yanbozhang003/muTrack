function [PathP,it_num] = xDTrack(X_tx,Y_rx,opt)
 
%  init xDTrack
[PathP,wave,C_steer,U_delay,path_num] = xDTrack_init(X_tx,Y_rx,opt);

% drop those paths with low power
PathP           = PathP(1:path_num,:);
wave            = wave(:,:,1:path_num);
C_steer         = C_steer(:,1:path_num);
U_delay         = U_delay(1:path_num,:);

% iterative interference cancellation
[PathP,it_num]  = xDTrack_iterative_IC(X_tx,Y_rx,opt,PathP,wave,C_steer,U_delay); 
end
