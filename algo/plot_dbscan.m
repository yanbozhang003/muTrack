clear;
close all

load('./get_location_mdTrack/result/0128/ready/trace.mat');

test_Device = 2;

loc_vec = trace_cell{test_Device,1}.loc_vec;
ts_vec = trace_cell{test_Device,1}.ts_vec;

%% study cluster
ts_r = ts_vec - ts_vec(:,1);
ts_r_s = (ts_r(1,:)*10e6+ts_r(2,:))/10e6;
% plot(ts_r_s,'.');

ts_r_s_diff = diff(ts_r_s);
% plot(ts_r_s_diff,'k.-')

THRSLD = 0.5;
[~,cluster_tail] = find(ts_r_s_diff>THRSLD);
cluster_head = cluster_tail + 1;
cluster_head = [1 cluster_head];
cluster_tail = [cluster_tail length(ts_vec)];
cluster_seg  = [cluster_head;cluster_tail];

% observation 1: the time range of each cluster is less than coherence time
[~,num_time_cluster] = size(cluster_seg);
cluster_range_vec = zeros(1,1);
% distr_range = 0:1/1000:0.1;
% distr_vec = zeros(100,1);
for t_cluster_idx = 1:1:num_time_cluster
    time_head = ts_r_s(cluster_seg(1,t_cluster_idx));
    time_tail = ts_r_s(cluster_seg(2,t_cluster_idx));
    
    time_range = time_tail - time_head;
    cluster_range_vec(t_cluster_idx) = time_range;
    
%     % get distribution
%     [~,t1] = find(distr_range<=time_range);
%     distr_vec(t1(end)) = distr_vec(t1(end))+1;
end
[f,x] = ecdf(cluster_range_vec);
% plot(x,f,'k.-')

% observation 2: different time clusters are clearly separated (inter-distance >> intra-distance)
intra_dist_vec = ts_r_s_diff(ts_r_s_diff<THRSLD);
inter_dist_vec = ts_r_s_diff(ts_r_s_diff>=THRSLD);
[f_intra,x_intra] = ecdf(intra_dist_vec);
[f_inter,x_inter] = ecdf(inter_dist_vec);
% plot(x_intra,f_intra,'k.-');hold on
% plot(x_inter,f_inter,'b.-');hold off

%% remove noise samples
%  step 1: apply dbscan for inner-clustering
%  step 2: select nearest cluster (use euc-distance of center points)
load('./get_location_mdTrack/result/0128/Groundtruth.mat')

cluster_seg_select = zeros(2,1);
cluster_count = 0;

tr_seg = trace_cell{test_Device,1}.tr_idx;
figure('Position',[650 200 535 725])
for t_cluster_idx = 1:1:num_time_cluster
    idx_head = cluster_seg(1,t_cluster_idx);
    idx_tail = cluster_seg(2,t_cluster_idx);
    
    num_sample = idx_tail-idx_head+1;
    sample_loc = loc_vec(:,idx_head:idx_tail)';
    
    % apply dbscan (esp=0.5,minPts=2)
    dbscan_idx = dbscan(sample_loc,0.3,2); 
    
%     dbscan_idx_vec = unique(dbscan_idx);
%     dbscan_num_cluster = length(unique(dbscan_idx));
%     
%     if dbscan_num_cluster == 1 || t_cluster_idx == 1
%         cluster_count = cluster_count + 1;
%         cluster_seg_select(:,cluster_count) = cluster_seg(:,t_cluster_idx);
%     else
%         % get center point of each inner-cluster
%         cPts_vec = zeros(dbscan_num_cluster,2);
%         for InnerC_idx = 1:1:dbscan_num_cluster
%             loc_tmp_idx = find(dbscan_idx==dbscan_idx_vec(InnerC_idx));
%             loc_tmp = sample_loc(loc_tmp_idx,:);
%             cPts_vec(InnerC_idx,:) = mean(loc_tmp,1);
%         end
%         % take out the previous cluster location samples and get the center
%         % point
%         cluster_prev_seg_tmp = cluster_seg_select(:,cluster_count);
%         loc_samples_prev_tmp = loc_vec(:,cluster_prev_seg_tmp(1):cluster_prev_seg_tmp(2));
%         cPts_prev = mean(loc_samples_prev_tmp,2)';
%         % compute the euc-distance
%         euclDist_vec = sqrt(sum((cPts_vec - cPts_prev).^2,2));
%         % get the nearest inner-cluster
%         [~,I] = min(euclDist_vec);
%         
%         % update cluster_seg_select
%         innerC_seg = find(dbscan_idx == dbscan_idx_vec(I));
%         cluster_count = cluster_count + 1;
%     end
    
    % plot
    [~,tr_col] = find(tr_seg(1,:)<=idx_head);
    tr_idx = tr_col(end)
    plot(Gtruth_D2.x,Gtruth_D2.y,'.','MarkerSize',20,...
    'MarkerEdgeColor','b');hold on
%     plot(loc_vec(1,idx_head:idx_tail),loc_vec(2,idx_head:idx_tail),'.',...
%         'MarkerSize',20,'MarkerEdgeColor','b');
    gscatter(sample_loc(:,1),sample_loc(:,2),dbscan_idx);
    xlim([-5.35/2 5.35/2]);ylim([-7.25/2 7.25/2]);
    hold on
    waitforbuttonpress();
end


