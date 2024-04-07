clear;
close all

num_trace_collect = [16,12,12,1];
trace_cell = cell(4,1);
mac_cell = cell(4,1);

% struct timestamp 
for D_idx = 1:1:4
    num_trace = num_trace_collect(D_idx);
    trace_cell{D_idx}.ts_vec = zeros(2,1);                %((sec,usec),sample)
    trace_cell{D_idx}.loc_vec = zeros(2,1);               %((x,y),sample)
    trace_cell{D_idx}.tr_idx = zeros(2,1);                %((head,tail),trace)
    ts_count = 0;
    for tr_idx = 1:1:num_trace
        load(['./get_location_mdTrack/result/0201/modify/D',num2str(D_idx),...
            '_loc_2G_20M_tr',num2str(tr_idx),'.mat']);
        
        num_sample = length(loc_cell);
        for sample_idx = 1:1:num_sample
            ts_sec_tmp = loc_cell{sample_idx,1}.tstamp.ts_sec;
            ts_usec_tmp = loc_cell{sample_idx,1}.tstamp.ts_usec;
            ts_count = ts_count+1;
            
            % remove the interval between traces      
            if tr_idx >= 2
                if sample_idx == 1
                    ts_sec_first = ts_sec_tmp;
                    ts_sec_interval = ts_sec_first - ts_sec_last;
                end
                ts_sec_tmp = ts_sec_tmp - ts_sec_interval + 2.5;
            end
            if sample_idx == num_sample
                ts_sec_last = ts_sec_tmp;
            end
                
            trace_cell{D_idx,1}.ts_vec(1,ts_count) = ts_sec_tmp;
            trace_cell{D_idx,1}.ts_vec(2,ts_count) = ts_usec_tmp;
            
            trace_cell{D_idx,1}.loc_vec(:,ts_count) = loc_cell{sample_idx,1}.location;
            
            % label each trace
            if sample_idx == 1
                trace_cell{D_idx,1}.tr_idx(1,tr_idx) = ts_count;
            end
            if sample_idx == num_sample
                trace_cell{D_idx,1}.tr_idx(2,tr_idx) = ts_count;
            end
            
            mac_cell{D_idx,ts_count}.macaddr = loc_cell{sample_idx,1}.macaddr;
        end
%         ts_D1 = ts_cell{D_idx,1}.ts_vec;
%         ts_D1_r = ts_D1 - ts_D1(:,1);
%         ts_D1_r_s = (ts_D1_r(1,:)*10e6+ts_D1_r(2,:))/10e6;
%         
%         plot(ts_D1_r_s,'.');
%         waitforbuttonpress();
    end
end
save('./get_location_mdTrack/result/0201/ready/trace.mat','trace_cell','mac_cell');

% plot timestamp
test_Device = 1;

ts_D1 = trace_cell{test_Device,1}.ts_vec;
ts_D1_r = ts_D1 - ts_D1(:,1);
ts_D1_r_s = (ts_D1_r(1,:)*10e6+ts_D1_r(2,:))/10e6;

plot(ts_D1_r_s,'.')


