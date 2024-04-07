function [PathP,it_num] = xDTrack_iterative_IC(X_tx,Y_rx,opt,PathP,wave,C_steer,U_delay)
M           = opt.M;            % antenna/sensor number
pwr         = opt.pwr;          % transmitted signal power
f_n         = opt.f_n;
array       = opt.array;

% search step for each dimension
time_scope  = opt.time_scope;
angle_scope = opt.angle_scope;

u_delay_mat = opt.u_delay_mat;
c_steer_mat = opt.c_steer_mat;

[path_num,~]= size(PathP);
it_num      = 0;
while 1
     it_num      = it_num + 1;
%      fprintf('Iteration: %f\n',it_num);
     for path_idx = 1:1:path_num
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%   Expectation
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        noise_est   = Y_rx - sum(wave,3);        
        wave_l      = wave(:,:,path_idx);
        wave_l_exp  = wave_l + noise_est;
        PathP_old   = PathP;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %     Estimate time delay
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        c_steer             = C_steer(:,path_idx);             
        z_time              = c_steer' * wave_l_exp * conj(u_delay_mat); 
        z_time              = (abs(z_time)).^2;
        [~,I_time]          = max(z_time(:));
        delay_opt           = time_scope(1,I_time);    
        u_delay_opt         = ifft(X_tx .* exp(-(1i * 2 * pi * f_n * delay_opt)));
    %         u_delay_opt         = time_delay(X_tx,delay_opt,opt);
%         fprintf('I time is:%d, delay is: %f \n',I_time,delay_opt./10^(-9));


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %     Estimate AoA
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     

        z_aoa       = c_steer_mat' * wave_l_exp .* repmat(conj(u_delay_opt),length(angle_scope),1);
        z_aoa       = sum(z_aoa,2);
        z_aoa       = (abs(z_aoa)).^2;
        [~,I_aoa]   = max(z_aoa(:));
        aoa_opt     = angle_scope(1,I_aoa); 
        c_steer_opt = exp(- array * pi * cos(aoa_opt) *1i);
%         fprintf('I aoa is:%d, aoa is:%f\n',I_aoa,aoa_opt);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %     Estimate Complex Attenuation
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
        z_amp_tmp       = c_steer_opt' * wave_l;
        z_amp_tmp       = z_amp_tmp .* conj(u_delay_opt);
        z_amp           = sum(z_amp_tmp(:));
        amp_opt         = z_amp ./ ( M * pwr);

        U_delay(path_idx,:) = u_delay_opt;
        C_steer(:,path_idx) = c_steer_opt;

        PathP(path_idx,:)   = [delay_opt,aoa_opt,0,amp_opt];

        % update the wave estimate
        wave(:,:,path_idx) = amp_opt * c_steer_opt * u_delay_opt;

     end  
     % Stop the iteration if the condition is satisfied
    [stop,~]   = xDTrack_stop_condition(PathP_old,PathP,opt); 
     if stop || it_num > 60
        break;
     end 
end
end