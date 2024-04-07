clear;
close all

addpath('./xDTrack-2D-Time');

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%         Parameters of the 802.11 standard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

HTLTF_20            = [1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 0,...
    1 -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, -1, -1, 1, 1, -1, -1, 1, -1, 1, -1, 1, 1, 1, 1, -1, -1];
HTLTF_20_all        = [0, 0, 0, 0, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 0,...
    1 -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, -1, -1, 1, 1, -1, -1, 1, -1, 1, -1, 1, 1, 1, 1, -1, -1, 0, 0, 0,];

half_CSI_idx_lw_20  = 1:1:26;
half_CSI_idx_up_20  = 27:1:52;
occ_sub_20_1_ori    = -27:1:-2;
occ_sub_20_2_ori    = 2:1:27;
occ_sub_20_1        = occ_sub_20_1_ori + 33;
occ_sub_20_2        = occ_sub_20_1_ori + 62;

HTLTF_40        = [1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, ...
    1, -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, -1, -1, 1, 1, -1, -1, 1, -1, 1, -1, 1, 1, 1, 1, -1, -1, -1, 1, 0, ... 
    0, 0, -1, 1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, ... 
    1, -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, -1, -1, 1, 1, -1, -1, 1, -1, 1, -1, 1, 1, 1, 1];

HTLTF_40_all    = [0, 0, 0, 0, 0, 0, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, ...
    1, -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, -1, -1, 1, 1, -1, -1, 1, -1, 1, -1, 1, 1, 1, 1, -1, -1, -1, 1, 0, ... 
    0, 0, -1, 1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, 1, 1, 1, ... 
    1, -1, -1, 1, 1, -1, 1, -1, 1, -1, -1, -1, -1, -1, 1, 1, -1, -1, 1, -1, 1, -1, 1, 1, 1, 1, 0, 0, 0, 0, 0,];

half_CSI_idx_lw_40  = 1:1:57;
half_CSI_idx_up_40  = 58:1:114;
occ_sub_40_1_ori    = -58:1:-2;
occ_sub_40_2_ori    = 2:1:58;
occ_sub_40_1        = occ_sub_40_1_ori + 65;
occ_sub_40_2        = occ_sub_40_2_ori + 65;

HTLTF_20_t      = ifft(HTLTF_20_all);
HTLTF_40_t      = ifft(HTLTF_40_all);

X_tx_t_40       = HTLTF_40_t;
X_tx_40         = HTLTF_40_all;

X_tx_t_20       = HTLTF_20_t;
X_tx_20         = HTLTF_20_all;
x_1     = 0:0.1:6.77;
x_2     = x_1;
y_1     = zeros(1,length(x_1));
y_2     = y_1 + 9.43;

y_3     = 0:0.1:9.43;
y_4     = y_3;
x_3     = zeros(1,length(y_3));
x_4     = x_3 + 6.77;
wall_x  = cat(2,x_1,x_2,x_3,x_4);
wall_y  = cat(2,y_1,y_2,y_3,y_4);

x_1     = 2.63:0.02:4.12;
x_2     = x_1;
y_1     = zeros(1,length(x_1))+3.19;
y_2     = zeros(1,length(x_1)) + 6.7;

y_3     = 3.19:0.02:6.7;
y_4     = y_3;
x_3     = zeros(1,length(y_3))+2.634;
x_4     = zeros(1,length(y_3)) + 4.12;
desk_x  = cat(2,x_1,x_2,x_3,x_4);
desk_y  = cat(2,y_1,y_2,y_3,y_4);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Estimation parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sm          = 1;
step        = 0.01;
theta       = -pi:step:pi;
theta_len   = length(theta);
path        = 4;
mu          = 0;
sigma       = 0.1;

% rx_x        = 3.35;
% rx_y        = 7.20;
rx_x = 3.35;
rx_y = 3.35;

ENV_para    = para_cal(rx_x,rx_y,0.1);
loc_x       = ENV_para.loc_x;
loc_y       = ENV_para.loc_y;
N           = 64;
L           = path;
Pkt_Num     = 100;
car_num     = 56;

M           = 3;
opt20_M3    = xDTrack_system_parameter(X_tx_t_20,L,M,N);

subcarrier_idx          = zeros(1,56);
subcarrier_idx(1,1:28)  = 1:1:28;
subcarrier_idx(1,29:56)  = 30:1:57;

CSI_NUM_V   = 600;  % the number of CSI we will record
csi_num     = 0;    % count the number of csi received
idx1_num    = 0;
idx2_num    = 0;
idx3_num    = 0;

est_num     = 0;
est_flag    = 0;

