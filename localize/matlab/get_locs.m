clear;
close all

% AP2_data = load('./result/AoA_AP2_tr1.mat');
AP3_data = load('./data/2G_20M_CH6_AP3_tr1.mat');
AP5_data = load('./data/2G_20M_CH6_AP5_tr1.mat');

% aoaPlt = movmedian(aoa_vec,100);
% plot(aoaPlt,'k.-');

AP2_time = AP2_data.time_cell;
AP3_time = AP3_data.time_cell;
AP5_time = AP5_data.time_cell;

n_pkt = min([length(AP2_time),length(AP3_time),length(AP5_time)]);

ts_diff_23 = zeros(1,1);
ts_diff_25 = zeros(1,1);
for pkt_idx = 1:1:n_pkt
    ts_diff_23(pkt_idx) = AP3_time{pkt_idx}.Unix.ts_sec - AP2_time{pkt_idx}.Unix.ts_sec;
    ts_diff_25(pkt_idx) = AP5_time{pkt_idx}.Unix.ts_sec - AP2_time{pkt_idx}.Unix.ts_sec;
end

plot(ts_diff_23,'k.-');hold on
plot(ts_diff_25,'r.-');