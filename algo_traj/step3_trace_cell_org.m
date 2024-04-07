clear;
close all

num_locs = 16;
trace_cell = cell(4,1);
mac_cell = cell(4,1);

tr_idx = 1;
loc_idx = 1;

% get loc intervals
load(['./data/0202/proc/locs_ts_head_tail_tr',num2str(tr_idx),'.mat']);
loc_ts_intrvls = zeros(num_locs,1);
for loc_ts_idx = 1:1:num_locs
    if loc_ts_idx == 1
        loc_ts_intrvls(loc_ts_idx) = 0;
        continue
    end
    loc_ts_prev_tail = loc_ts_head_tail_cell{loc_ts_idx-1,2}.Unix;
    loc_ts_cur_head = loc_ts_head_tail_cell{loc_ts_idx,1}.Unix;
    
    sec_prev = double(loc_ts_prev_tail.ts_sec);
    sec_cur = double(loc_ts_cur_head.ts_sec);
    usec_prev = double(loc_ts_prev_tail.ts_usec);
    usec_cur = double(loc_ts_cur_head.ts_usec);
    
    loc_ts_intrvls(loc_ts_idx) = ((sec_cur - sec_prev) * 10e6 + ...
        (usec_cur - usec_prev))/10e6;        % unit is second
end

% struct timestamp 
for D_idx = 1:1:4
    trace_cell{D_idx}.ts_vec = zeros(2,1);                %((sec,usec),sample)
    trace_cell{D_idx}.loc_vec = zeros(2,1);               %((x,y),sample)
    trace_cell{D_idx}.loc_idx = zeros(2,1);                %((head,tail),trace)
    ts_count = 0;
    for loc_idx = 1:1:num_locs
        load(['./get_location_mdTrack/result/0202/modify/D',num2str(D_idx),'_2G_20M_tr',...
            num2str(tr_idx),'_loc',num2str(loc_idx),'.mat']);
        
        num_sample = length(loc_cell);
        for sample_idx = 1:1:num_sample
            ts_sec_tmp = loc_cell{sample_idx,1}.tstamp.ts_sec;
            ts_usec_tmp = loc_cell{sample_idx,1}.tstamp.ts_usec;
            ts_count = ts_count+1;
            
            % remove the interval between locations
            if loc_idx >= 2
                ts_intvl = sum(loc_ts_intrvls(1:loc_idx));
                ts_sec_tmp = ts_sec_tmp - ts_intvl + 2.5;
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
% save('./get_location_mdTrack/result/0202/ready/trace.mat','trace_cell','mac_cell');

%% plot timestamp
ts_D1 = trace_cell{4,1}.ts_vec;
ts_D1_r = ts_D1 - ts_D1(:,1);
ts_D1_r_s = (ts_D1_r(1,:)*10e6+ts_D1_r(2,:))/10e6;

plot(ts_D1_r_s,'b.');


