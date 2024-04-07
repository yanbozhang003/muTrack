function [PathP,wave,C_steer,U_delay,path_num] = xDTrack_init(X_tx,Y_rx,opt) 
M           = opt.M;        % antenna/sensor number
L           = opt.L;        % number of multipath 
pwr         = opt.pwr;      % transmitted signal power 
array       = opt.array;
N           = opt.N;        % FFT size 
f_n         = opt.f_n;      % frequency bins

% search step for each dimension
time_scope  = opt.time_scope;
angle_scope = opt.angle_scope;

%%%%%%%%%%%%%%%%%%%% channel parameter %%%%%%%%%%%%%%%%%%%%
% 1, time delay        2, AoA
% 3, doppler shift     4, amplitude attentuation 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PathP   = zeros(L,4);

% the L wave we received at the rx array
wave    = zeros(M,N,L);
C_steer = zeros(M,L);
U_delay = zeros(L,N);

delay_vec_f             = exp(-(1i * 2 * pi* f_n' * time_scope));
X_tx_d_mat              = repmat(X_tx',1,length(time_scope)) .* delay_vec_f;
u_delay_mat             = ifft(X_tx_d_mat,[],1);

%% initialization
for path_idx = 1:1:L
%     fprintf('we are init %d path\n',path_idx);  
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%   Estimate the wave of lth path
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    wave_l      = Y_rx - sum(wave,3);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     Estimate time delay
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % estimate the time delay of this path   
 
    z_time                  = wave_l * conj(u_delay_mat);
    z_time                  = (abs(z_time)).^2;
    z_time                  = sum(z_time);
    [~,I_time]              = max(z_time(:));
    delay_opt               = time_scope(1,I_time);
    u_delay_opt             = ifft(X_tx .* exp(-(1i * 2 * pi * f_n * delay_opt)));
    
%     fprintf('I time is:%d, delay is: %f \n',I_time,delay_opt./10^(-9));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     Estimate AoA
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % update the AoA estimation
    c_steer_mat         = exp(- array * pi * cos(angle_scope) *1i); 
    z_aoa               = c_steer_mat' * wave_l .* repmat(conj(u_delay_opt),length(angle_scope),1);
    z_aoa               = sum(z_aoa,2);
    z_aoa               = (abs(z_aoa)).^2;
    [~,I_aoa]           = max(z_aoa(:));
    aoa_opt             = angle_scope(1,I_aoa); 
    c_steer_opt         = exp(- array * pi * cos(aoa_opt) *1i);
%     fprintf('I aoa is:%d, aoa is:%f\n',I_aoa,aoa_opt);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %     Estimate Complex Attenuation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    % update the amplitude 
      
    z_amp_tmp       = c_steer_opt' * wave_l;
    z_amp_tmp       = z_amp_tmp .* conj(u_delay_opt);
    z_amp           = sum(z_amp_tmp(:));
    
    amp_opt         = z_amp ./ ( M * pwr);

    wave(:,:,path_idx)  = amp_opt * c_steer_opt * u_delay_opt;
    C_steer(:,path_idx) = c_steer_opt;
    U_delay(path_idx,:) = u_delay_opt;
    
    
    PathP(path_idx,:)   = [delay_opt,aoa_opt,0,amp_opt];
    path_num            = L;
end
