clear;
close all

load('./get_location_mdTrack/result/0128/Groundtruth.mat')

D = 2;
num_trace = 12;

figure('Position',[650 200 535 725])
for tr_idx = 1:1:num_trace
    tr_idx
    load(['./get_location_mdTrack/result/0128/modify/D',num2str(D),...
        '_loc_2G_20M_tr',num2str(tr_idx),'.mat']);
    
    plot(Gtruth_D3.x,Gtruth_D3.y,'.','MarkerSize',20,...
    'MarkerEdgeColor','r');hold on
    xlim([-5.35/2 5.35/2]);ylim([-7.25/2 7.25/2]);
    
    num_sample = length(loc_cell);
    for sample_idx = 1:1:num_sample
        if sample_idx == 1
            macaddr = loc_cell{sample_idx}.macaddr
        end
        location = loc_cell{sample_idx}.location;
        
        plot(location(1),location(2),'.','MarkerSize',20,...
            'MarkerEdgeColor','b');hold on
        xlim([-Wdt/2 Wdt/2]);
        ylim([-Len/2 Len/2]);
        
        drawnow();
    end
%     hold off
end