clear;
close all

AP = [2,3,5];
tr = 12;

n_rx = 3;
n_sc = 52;

fc = 2.437e9;
M = 3;
fs = 20e6;
c = 3e8;
d = 5.75e-2;
SubCarrInd = [-27:-2,2:27];
N = length(SubCarrInd);
fgap = 312.5e3;
lambda = c/fc;
T = 1; % number of transmitter antennas

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

%% prepare locations
Len = 7.25;        % length: 7.25m
Wdt = 5.35;        % width: 5.35m
num_grid = 100/3; % resolution: 1cm
x_axis = (-Wdt/2+1/num_grid):1/num_grid:(Wdt/2-1/num_grid);
y_axis = (-Len/2+1/num_grid):1/num_grid:(Len/2-1/num_grid);

AP2_loc = [2.5, 3];
AP3_loc = [-2.5, 3];
AP5_loc = [0,0];

loc_coord_cell = cell(1,1);
loc_cnt = 0;
for x_idx = 1:1:length(x_axis)
    for y_idx = 1:1:length(y_axis)
        loc_cnt = loc_cnt + 1;
        loc_coord_cell{loc_cnt,1}.cartesian = [x_axis(x_idx),y_axis(y_idx)];
        
        theta_AP2 = rad2deg(atan(-y_axis(y_idx)/(Wdt/2-x_axis(x_idx))));
        theta_AP3 = rad2deg(atan(y_axis(y_idx)/(Wdt/2+x_axis(x_idx))));
        theta_AP5 = rad2deg(atan(-x_axis(x_idx)/(y_axis(y_idx)+Len/2)));
        
        loc_coord_cell{loc_cnt,1}.polar = [theta_AP2,theta_AP3,theta_AP5];
    end
end

%% packet sync
data_AP1 = load(['../data/dbg_mDtrack_AoA_2G_20M_AP',num2str(AP(1)),'_tr',num2str(tr),'.mat']);
data_AP2 = load(['../data/dbg_mDtrack_AoA_2G_20M_AP',num2str(AP(2)),'_tr',num2str(tr),'.mat']);
data_AP3 = load(['../data/dbg_mDtrack_AoA_2G_20M_AP',num2str(AP(3)),'_tr',num2str(tr),'.mat']);

pha_diff_AP1 = load(['../data/calib/spotFi_fastcalib_20M_2G_AP',num2str(AP(1)),'_tr5.mat']);
pha_diff_AP2 = load(['../data/calib/spotFi_fastcalib_20M_2G_AP',num2str(AP(2)),'_tr5.mat']);
pha_diff_AP3 = load(['../data/calib/spotFi_fastcalib_20M_2G_AP',num2str(AP(3)),'_tr5.mat']);

data = {data_AP1;data_AP2;data_AP3};
pha_diff_cell = {pha_diff_AP1;pha_diff_AP2;pha_diff_AP3};

num_pkt_AP1 = length(data_AP1.CSI_cell);
num_pkt_AP2 = length(data_AP2.CSI_cell);
num_pkt_AP3 = length(data_AP3.CSI_cell); 

[num_pkt,ts_ref_AP_idx] = min([num_pkt_AP1,num_pkt_AP2,num_pkt_AP3]);
AP_idx = 1:1:length(AP);
AP_idx(AP_idx==ts_ref_AP_idx) = [];

ts_cell = cell(length(AP),1);
for idx = 1:1:length(AP)
    ts_cell{idx}.ts_vec = zeros(length(data{idx}.CSI_cell),1);
    for pkt_idx = 1:1:length(data{idx}.CSI_cell)
        ts_cell{idx}.ts_vec(pkt_idx) = (data{idx}.CSI_cell{pkt_idx}.tstamp.Unix.ts_sec-...
                                        data{idx}.CSI_cell{pkt_idx}.tstamp.year*31540000-...
                                        data{idx}.CSI_cell{pkt_idx}.tstamp.month*2628000-...
                                        data{idx}.CSI_cell{pkt_idx}.tstamp.day*86400)*10e3+...
                                        data{idx}.CSI_cell{pkt_idx}.tstamp.Unix.ts_usec/10e3;
    end
end

