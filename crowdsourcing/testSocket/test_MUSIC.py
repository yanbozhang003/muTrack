import matlab.engine
import numpy as np 
import cmath
import math
import time
import matplotlib.pyplot as plt

eng = matlab.engine.start_matlab()
eng.addpath(r'/home/project6/work/muTrack/AoAest/MUSIC')

DICT_SUM = np.load('./DICT_SUM_monitor_single_phone.npy',allow_pickle = True).item()

n_pkt_MUSIC = 10
CSI_array_pha = np.zeros((4, 1, 52),dtype=float)
CSI_array_amp = np.zeros((4, 1, 52),dtype=float)
CSI_pass = np.zeros((4,1,52,n_pkt_MUSIC),dtype=float)
array_pha_diff = np.zeros((4,52), dtype=float)

head = 1
tail = 63
left_len = 25
right_len = 25

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
        for idx in range(n_pkt_MUSIC):
            # print('ip: ', ip, 'MAC: ', MAC, 'num_CSI: ', num_CSI, 'Idx: ', idx)
            CSI_array = DICT_SUM[ip][MAC]['CSI'][idx]
            seg1 = CSI_array[:,:,head:(head+left_len+1)]
            seg2 = CSI_array[:,:,(tail-right_len-1):tail]
            CSI_array_correct = np.concatenate((seg2, seg1), axis=2)
            
            CSI_pass[:,:,:,idx] = CSI_array_correct

        CSI_pass_list = CSI_pass.tolist()
        arr_pass = matlab.double(CSI_pass_list)
        MUSIC_ret = eng.AoAest(arr_pass)
        print(MUSIC_ret)
        
