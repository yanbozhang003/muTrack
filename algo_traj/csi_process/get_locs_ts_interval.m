clear all
%% csireader.m
%
% read and plot CSI from UDPs created using the nexmon CSI extractor (nexmon.org/csi)
% modify the configuration section to your needs
% make sure you run >mex unpack_float.c before reading values from bcm4358 or bcm4366c0 for the first time
%
% the example.pcap file contains 4(core 0-1, nss 0-1) packets captured on a bcm4358
%

%% configuration
CHIP = '4366c0';          % wifi chip (possible values 4339, 4358, 43455c0, 4366c0)
BW = 20;                  % bandwidth
rx_config = [0 1 3];      
n_Tx = 1;                 % Tx antenna number, currently only support 1
Band = 2;                 % frequency band 2GHz

sum_locs = 16;
tr_idx = 1;
AP_idx = 3;

loc_ts_head_tail_cell = cell(1,2);  % (loc_idx,(head_ts, tail_ts))

for loc_idx = 1:1:sum_locs
    FILE = ['../data/0202/raw/CSI_2G_20M_AP',num2str(AP_idx),...
        '_tr',num2str(tr_idx),'_loc',num2str(loc_idx),'.pcap'];% capture file
    % FILE = '../data/calib/spotFi_fastcalib_20M_2G_R1R2_AP5_tr1.pcap';
    NPKTS_MAX = 500000;       % max number of UDPs to process

    %% read file
    HOFFSET = 16;           % header offset
    NFFT = BW*3.2;          % fft size
    p = readpcap();
    p.open(FILE);
    n = min(length(p.all()),NPKTS_MAX);
    p.from_start();
    csi_buff = complex(zeros(n,NFFT),0);
    k = 1;

    core_v = zeros(1,1);
    rxss_v = zeros(1,1);
    pkt_v = zeros(1,1);

    CSI = zeros(length(rx_config),1,NFFT,1); % (rxAnt, txAnt, subc, pkt), current only support tx=1
    csi_tmp = zeros(length(rx_config),NFFT);

    pkt_cnt = 0;
    [seg1,seg2] = get_freq_seg(BW);
    idle_sc = get_subchannel(BW);
    CSI_struct = zeros(length(rx_config),1,length([seg1 seg2])-length(idle_sc));  % structure for real CSI
    CSI_cell = cell(1,1);
    MAC_dec_vec = zeros(6,1);   % save decimal macaddr ((MAC in decimal), pkt)
    while (k <= n)
        f = p.next();
        if isempty(f)
            disp('no more frames');
            break;
        end
        if f.header.orig_len-(HOFFSET-1)*4 ~= NFFT*4
            disp('skipped frame with incorrect size');
            continue;
        end
        payload = f.payload;

        payloadbytes = typecast(payload,'uint8');
        macADDR_dec = [payloadbytes(47);payloadbytes(48);payloadbytes(49);...
            payloadbytes(50);payloadbytes(51);payloadbytes(52)];
        if isequal(macADDR_dec,[240;121;232;42;242;51])
    %         macADDR_dec = [58;221;168;99;171;57];       % change to iphone mac1
            macADDR_dec = [122;166;30;41;136;23];       % change to iphone mac2
        end
        macADDR = dec2hex(double(macADDR_dec));
        macADDR = [macADDR(1,:),':',macADDR(2,:),':',macADDR(3,:),':',...
            macADDR(4,:),':',macADDR(5,:),':',macADDR(6,:)];
        time.year = floor(double(f.header.ts_sec)/31540000);    % ignore the leap year
        time.month = floor(mod(double(f.header.ts_sec),31540000)/2628000);
        residule_day = double(f.header.ts_sec)-time.year*31540000-time.month*2628000;
        time.day = floor(residule_day/86400);
        time.hour = floor((residule_day-time.day*86400)/3600);
        residule_min = residule_day-time.day*86400-time.hour*3600;
        time.min = floor(residule_min/60);
        time.sec = residule_min-time.min*60;
        time.usec = double(f.header.ts_usec);
        time.Unix = f.header;

        core = bitand(payloadbytes(56),3);
        rxss = bitand(bitshift(payloadbytes(56),-3),3);
        pkt = payloadbytes(53); % although the number should divided by 16

        core_v(k,1) = core;
        rxss_v(k,1) = rxss;
        pkt_v(k,1) = pkt;
    %     fprintf('core : %d | rxss: %d | pkt: %d\n', core, rxss, pkt);

        H = payload(HOFFSET:HOFFSET+NFFT-1);
        if (strcmp(CHIP,'4339') || strcmp(CHIP,'43455c0'))
            Hout = typecast(H, 'int16');
        elseif (strcmp(CHIP,'4358'))
            Hout = unpack_float(int32(0), int32(NFFT), H);
        elseif (strcmp(CHIP,'4366c0'))
            Hout = unpack_float(int32(1), int32(NFFT), H);
        else
            disp('invalid CHIP');
            break;
        end
        Hout = reshape(Hout,2,[]).';
    %     k
        cmplx = double(Hout(1:NFFT,1))+1j*double(Hout(1:NFFT,2));
        csi_buff(k,:) = cmplx.';
        k = k + 1;   

        % reconstruct CSI
        if mod(pkt,16)~=0
            disp('skip error frame');
            continue
        end
        rx_idx = map_core_idx(core, rx_config);

        csi_tmp(rx_idx,:) = cmplx;
    %     flag1 = length(find(csi_tmp==0));

        if rx_idx == length(rx_config)
    %         if isempty(find(abs(csi_tmp)==zeros(1,NFFT), 1))
                CSI_mat_tmp = csi_tmp(:,[seg2 seg1]);
    %             CSI_error_tst_dbamp = db(abs(CSI_mat_tmp));
    %             m_diff = dbinv(diff(CSI_error_tst_dbamp,1,2));
    %             if isempty(find(m_diff>20, 1))
                    pkt_cnt = pkt_cnt + 1;            
        %             if length(rx_config)==1
        %                 csi_tmp = csi_tmp.';
        %             end
                    CSI_mat_tmp(:,idle_sc) = [];
                    CSI_struct(:,1,:) = CSI_mat_tmp;

                    CSI_cell{pkt_cnt,1}.CSI = CSI_struct;
                    CSI_cell{pkt_cnt,1}.tstamp = time;
                    CSI_cell{pkt_cnt,1}.macADDR = macADDR;

                    MAC_dec_vec(:,pkt_cnt) = macADDR_dec;
    %             else
    %                 disp('Error: contains noisy subcarriers! Skip this packet.');
    %             end
    %         else
    %             disp('Error: contains empty channel! Skip this packet.');
    %         end
            csi_tmp = zeros(length(rx_config),NFFT);
        end
        if AP_idx == 3
        % remove measurement interval between locs, use 2nd AP as reference
            if k == 2
                loc_ts_head_tail_cell{loc_idx,1} = time;
            end
            if k == n+1
                loc_ts_head_tail_cell{loc_idx,2} = time;
            end
        end
    end

    if loc_idx == sum_locs && AP_idx == 3
        save(['../data/0202/proc/locs_ts_head_tail_tr',...
            num2str(tr_idx),'.mat'],'loc_ts_head_tail_cell');
    end
end