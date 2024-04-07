function opt = xDTrack_system_parameter(X_tx_t,L,M,N)
%%% this function is to set the system parameters for estimation 
%%% Inputs:
%%% X_tx_t: transmitted preamble in time domain
%%% L:      the number of multipaths
%%% M:      the number of receiving antennas
%%% N:      the FFT size (default is 64)
%%% Output:
%%% opt:    the struct that contains all the parameters

opt.lamda       = 5.6;             % wave length
% opt.ant_dis     = 2.8;             % distance between 2 antennas
opt.ant_dis     = 5.6;             % distance between 2 antennas
opt.M           = double(M);                % antenna/sensor number
opt.L           = double(L);                % number of multipath
opt.N           = double(N);                % FFT size

%% parameters for 802.11 OFDM symbol
opt.t_sym       = 3.2 * 10^(-6);                    % OFDM symbol length (s)
opt.t_cp        = 1.8 * 10^(-6);                    % OFDM cyclic-prefix length (s)
t_step          = 0:1:opt.N-1;                      % vector for time or frequency bins
opt.f_n         = (t_step) ./ opt.t_sym;            % frequencies of subcarriers
opt.t_step      = t_step .* (opt.t_sym / opt.N);    % time step in one OFDM symbol

%% the channel is divided into two bands (lower and upper half), blow are some statics about it
opt.N_s         = 26;                               % number of points in half band
opt.s_lower     = 2:1:27;                           % index of lower half 
opt.s_upper     = 39:1:64;                          % index of upper half
opt.t_sample    = 0.01; 
opt.f_n_lower   = opt.f_n(1,opt.s_lower);           % frequencies of lower half
opt.f_n_upper   = opt.f_n(1,opt.s_upper);           % frequencies of upper half

%% search steps and search interval for time domain 
opt.delay_step  = 0.2 * 10^(-9);                      % search step for time delay
opt.delay_min   = -50 * 10^(-9);                    % min time delay value to search
opt.delay_max   = 150 * 10^(-9);                      % max time delay value to search
% opt.time_scope  = opt.delay_min:opt.delay_step:opt.delay_max;   
opt.time_scope  = opt.delay_min:opt.delay_step:opt.delay_max;   
%% search steps and search interval for spatial domain
opt.angle_step  = 0.01;                             % search step for AoA
opt.angle_scope = double(0:opt.angle_step:pi);              % angle (radian) [0,pi]  
 
%% array vector
array           = 0:1:(opt.M-1);
opt.array       = double(array');                           % array vector

%% signal power of the transmitted preamble
opt.pwr         = double(func_pwr(X_tx_t));          % transmitted signal power

%% pre-calculated matrix for estimation
X_tx            = fft(X_tx_t);
opt.delay_vec_f = exp(-(1i * 2 * pi* opt.f_n' * opt.time_scope));   % delay vector matrix in frequency domain
opt.X_tx_d_mat  = repmat(X_tx',1,length(opt.time_scope)) .* opt.delay_vec_f;
opt.u_delay_mat = ifft(opt.X_tx_d_mat,[],1);

opt.c_steer_mat = exp(- opt.array * pi * cos(opt.angle_scope) *1i); % steer vector matrix 
end