CSI_input = zeros(n_rx,1,n_sc,length(AP));
dbg_sync_pkt_vec = zeros(1,1);
loc_cell = cell(1,1);
aoa_vec = zeros(1,1);
for pkt_idx = 1:1:num_pkt
    pkt_idx
    CSI_input(:,:,:,ts_ref_AP_idx) = data{ts_ref_AP_idx}.CSI_cell{pkt_idx}.CSI;
    ts_ref = ts_cell{ts_ref_AP_idx}.ts_vec(pkt_idx);
    musicSpec_AP = zeros(101,1);
    
    for i = 1:1:length(AP_idx)
        ts_sync = ts_cell{AP_idx(i)}.ts_vec;
        [~,sync_pkt_idx] = min(abs(ts_sync-ts_ref));
        CSI_input(:,:,:,AP_idx(i)) = data{AP_idx(i)}.CSI_cell{sync_pkt_idx}.CSI;
        dbg_sync_pkt_vec(i,pkt_idx) = sync_pkt_idx;
    end
    
    for k = 1:1:length(AP)
        pha_diff_rx12 = pha_diff_cell{k}.pha_diff_rx12;
        pha_diff_rx13 = pha_diff_cell{k}.pha_diff_rx13;
        pha_diff = [zeros(1,n_sc);pha_diff_rx12;pha_diff_rx13];
        pha_diff_exp = exp(-1i*pha_diff);
        
        CSI = CSI_input(:,:,:,k);
        CSI_tmp = squeeze(CSI(:,1,:));
        CSI_sanit = CSI_tmp.*pha_diff_exp;
        
        sample_csi_trace = reshape(CSI_sanit.',[],1);

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
        
        [~,I] = min(tofEstimate);
        aoa_vec(pkt_idx,k) = aoaEstomate(I);   
        musicSpec_AP(:,k) = mean(musicSpec,1);
    end
    
%     try_AoA_spotFi = -90:180/10:90;
%     loc_possibility = zeros(length(loc_coord_cell),1);
%     for try_loc_idx = 1:1:length(loc_coord_cell)
%         try_polar = loc_coord_cell{try_loc_idx}.polar;
%         
%         [~,try_AP1_AoA] = min(abs(try_AoA_spotFi-try_polar(1)));
%         [~,try_AP2_AoA] = min(abs(try_AoA_spotFi-try_polar(2)));
%         [~,try_AP3_AoA] = min(abs(try_AoA_spotFi-try_polar(3)));
%         
%         loc_possibility(try_loc_idx) = musicSpec_AP(try_AP1_AoA,1)*...
%             musicSpec_AP(try_AP2_AoA,2)*musicSpec_AP(try_AP3_AoA,3);
%     end
%     
%     [~,location_idx] = max(loc_possibility);
%     loc_cell{pkt_idx,1}.loc = loc_coord_cell{location_idx}.cartesian;
%     loc_cell{pkt_idx,1}.time = data{ts_ref_AP_idx}.CSI_cell{pkt_idx}.tstamp;
%     
%     plot(loc_cell{pkt_idx,1}.loc(1),loc_cell{pkt_idx,1}.loc(2),'*');hold on
%     xlim([-Wdt/2 Wdt/2]);
%     ylim([-Len/2 Len/2]);
%     drawnow();
end

% subplot(1,3,1)
% plot(movmedian(aoa_vec(:,1),100),'k.-');
% subplot(1,3,2)
% plot(movmedian(aoa_vec(:,2),100),'k.-');
% subplot(1,3,3)
% plot(movmedian(aoa_vec(:,3),100),'k.-');

save(['AoA_tr',num2str(tr),'.mat'],'aoa_vec','loc_coord_cell');
%%
% load('AoA_tr2.mat');
% aoa_vec = movmedian(aoa_vec,5,1);

loc_vec = zeros(1,2); %(sample,(x,y))
dif_coord_real_vec = zeros(1,1);
for idx = 1:1:length(aoa_vec)
    idx
    for coord_idx = 1:1:length(loc_coord_cell)
        coord_aoa = loc_coord_cell{coord_idx}.polar;
        dif_coord_real = aoa_vec(idx,:)-coord_aoa;
        dif_coord_real_vec(coord_idx,1) = dif_coord_real * dif_coord_real';
    end
    [~,I] = min(dif_coord_real_vec);
    loc_vec(idx,:) = loc_coord_cell{I}.cartesian;
    
    plot(loc_vec(idx,1),loc_vec(idx,2),'*'); hold on
    xlim([-Wdt/2 Wdt/2]);
    ylim([-Len/2 Len/2]);
    
    waitforbuttonpress();
end

%%
% load('AoA_tr6.mat');
% % aoa_vec = movmedian(aoa_vec,100,1);
% 
% AP_inuse = [2,3];
% 
% loc_vec = zeros(1,2);
% for idx = 1:1:length(aoa_vec)
%     aoa1 = aoa_vec(idx,AP_inuse(1));
%     aoa2 = aoa_vec(idx,AP_inuse(2));
%     
%     y = tan(deg2rad(aoa1))*(Wdt-Len*tan(deg2rad(aoa2))*tan(deg2rad(aoa1)))/...
%         (2*(tan(deg2rad(aoa1))*tan(deg2rad(aoa2))+1));
%     x = -Len*deg2rad(aoa2)/2-y*tan(deg2rad(aoa2));
%     
%     loc_vec(idx,1) = x;
%     loc_vec(idx,2) = y;
%     
%     plot(loc_vec(idx,1),loc_vec(idx,2),'*'); hold on
%     xlim([-Wdt/2 Wdt/2]);
%     ylim([-Len/2 Len/2]);
%     
%     waitforbuttonpress();
% end



