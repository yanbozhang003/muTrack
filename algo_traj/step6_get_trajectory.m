clear;
close all

load('./get_location_mdTrack/result/0201/Groundtruth.mat')

trace_idx = 1;

test_Device = 3;
% figure('Position',[650 200 535 725])
% plot(Gtruth_D4.x,Gtruth_D4.y,'.','MarkerSize',20,...
%     'MarkerEdgeColor','r');
% xlim([-5.35/2 5.35/2]);ylim([-7.25/2 7.25/2]);
% hold on

load('./get_location_mdTrack/result/0201/ready/trace_new.mat');

loc_vec = trace_cell_new{test_Device,1}.loc_vec_new;
ts_vec = trace_cell_new{test_Device,1}.ts_vec_new;
cluster_seg = trace_cell_new{test_Device,1}.cluster_seg_new;
[~,num_time_cluster] = size(cluster_seg);
tr_label = trace_cell_new{test_Device,1}.tr_label_new;

%% get trajectory: 
%  global dbscan -> get center point for each global cluster
dbscan_sample = loc_vec';
dbscan_idx = dbscan(dbscan_sample,0.2,5); 
dbscan_idx_vec = unique(dbscan_idx);
dbscan_num_cluster = length(unique(dbscan_idx));

loc_cpoint = zeros(2,1);
loc_cpoint_ts = zeros(2,1);
loc_cpoint_macaddr = cell(1,1);
for dbscan_cluster_idx = 1:1:max(dbscan_idx_vec)
    [sample_idx,~] = find(dbscan_idx==dbscan_cluster_idx);
    sample_loc = loc_vec(:,sample_idx);
    sample_ts  = ts_vec(:,sample_idx);
    
    loc_cpoint(:,dbscan_cluster_idx) = mean(sample_loc,2);
    loc_cpoint_ts(:,dbscan_cluster_idx) = mean(sample_ts,2);
    loc_cpoint_macaddr{dbscan_cluster_idx}.macaddr = ...
        mac_cell_new{test_Device,sample_idx(end)}.macaddr;
end

dbscan_num_outlier = length(find(dbscan_idx_vec<0));
if dbscan_num_outlier
    fprintf('%d outliers detected and filtered.\n', dbscan_num_outlier);
end

% % plot dbscan clusters
% gscatter(dbscan_sample(:,1),dbscan_sample(:,2),dbscan_idx);
% title('DBSCAN Using Euclidean Distance Metric')
% % plot final estimated trajectory
% plot(loc_cpoint(1,:),loc_cpoint(2,:),'ro-')

save(['./get_location_mdTrack/result/0201/trajectory/D',num2str(test_Device),...
    '_trace',num2str(trace_idx),'.mat'],'loc_cpoint','loc_cpoint_ts',...
    'loc_cpoint_macaddr');