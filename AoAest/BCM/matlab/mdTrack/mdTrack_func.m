function loc_result = mdTrack_func(CSI_amp,CSI_pha,pha_diff_rx12,pha_diff_rx13)

    addpath('matlab/mdTrack/xDTrack-2D-Time/');

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

    CSI         = CSI_amp.*exp(1i*wrapToPi(CSI_pha));
    [N_rx,num_tones] = size(CSI);

    pha_diff = [zeros(1,num_tones);pha_diff_rx12;pha_diff_rx13];
    pha_diff_exp = exp(-1i*pha_diff);

    CSI_M       = CSI .* pha_diff_exp;

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
end