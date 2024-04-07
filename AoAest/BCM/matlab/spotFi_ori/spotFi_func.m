% clear;

% remove const phase offset
% load('../data/spotFi_20M_2G_tr28.mat');
% load('../data/Calib/spotFi_calib_20M_2G_rx12.mat');
% load('../data/Calib/spotFi_calib_20M_2G_rx13.mat');
% load('../data/calib/spotFi_fastcalib_20M_2G.mat');

function aoaEstimateMatrix = spotFi_func(CSI_amp,CSI_pha,pha_diff_rx12,pha_diff_rx13)

    CSI = CSI_amp.*exp(1i*wrapToPi(CSI_pha));
    [n_rx,n_tx,n_sc] = size(CSI);

    pha_diff = [zeros(1,n_sc);pha_diff_rx12;pha_diff_rx13];
    pha_diff_exp = exp(-1i*pha_diff);

    CSI_tmp = squeeze(CSI(:,1,:));
    CSI_sanit = CSI_tmp.*pha_diff_exp;

    % sample CSI trace is a 90x1 vector where first 30 elements correspond to subcarriers for first rx antenna, second 30 correspond to CSI from next 30 subcarriers and so on.
    % replace sample_csi_trace with CSI from Intel 5300 converted to 90x1 vector
    sample_csi_trace = reshape(CSI_sanit.',[],1);

    fc = 2.437e9; % center frequency
    M = 3;    % number of rx antennas
    fs = 20e6; % channel bandwidth
    c = 3e8;  % speed of light
    %d = 5.55e-2;  % distance between adjacent antennas in the linear antenna array (AP1)
    d = 5.75e-2;  % AP2
%     SubCarrInd = [-58,-54,-50,-46,-42,-38,-34,-30,-26,-22,-18,-14,-10,-6,-2,2,6,10,14,18,22,26,30,34,38,42,46,50,54,58]; % WiFi subcarrier indices at which CSI is available
    SubCarrInd = [-27:-2,2:27];
    N = length(SubCarrInd); % number of subcarriers
    % subCarrSize = 128;  % total number fo
    fgap = 312.5e3; % frequency gap in Hz between successive subcarriers in WiFi
    lambda = c/fc;  % wavelength
    T = 1; % number of transmitter antennas

    % MUSIC algorithm requires estimating MUSIC spectrum in a grid. paramRange captures parameters for this grid
    % For the following example, MUSIC spectrum is caluclated for 101 ToF (Time of flight) values spaced equally between -25 ns and 25 ns. MUSIC spectrum is calculated for for 101 AoA (Angle of Arrival) values between -90 and 90 degrees.
    paramRange = struct;
    paramRange.GridPts = [101 101 1]; % number of grid points in the format [number of grid points for ToF (Time of flight), number of grid points for angle of arrival (AoA), 1]
    paramRange.delayRange = [-50 50]*1e-9; % lowest and highest values to consider for ToF grid. 
    paramRange.angleRange = 90*[-1 1]; % lowest and values to consider for AoA grid.
    do_second_iter = 0;
    % paramRange.seconditerGridPts = [1 51 21 21];
    paramRange.K = floor(M/2)+1; % parameter related to smoothing.  
    paramRange.L = floor(N/2); % parameter related to smoothing.  
    paramRange.T = 1;
    paramRange.deltaRange = [0 0]; 

    maxRapIters = Inf;
    useNoise = 0;
    paramRange.generateAtot = 2;

    % ToF sanitization code (Algorithm 1 in SpotFi paper)
    csi_plot = reshape(sample_csi_trace, N, M);
    [PhsSlope, PhsCons] = removePhsSlope(csi_plot,M,SubCarrInd,N);
    ToMult = exp(1i* (-PhsSlope*repmat(SubCarrInd(:),1,M) - PhsCons*ones(N,M) ));
    csi_plot = csi_plot.*ToMult;
    relChannel_noSlope = reshape(csi_plot, N, M, T);
    sample_csi_trace_sanitized = relChannel_noSlope(:);

    % MUSIC algorithm for estimating angle of arrival
    % aoaEstimateMatrix is (nComps x 5) matrix where nComps is the number of paths in the environment. First column is ToF in ns and second column is AoA in degrees as defined in SpotFi paper
    aoaEstimateMatrix = backscatterEstimationMusic(sample_csi_trace_sanitized, M, N, c, fc,...
                        T, fgap, SubCarrInd, d, paramRange, maxRapIters, useNoise, do_second_iter, ones(2))
    tofEstimate = aoaEstimateMatrix(:,1); % ToF in nanoseconds
    aoaEstomate = aoaEstimateMatrix(:,2); % AoA in degrees
end