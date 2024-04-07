import numpy as np 
import cmath
import math
import time
import matplotlib.pyplot as plt
# import matplotlib
# matplotlib.use('TkAgg')

DICT_SUM = np.load('DICT_80M.npy',allow_pickle = True).item()

CSI_array_pha = np.zeros((4, 1, 244),dtype=float)
CSI_array_amp = np.zeros((4, 1, 244),dtype=float)
array_pha_diff = np.zeros((4,244), dtype=float)

head = 1
tail = 63
left_len = 25
right_len = 25

left_hd = 1
left_tail = 6
middle_hd = 128
middle_tail = 130
right_hd = 252
right_tail = 256

num_rxAnt = 4

figs = []

def wrapTo2Pi(Pha):
    if Pha >= 0:
        ret_Pha = Pha
    else:
        ret_Pha = Pha+2*math.pi
    return ret_Pha

def wrapToPi(Pha):
    if np.abs(Pha) > np.pi:
        Pha -= 2*np.pi*np.sign(Pha)
        ret_Pha = Pha
    else:
        ret_Pha = Pha
    return ret_Pha

for ip in DICT_SUM:
    for MAC in DICT_SUM[ip]:
        num_CSI = len(DICT_SUM[ip][MAC]['CSI'])
        # try: 
        #     plt.close(fig1)
        #     fig1 = plt.figure(figsize=(12, 8))
        # except:
        # fig1 = plt.figure(figsize=(12, 8))
        for idx in range(num_CSI):
            print('ip: ', ip, 'MAC: ', MAC, 'num_CSI: ', num_CSI, 'Idx: ', idx)
            CSI_array = DICT_SUM[ip][MAC]['CSI'][idx]
            seg1 = CSI_array[:,:,left_tail:middle_hd]
            seg2 = CSI_array[:,:,middle_tail:right_hd]
            CSI_array_correct = np.concatenate((seg2, seg1), axis=2)

            for rx_idx in range(num_rxAnt):
                for sc_idx in range(244):
                    CSI_array_pha[rx_idx][0][sc_idx] = cmath.phase(CSI_array_correct[rx_idx][0][sc_idx])
                    CSI_array_amp[rx_idx][0][sc_idx] = abs(CSI_array_correct[rx_idx][0][sc_idx])

            for r_idx in range(num_rxAnt):
                for c_idx in range(244):
                    pha_rx1 = CSI_array_pha[0,0,c_idx]
                    pha_rx = CSI_array_pha[r_idx,0,c_idx]
                    # print("pha_rx1: ", pha_rx1, " | pha_rx2: ", pha_rx)
                    pha_rx1_2pi = wrapTo2Pi(pha_rx1)
                    pha_rx_2pi = wrapTo2Pi(pha_rx)
                    array_pha_diff[r_idx][c_idx] = wrapToPi(pha_rx_2pi - pha_rx1_2pi)
                array_pha_diff[r_idx][:] = np.unwrap(array_pha_diff[r_idx][:],discont=np.pi)
            
            hold_flag = False
            if idx <= 200:
                fig = plt.figure()
                ax1 = fig.add_subplot(2,4,1)
                ax1.plot(np.unwrap(CSI_array_pha[0,0,:],discont=np.pi))
                # plt.plot(array_pha_diff[0,:])
                # plt.ylim(-np.pi,np.pi)
                # plt.hold(hold_flag)
                ax2 = fig.add_subplot(2,4,2)
                ax2.plot(np.unwrap(CSI_array_pha[1,0,:],discont=np.pi))
                # plt.plot(array_pha_diff[1,:])
                # plt.ylim(-np.pi,np.pi)
                # plt.hold(hold_flag)
                ax3 = fig.add_subplot(2,4,3)
                ax3.plot(np.unwrap(CSI_array_pha[2,0,:],discont=np.pi))
                # plt.plot(array_pha_diff[2,:])
                # plt.ylim(-np.p4,np.pi)
                # plt.hold(hold_4lag)
                ax4 = fig.add_subplot(2,4,4)
                ax4.plot(CSI_array_pha[3,0,:])
                # plt.ylim(-np.pi,np.pi)
                # plt.hold(hold_flag)
                ax5 = fig.add_subplot(2,4,5)
                ax5.plot(CSI_array_amp[0,0,:])
                # plt.pause(1)
                # plt.hold(hold_flag)
                ax6 = fig.add_subplot(2,4,6)
                ax6.plot(CSI_array_amp[1,0,:])
                # plt.pause(1)
                # plt.hold(hold_flag)
                ax7 = fig.add_subplot(2,4,7)
                ax7.plot(CSI_array_amp[2,0,:])
                # plt.pause(1)
                # plt.hold(hol4d_flag)
                ax8 = fig.add_subplot(2,4,8)
                ax8.plot(CSI_array_amp[3,0,:])
                #fig.pause(0.3)
                # plt.hold(hold_flag)
                figs.append(fig)
                fig.show()

input()
