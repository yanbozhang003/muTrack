import socket
import threading, os
import time
import struct
from ctypes import *
from unpack_float import *
import cmath
import math
from copy import copy, deepcopy
import logging

import matlab.engine
import numpy as np
import numpy.matlib 
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt 
from matplotlib.animation import FuncAnimation

eng = matlab.engine.start_matlab()

### Radio configure
# Set up your radio configure here
# BW = 20/40/80, depending on the channel bandwidth in use
# num_rxAnt = 1/2/3/4, depending on the number of enabled receiving RF chains in use
# num_txAnt = 1/2/3/4, depending on the number of tranmission spatial streams
BW        = 20
num_txAnt = 1
num_rxAnt = 4

### Dependency
libunpackf = CDLL("./unpack_float/libunpackf.so")
unpack_float_acphy = libunpackf.unpack_float_acphy
unpack_float_acphy.argtypes = (c_int, POINTER(c_uint32), POINTER(c_int32))
unpack_float_acphy.restype = c_int

### Control
tstamp_first = (0,0)
tstamp_now = (0,0)
PLOT_ONLINE = 0
duration_monitor = 5

### Parameters
delimeter = b'\xaa\xaa\xaa\xaa\xaa\xaa'
OFFSET    = 60
num_subcr = int(BW * 3.2)
C_Hin = c_uint32*num_subcr
C_Hout = c_int32*(num_subcr*2)
buf_len =  6 + OFFSET + (4 * num_subcr) + 16

if BW == 20:
    left_h = 2
    left_t = 29
    right_h = 37
    right_t = 64
    sc_idle_idx = [7,21,34,48]

if BW == 40:
    left_h = 3
    left_t = 59
    right_h = 71
    right_t = 127
    sc_idle_idx = [5,33,47,66,80,108]

if BW == 80:
    left_h = 3
    left_t = 123
    right_h = 135
    right_t = 255
    sc_idle_idx = [19,47,83,111,130,158,194,222]

### Data
DICT_RAW = []               # {'addr1': packet queue, 'addr2': packet queue, ...}
DICT_SUM = {}               # {'CSI': array queue, 'ts': tuple queue}
DICT_SUM['CSI'] = []
DICT_SUM['TS'] = []
DICT_SANIT = {}             
DICT_SANIT['CSI'] = []
DICT_SANIT['TS'] = []

def clientThread(conn):
    global DICT_RAW
    while True: 
        data = conn.recv(buf_len)
        DICT_RAW.append(data)

def csiDecodeThread():
    global tstamp_first
    global tstamp_now
    global delimeter
    global DICT_RAW
    global DICT_SUM
    CSI_array = np.zeros((num_rxAnt, num_txAnt, num_subcr),dtype=complex)
    tstamp = ()
    
    while True:
        if len(DICT_RAW) > 0:
            pkt = DICT_RAW.pop(0)
            frames = pkt.split(delimeter)
            frames = [delimeter + x for x in frames if len(x) > 0]

            for frm in frames:
                frm_length = len(frm)
                if frm_length - OFFSET != 6+4*num_subcr+16:
                    continue

                core = frm[55+6] & 3     
                rxss = frm[55+6]>>3 & 3  
                rx_idx  = core + 1
                if num_rxAnt == 3 and rx_idx == 4:
                    rx_idx = 3
                tx_idx  = rxss + 1
                tstamp_coded = frm[(frm_length-16):frm_length]
                tstamp = struct.unpack('qq', tstamp_coded)
                
                f = not bool(DICT_SANIT['CSI'])
                if f:
                    tstamp_first = (tstamp[0],tstamp[1])

                H = frm[60+6:(num_subcr*4)+60+6]
                H = struct.unpack('<' + ('I')*num_subcr, H)
                H = C_Hin(*[c_uint32(x) for x in H])
                H_out = C_Hout(*([c_int32()]*(num_subcr*2)))
                r = libunpackf.unpack_float_acphy(c_int(num_subcr), H, H_out)          # get CSI
                Hi = np.array(H_out[0::2])
                Hq = np.array(H_out[1::2])
                H_out = Hi + Hq*1j
                CSI_array[rx_idx-1,tx_idx-1,:] = H_out
            
                if rx_idx == num_rxAnt and tx_idx == num_txAnt:
                    DICT_SUM['CSI'].append(copy(CSI_array))
                    DICT_SUM['TS'].append(tstamp)
                    tstamp_now = (tstamp[0], tstamp[1])

