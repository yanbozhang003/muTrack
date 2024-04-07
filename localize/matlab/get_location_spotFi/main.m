clear;

AP = 3;
tr = 1;

% remove const phase offset
load(['../data/spotFi_AP',num2str(AP),'_tr',num2str(tr),'.mat']);
% load('../data/Calib/spotFi_calib_20M_2G_rx12.mat');
% load('../data/Calib/spotFi_calib_20M_2G_rx13.mat');
load(['../data/calib/spotFi_fastcalib_20M_2G_AP',num2str(AP),'_tr1.mat']);

n_rx = 3;
n_sc = 52;
n_pkt = length(CSI_cell);

pha_diff = [zeros(1,n_sc);pha_diff_rx12;pha_diff_rx13];
pha_diff_exp = exp(-1i*pha_diff);

aoa_vec = zeros(1,1);
macADDR_cell = cell(1,1);
time_cell = cell(1,1);
for pkt_idx = 1:1:n_pkt
    pkt_idx
    CSI = CSI_cell{pkt_idx,1}.CSI;
    macADDR = CSI_cell{pkt_idx,1}.macADDR;
    time = CSI_cell{pkt_idx,1}.tstamp;
    
    macADDR_cell{pkt_idx,1} = macADDR;
    time_cell{pkt_idx,1} = time;
    
    CSI_tmp = squeeze(CSI(:,1,:));
    CSI_sanit = CSI_tmp.*pha_diff_exp;
    
%     sanit_pha = angle(CSI_sanit);
%     sanit_pha_rx1 = unwrap(sanit_pha(1,:));
%     sanit_pha_rx2 = unwrap(sanit_pha(2,:));
%     sanit_pha_rx3 = unwrap(sanit_pha(3,:));
%     
%     p_rx1 = polyfit(1:n_sc,sanit_pha_rx1,1);
%     p_rx2 = polyfit(1:n_sc,sanit_pha_rx2,1);
%     p_rx3 = polyfit(1:n_sc,sanit_pha_rx3,1);
%     
%     p_rx12 = abs(p_rx1(1)-p_rx2(1))
%     p_rx13 = abs(p_rx1(1)-p_rx3(1))
%     sanit_pha_rx2 = sanit_pha_rx2 + [1:n_sc] .* (p_rx1(1)-p_rx2(1));
%     sanit_pha_rx3 = sanit_pha_rx3 + [1:n_sc] .* (p_rx1(1)-p_rx3(1));
%     
%     sanit_pha = [wrapToPi(sanit_pha_rx1);wrapToPi(sanit_pha_rx2);wrapToPi(sanit_pha_rx3)];
%     
%     CSI_sanit = abs(CSI_sanit) .* exp(1i*sanit_pha);
%     
%     CSI_sanit_amp = abs(CSI_sanit);
%     subplot(2,3,1)
%     plot(CSI_sanit_amp(1,:),'k.-');hold on
%     subplot(2,3,2)
%     plot(CSI_sanit_amp(2,:),'r.-');hold on
%     subplot(2,3,3)
%     plot(CSI_sanit_amp(3,:),'b.-');hold on
%     
%     pha_diff_11 = angle(CSI_sanit(1,:)./CSI_sanit(1,:));
%     pha_diff_21 = angle(CSI_sanit(2,:)./CSI_sanit(1,:));
%     pha_diff_31 = angle(CSI_sanit(3,:)./CSI_sanit(1,:));
%     CSI_sanit_pha = angle(CSI_sanit);
%     subplot(2,3,4)
% %     plot(pha_diff_11,'k.-');hold on
%     plot(unwrap(CSI_sanit_pha(1,:)),'k.-');hold on
% %     ylim([-pi pi])
%     subplot(2,3,5)
%     plot(unwrap(CSI_sanit_pha(2,:)),'r.-');hold on
% %     ylim([-pi pi])
%     subplot(2,3,6)
%     plot(unwrap(CSI_sanit_pha(3,:)),'b.-');hold on
% %     ylim([-pi pi])
    
    % sample CSI trace is a 90x1 vector where first 30 elements correspond to subcarriers for first rx antenna, second 30 correspond to CSI from next 30 subcarriers and so on.
    % replace sample_csi_trace with CSI from Intel 5300 converted to 90x1 vector
    sample_csi_trace = reshape(CSI_sanit.',[],1);

    fc = 2.437e9; % center frequency
    M = 3;    % number of rx antennas
    fs = 20e6; % channel bandwidth
    c = 3e8;  % speed of light
    d = 5.75e-2;  % distance between adjacent antennas in the linear antenna array
    % dTx = 2.6e-2; 
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
    [aoaEstimateMatrix,musicSpec] = backscatterEstimationMusic(sample_csi_trace_sanitized, M, N, c, fc,...
                        T, fgap, SubCarrInd, d, paramRange, maxRapIters, useNoise, do_second_iter, ones(2));
    tofEstimate = aoaEstimateMatrix(:,1); % ToF in nanoseconds
    aoaEstomate = aoaEstimateMatrix(:,2); % AoA in degrees

%     waitforbuttonpress();
    [~,I] = min(tofEstimate);
    aoa_vec(pkt_idx,1) = aoaEstomate(I);    
    
    musicSpec = mean(musicSpec,1);
    bar(musicSpec);
    waitforbuttonpress();
end

% save(['../result/AoA_AP',num2str(AP),'_tr',num2str(tr),'.mat'],'aoa_vec','macADDR_cell','time_cell');
%%

aoaPlt = movmedian(aoa_vec,100);
plot(aoaPlt,'k.-');
