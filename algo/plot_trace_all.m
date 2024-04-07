clear;
close all

%% plot groundtruth
load('./get_location_mdTrack/result/0201/Groundtruth.mat')
figure('Position',[650 200 535 725])
plot(Gtruth_D1.x,Gtruth_D1.y,'k--');hold on
plot((Gtruth_D2.x+Gtruth_D3.x)/2,(Gtruth_D2.y+Gtruth_D3.y)/2,'k--');hold on
plot(Gtruth_D4.x,Gtruth_D4.y,'k--');hold on
xlim([-5.35/2 5.35/2]);ylim([-7.25/2 7.25/2]);

%% plot sample
num_trace_collect = [16,12,12,1];
color_collect = {'b','r','g','c','m'};
D_count = 0;
plt_count = 0;
macaddr_ref = 'aa:aa:aa:aa:aa:aa';
for D_idx = 1:1:4
    num_trace = num_trace_collect(D_idx);
    for tr_idx = 1:1:num_trace
        tr_idx
        load(['./get_location_mdTrack/result/0201/modify/D',num2str(D_idx),...
            '_loc_2G_20M_tr',num2str(tr_idx),'.mat']);
        
        num_sample = length(loc_cell);
        for sample_idx = 1:1:num_sample
            plt_count = plt_count+1;
            macaddr = loc_cell{sample_idx}.macaddr;
            if  ~isequal(macaddr, macaddr_ref) || plt_count == 1
                D_count = D_count+1;
            end
            macaddr_ref = macaddr;
            location = loc_cell{sample_idx}.location;

            plot(location(1),location(2),'.','MarkerSize',20,...
                'MarkerEdgeColor',color_collect{D_count});hold on
            xlim([-Wdt/2 Wdt/2]);xlabel('X (m)');
            ylim([-Len/2 Len/2]);ylabel('Y (m)');
            grid on

            drawnow();
        end
    end
end