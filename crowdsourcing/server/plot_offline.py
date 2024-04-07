import numpy as np
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt 

DICT_SANIT = np.load('./data/CSI_data.npy',allow_pickle = True).item()

num_pkt = len(DICT_SANIT['CSI'])
[n_rx,n_tx,n_sc] = DICT_SANIT['CSI'][num_pkt-1].shape

if n_tx >= 2:
    Warning('Cannot plot all tx antenna at one time! Plot tx 1.')

tx_idx = 0
for idx in range(num_pkt):
    CSI_matrix = DICT_SANIT['CSI'][idx]

    CSI_matrix_amp = np.absolute(CSI_matrix)
    CSI_matrix_pha = np.angle(CSI_matrix)
    [n_rx,n_tx,n_sc] = CSI_matrix_amp.shape

    for rx_idx in range(n_rx):
        CSI_amp_plt = CSI_matrix_amp[rx_idx][tx_idx]
        CSI_pha_plt = CSI_matrix_pha[rx_idx][tx_idx]

        plt.subplot(2,4,rx_idx+1)
        plt.plot(CSI_amp_plt)
        plt.subplot(2,4,rx_idx+5)
        plt.plot(np.unwrap(CSI_pha_plt))
    plt.pause(0.5)

plt.show()