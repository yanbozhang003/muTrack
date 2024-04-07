import numpy as np 
import cmath
import math
import time
import matplotlib.pyplot as plt
# import matplotlib
# matplotlib.use('TkAgg')

DICT_SUM = np.load('DICT_SUM_monitor_single_phone.npy',allow_pickle = True).item()

CSI_array_pha = np.zeros((4, 1, 52),dtype=float)
CSI_array_amp = np.zeros((4, 1, 52),dtype=float)
array_pha_diff = np.zeros((4,52), dtype=float)

head = 1
tail = 63
left_len = 25
right_len = 25

num_rxAnt = 3

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
        fig1 = plt.figure(figsize=(12, 8))
        for idx in range(num_CSI):
            print('ip: ', ip, 'MAC: ', MAC, 'num_CSI: ', num_CSI, 'Idx: ', idx)
            CSI_array = DICT_SUM[ip][MAC]['CSI'][idx]
            seg1 = CSI_array[:,:,head:(head+left_len+1)]
            seg2 = CSI_array[:,:,(tail-right_len-1):tail]
            CSI_array_correct = np.concatenate((seg2, seg1), axis=2)

            for rx_idx in range(num_rxAnt):
                for sc_idx in range(52):
                    CSI_array_pha[rx_idx][0][sc_idx] = cmath.phase(CSI_array_correct[rx_idx][0][sc_idx])
                    CSI_array_amp[rx_idx][0][sc_idx] = abs(CSI_array_correct[rx_idx][0][sc_idx])

            for r_idx in range(num_rxAnt):
                for c_idx in range(52):
                    pha_rx1 = CSI_array_pha[0,0,c_idx]
                    pha_rx = CSI_array_pha[r_idx,0,c_idx]
                    # print("pha_rx1: ", pha_rx1, " | pha_rx2: ", pha_rx)
                    pha_rx1_2pi = wrapTo2Pi(pha_rx1)
                    pha_rx_2pi = wrapTo2Pi(pha_rx)
                    array_pha_diff[r_idx][c_idx] = wrapToPi(pha_rx_2pi - pha_rx1_2pi)
                array_pha_diff[r_idx][:] = np.unwrap(array_pha_diff[r_idx][:],discont=np.pi)
            
            hold_flag = True
            if idx <= 200:
                plt.subplot(241)
                plt.plot(np.unwrap(CSI_array_pha[0,0,:],discont=np.pi))
                # plt.plot(array_pha_diff[0,:])
                # plt.ylim(-np.pi,np.pi)
                # plt.hold(hold_flag)
                plt.subplot(242)
                plt.plot(np.unwrap(CSI_array_pha[1,0,:],discont=np.pi))
                # plt.plot(array_pha_diff[1,:])
                # plt.ylim(-np.pi,np.pi)
                # plt.hold(hold_flag)
                plt.subplot(243)
                plt.plot(np.unwrap(CSI_array_pha[2,0,:],discont=np.pi))
                # plt.plot(array_pha_diff[2,:])
                # plt.ylim(-np.pi,np.pi)
                # plt.hold(hold_flag)
                # plt.subplot(244)
                # plt.plot(array_pha_diff[3,:])
                # plt.ylim(-np.pi,np.pi)
                # plt.hold(hold_flag)
                plt.subplot(245)
                plt.plot(CSI_array_amp[0,0,:])
                # plt.pause(1)
                # plt.hold(hold_flag)
                plt.subplot(246)
                plt.plot(CSI_array_amp[1,0,:])
                # plt.pause(1)
                # plt.hold(hold_flag)
                plt.subplot(247)
                plt.plot(CSI_array_amp[2,0,:])
                # plt.pause(1)
                # plt.hold(hold_flag)
                # plt.subplot(248)
                # plt.plot(CSI_array_amp[3,0,:])
                plt.pause(0.3)
                # plt.hold(hold_flag)
        plt.show()


            
