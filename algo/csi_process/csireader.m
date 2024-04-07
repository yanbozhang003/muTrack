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
BW = 80;                % bandwidth
FILE = './data/raw/asus_vld_tr23.pcap';% capture file
NPKTS_MAX = 1000;       % max number of UDPs to process

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
    core = bitand(payloadbytes(56),3);
    rxss = bitand(bitshift(payloadbytes(56),-3),3);
    pkt = payloadbytes(53);
    
    core_v(k,1) = core;
    rxss_v(k,1) = rxss;
    pkt_v(k,1) = pkt;
    
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
    cmplx = double(Hout(1:NFFT,1))+1j*double(Hout(1:NFFT,2));
    csi_buff(k,:) = cmplx.';
    
%     disp(k);
%     disp(payloadbytes(53));
%     disp(payloadbytes(54));
    
    k = k + 1;   
end

%% plot
plotcsi_bw80(csi_buff, NFFT, false, core_v, rxss_v, pkt_v);