def csiSanitThread():
    global DICT_SUM
    global DICT_SANIT
    TH = 0.2
    
    while True:
        if len(DICT_SUM['CSI']) > 0:
            CSI_matrix = DICT_SUM['CSI'].pop(0)
            tstamp_tmp = DICT_SUM['TS'].pop(0)

            seg1 = CSI_matrix[:,:,(left_h-1):left_t]
            seg2 = CSI_matrix[:,:,(right_h-1):right_t]
            CSI_matrix = np.concatenate((seg2, seg1), axis=2)
            CSI_matrix_r = np.delete(CSI_matrix,sc_idle_idx,axis=2)

            CSI_matrix_amp = np.absolute(CSI_matrix_r)
            CSI_matrix_pha = np.angle(CSI_matrix_r)
            
            # skip the packets having 0 rows
            error_flag = np.all((CSI_matrix_amp==0),axis=2)
            if np.all((error_flag == True)):
                continue    
            
            # [n_rx,n_tx,n_sc] = CSI_matrix_pha.shape
            # pha_sanit = np.zeros((n_rx,n_tx,n_sc))
            # for tx_idx in range(n_tx):
            #     pha = CSI_matrix_pha[:,tx_idx,:]
            #     CSI_pha = np.unwrap(pha,axis=1)
            #     CSI_pha_avg = np.mean(CSI_pha,axis=0)
            #     p = np.polyfit(np.linspace(1,n_sc,n_sc),CSI_pha_avg,1)
            #     CSI_pha = CSI_pha - np.matlib.repmat(np.linspace(1,n_sc,n_sc)*p[0],n_rx,1)
            #     for rx_idx in range(n_rx):
            #         CSI_ali_pha = CSI_pha[rx_idx,:]
            #         for sc_idx in range(n_sc-1):
            #             th = CSI_ali_pha[sc_idx+1]-CSI_ali_pha[sc_idx]
            #             if abs(th) >= TH:
            #                 CSI_ali_pha[sc_idx+1:] = CSI_ali_pha[sc_idx+1:] - th
            #             pha_sanit[rx_idx,tx_idx,:] = (CSI_ali_pha + np.pi) % (2 * np.pi) - np.pi
            CSI_matrix_pha_tmp = CSI_matrix_pha.tolist()
            CSI_matrix_pha_pass = matlab.double(CSI_matrix_pha_tmp)
            CSI_sanit_pha = eng.func_sanitCSI(CSI_matrix_pha_pass)
            CSI_sanit_pha_nparray = np.array(CSI_sanit_pha)

            CSI_sanit = CSI_matrix_amp * np.exp(1j*CSI_sanit_pha_nparray)

            DICT_SANIT['CSI'].append(copy(CSI_sanit))
            DICT_SANIT['TS'].append(tstamp_tmp)

if __name__ == "__main__":
    SERVER_IP   = ''
    SERVER_PORT = 8080

    SERVER = socket.socket(socket.AF_INET, socket.SOCK_STREAM)		 
    SERVER.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    print("Socket successfully created")

    SERVER.bind((SERVER_IP, SERVER_PORT))
    print("socket binded to ", SERVER_PORT)

    SERVER.listen(5)	 
    print("socket is listening")

    threads_pool = list()

    (main_conn, (main_ip, port)) = SERVER.accept()	 
    print('Got connection from', main_ip)
    th_sock = threading.Thread(target=clientThread, args=(main_conn,))
    threads_pool.append(th_sock)
    th_dec = threading.Thread(target=csiDecodeThread, args=())
    threads_pool.append(th_dec)
    th_sanit = threading.Thread(target=csiSanitThread, args=())
    threads_pool.append(th_sanit)

    th_sock.start()
    th_dec.start()
    th_sanit.start()

    # Start implementing your application here
    # CSI visualization is used as an example
    if PLOT_ONLINE == 1:
        def CSI_plot(i):
            if len(DICT_SANIT['CSI']) > 0:
                CSI_len = len(DICT_SANIT['CSI'])
                print(CSI_len)
                CSI = DICT_SANIT['CSI'][CSI_len-1]

                CSI_amp = np.absolute(CSI)
                CSI_pha = np.angle(CSI)

                CSI_amp_plt = CSI_amp[0][0]
                CSI_pha_plt = CSI_pha[0][0]

                plt.clf()
                plt.plot(CSI_pha_plt)

        ani = FuncAnimation(plt.gcf(),CSI_plot, interval=1000)    
        plt.show()
    else:
        # Save data for offline plot
        while True:
            CSI_len = len(DICT_SANIT['CSI'])
            # print('Collected packet number:',CSI_len)
            time_elapse = (tstamp_now[0]-tstamp_first[0], tstamp_now[1]-tstamp_first[1])
            print('time_elapse: ', time_elapse)
            if time_elapse[0] >= duration_monitor:
                np.save('./data/CSI_data.npy', DICT_SANIT)
                os._exit(1)