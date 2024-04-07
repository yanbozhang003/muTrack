clear;
close all

% rx2 = 3;
% rx1rx2_data = load(['./data/Calib/spotFi_calib_20M_2G_R1R',num2str(rx2),'_AP1_tr1.mat']);
% rx2rx1_data = load(['./data/Calib/spotFi_calib_20M_2G_R',num2str(rx2),'R1_AP1_tr1.mat']);

rx1rx2_data = load('./data/calib/spotFi_fastcalib_20M_2G_R1R2_AP2_tr1.mat');
rx2rx1_data = load('./data/calib/spotFi_fastcalib_20M_2G_R1R3_AP2_tr1.mat');

CSI_12 = rx1rx2_data.CSI_cell;
CSI_21 = rx2rx1_data.CSI_cell;

n_pkt12 = length(CSI_12);
n_pkt21 = length(CSI_21);

[n_rx,n_tx,n_sc] = size(CSI_12{1}.CSI);

pkt_v = [n_pkt12 n_pkt21];
n_pkt = 3000;
pha_diff_12_vec = zeros(n_sc,1);
pha_diff_21_vec = zeros(n_sc,1);
for pkt_idx = 1:1:n_pkt
    pkt_idx
    
    CSI_12_pha = angle(squeeze(CSI_12{pkt_idx}.CSI(:,1,:)));
    CSI_21_pha = angle(squeeze(CSI_21{pkt_idx}.CSI(:,1,:)));
    
    pha_diff_12 = angle(exp(1i*CSI_12_pha(2,:))./exp(1i*CSI_12_pha(1,:)));
    pha_diff_21 = angle(exp(1i*CSI_21_pha(3,:))./exp(1i*CSI_21_pha(1,:)));
    
    pha_diff_12_vec(:,pkt_idx) = pha_diff_12;
    pha_diff_21_vec(:,pkt_idx) = pha_diff_21;
    
%     plot(pha_diff_12,'k.-');hold on
%     plot(pha_diff_21,'r.-');hold on
%     ylim([-pi pi]); 
% %     waitforbuttonpress;
%     drawnow();
end
% pha_diff_12_v_mean = mean(mean(pha_diff_12_vec(26:27,:),1));
% pha_diff_21_v_mean = mean(mean(pha_diff_21_vec(26:27,:),1));
pha_diff_12_v_mean = median(pha_diff_12_vec(26,:));
pha_diff_21_v_mean = median(pha_diff_21_vec(26,:));

% pha_diff = wrapToPi((wrapTo2Pi(pha_diff_12_v_mean)+wrapTo2Pi(pha_diff_21_v_mean))/2);
pha_diff_rx12 = repmat(pha_diff_12_v_mean,1,n_sc);
pha_diff_rx13 = repmat(pha_diff_21_v_mean,1,n_sc);

plot(pha_diff_12_vec(:,1:10:3000),'r.-');hold on
plot(pha_diff_21_vec(:,1:10:3000),'k.-');hold on
plot(pha_diff_rx12,'k.-');hold on
plot(pha_diff_rx13,'r.-');hold on
ylim([-pi pi]);

save('./data/calib/spotFi_fastcalib_20M_2G_AP2_tr1.mat','pha_diff_rx12','pha_diff_rx13');
