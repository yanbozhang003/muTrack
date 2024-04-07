import matlab.engine
import numpy as np
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt 

eng = matlab.engine.start_matlab()

DICT_SUM = np.load('DICT_TEST.npy',allow_pickle = True).item()

num_pkt = len(DICT_SUM['CSI'])

left_h = 3
left_t = 123
right_h = 135
right_t = 255

sc_idle_idx = [19,47,83,111,130,158,194,222]

for idx in range(num_pkt):
    CSI_matrix = DICT_SUM['CSI'][idx]

    seg1 = CSI_matrix[:,:,(left_h-1):left_t]
    seg2 = CSI_matrix[:,:,(right_h-1):right_t]
    CSI_matrix = np.concatenate((seg2, seg1), axis=2)
    CSI_matrix_r = np.delete(CSI_matrix,sc_idle_idx,axis=2)

    CSI_matrix_amp = np.absolute(CSI_matrix_r)
    CSI_matrix_pha = np.angle(CSI_matrix_r)
    [n_rx,n_tx,n_sc] = CSI_matrix_amp.shape
    
    # skip the packets having 0 rows
    error_flag = np.all((CSI_matrix_amp==0),axis=2)
    print(error_flag)
    if np.all((error_flag == True)):
        continue    

    CSI_matrix_pha_tmp = CSI_matrix_pha.tolist()
    CSI_matrix_pha_pass = matlab.double(CSI_matrix_pha_tmp)
    CSI_sanit_pha = eng.func_sanitCSI(CSI_matrix_pha_pass)
    CSI_sanit_pha_array = np.array(CSI_sanit_pha)
    
    if n_tx >= 2:
        Warning('Cannot plot all tx antenna at one time!')

    for rx_idx in range(n_rx):
        for tx_idx in range(n_tx):
            CSI_amp_plt = CSI_matrix_amp[rx_idx][tx_idx]
            CSI_pha_plt = CSI_sanit_pha[rx_idx][tx_idx]

            plt.subplot(2,4,rx_idx+1)
            plt.plot(CSI_amp_plt)
            plt.subplot(2,4,rx_idx+5)
            plt.plot(np.unwrap(CSI_pha_plt))
    plt.pause(1)

plt.show()