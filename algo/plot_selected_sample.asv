clear;
close all

load('./get_location_mdTrack/result/0201/ready/trace_new.mat');

test_Device = 2;

loc_vec = trace_cell_new{test_Device,1}.loc_vec_new;
ts_vec = trace_cell_new{test_Device,1}.ts_vec_new;
cluster_seg = trace_cell_new{test_Device,1}.cluster_seg_new;
[~,num_time_cluster] = size(cluster_seg);
tr_label = trace_cell_new{test_Device,1}.tr_label_new;

load('./get_location_mdTrack/result/0201/Groundtruth.mat')

figure('Position',[650 200 535 725])
for t_cluster_idx = 1:1:num_time_cluster
    t_cluster_idx
    idx_head = cluster_seg(1,t_cluster_idx);
    idx_tail = cluster_seg(2,t_cluster_idx);
    
    idx_tail-idx_head+1
    tr_idx = tr_label(idx_head)

    plot(Gtruth_D2.x(tr_idx),Gtruth_D2.y(tr_idx),'.','MarkerSize',20,...
    'MarkerEdgeColor','r');hold on
    
    plot(loc_vec(1,idx_head:idx_tail),loc_vec(2,idx_head:idx_tail),'.',...
        'MarkerSize',20,'MarkerEdgeColor','b');
    xlim([-5.35/2 5.35/2]);ylim([-7.25/2 7.25/2]);
    hold off
    
    waitforbuttonpress();
end


