load('./trace/SAGE_simuTrace_TxAnt_1_RxAnt_4_MultiPathNum_1_PktNum_100.mat');
X_tx_t  = lts_t;
X_tx    = lts_f;
L       = 1;
M       = 4;
N       = 64;


opt = xDTrack_system_parameter(X_tx_t,L,M,N);
for pkt_idx = 1:1:6
    Y_rx            = Y_rx_t(:,:,pkt_idx);
    [PathP,it_num]  = xDTrack(X_tx,Y_rx,opt);  
end