step        = 0.01;
theta       = -pi:step:pi;
theta_len   = length(theta);

csi_idx_v   = 1:1:CSI_NUM_V;
csi_idx_v   = repmat(csi_idx_v,path,1);

CSI_M_calib_all   = zeros(9,56,CSI_NUM_V);
csi_idx1_all   = zeros(3,56,CSI_NUM_V);
csi_idx2_all   = zeros(3,56,CSI_NUM_V);
csi_idx3_all   = zeros(3,56,CSI_NUM_V);
csi_idx4_all   = zeros(3,56,CSI_NUM_V);
PathP_all      = zeros(path,4,CSI_NUM_V);
tof_vec     = zeros(path,CSI_NUM_V);
aoa_vec     = zeros(path,CSI_NUM_V);
amp_vec     = zeros(path,CSI_NUM_V);

tof_vec1     = zeros(path,CSI_NUM_V);
aoa_vec1     = zeros(path,CSI_NUM_V);
amp_vec1     = zeros(path,CSI_NUM_V);
fig_config = {'k.-','b.-','r.-','g.-','y.-','k*-','b*-','r*-','g*-','y*-'};

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
AP = [2,3,5];
tr = 5;

data_AP1 = load(['../data/0125/dbg_mDtrack_AoA_2G_20M_AP',num2str(AP(1)),'_tr',num2str(tr),'.mat']);
data_AP2 = load(['../data/0125/dbg_mDtrack_AoA_2G_20M_AP',num2str(AP(2)),'_tr',num2str(tr),'.mat']);
data_AP3 = load(['../data/0125/dbg_mDtrack_AoA_2G_20M_AP',num2str(AP(3)),'_tr',num2str(tr),'.mat']);

pha_diff_AP1 = load(['../data/calib/spotFi_fastcalib_20M_2G_AP',num2str(AP(1)),'_tr1.mat']);
pha_diff_AP2 = load(['../data/calib/spotFi_fastcalib_20M_2G_AP',num2str(AP(2)),'_tr1.mat']);
pha_diff_AP3 = load(['../data/calib/spotFi_fastcalib_20M_2G_AP',num2str(AP(3)),'_tr1.mat']);

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

n_rx = 3;
n_sc = 52;
CSI_input = zeros(n_rx,1,n_sc,length(AP));
dbg_sync_pkt_vec = zeros(1,1);
loc_cell = cell(1,1);
aoaVec = zeros(1,1);
for pkt_idx = 1:1:num_pkt
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
        CSI_M       = CSI_tmp .* pha_diff_exp;

        CSI_all                 = zeros(M,64);
        CSI_all(:,occ_sub_20_1) = CSI_M(:,half_CSI_idx_lw_20);
        CSI_all(:,occ_sub_20_2) = CSI_M(:,half_CSI_idx_up_20);
        Y_rx_f                  = repmat(X_tx_20,M,1) .* CSI_all;
        Y_rx_t                  = ifft(Y_rx_f,[],2);
        [PathP,~]           = xDTrack(X_tx_20,Y_rx_t,opt20_M3);
        EST_para_result     = zeros(path,4,1);
        PathP(:,2)          = wrapToPi(PathP(:,2)- pi);
        EST_para_result(:,:,1)  = PathP;

        [loc_result,ANG_PDF_M_LOS] = func_Localizer(EST_para_result,ENV_para,mu,sigma);      
        aoaVec(pkt_idx,k) = -(rad2deg(atan2(loc_result(2)-3.35,loc_result(1)-3.35))+90);
    end
end
% save(['AoA_tr',num2str(tr),'.mat'],'aoaVec','loc_coord_cell');

%%
% aoaVec = movmedian(aoaVec,5,1);


loc_vec = zeros(1,2); %(sample,(x,y))
dif_coord_real_vec = zeros(1,1);
figure('Position',[650 200 Wdt*100 Len*100])
for idx = 1:1:length(aoaVec)
    idx
    for coord_idx = 1:1:length(loc_coord_cell)
        coord_aoa = loc_coord_cell{coord_idx}.polar;
        dif_coord_real = aoaVec(idx,:)-coord_aoa;
        dif_coord_real_vec(coord_idx,1) = dif_coord_real * dif_coord_real';
    end
    [~,I] = min(dif_coord_real_vec);
    loc_vec(idx,:) = loc_coord_cell{I}.cartesian;
    
    plot(loc_vec(idx,1),loc_vec(idx,2),'*'); hold on
    xlim([-Wdt/2 Wdt/2]);
    ylim([-Len/2 Len/2]);
    
    waitforbuttonpress();
end

