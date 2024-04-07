import socket
import threading
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
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt 
from matplotlib.animation import FuncAnimation
from pylab import *

eng = matlab.engine.start_matlab()

### CSI decoding function and config
libunpackf = CDLL("./unpack_float/libunpackf.so")
unpack_float_acphy = libunpackf.unpack_float_acphy
unpack_float_acphy.argtypes = (c_int, POINTER(c_uint32), POINTER(c_int32))
unpack_float_acphy.restype = c_int

### control
num_AP = 1
tstamp_first = (0,0)
tstamp_pre = (0,0)
tstamp_now = (0,0)

### process
delimeter = b'\xaa\xaa\xaa\xaa\xaa\xaa'
OFFSET    = 60
BW        = 40
num_txAnt = 2
num_rxAnt = 4
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

### data management
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
        # print('Queue length:', len(DICT_RAW))

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
            # print('ip: ', self.ip, '\n')
            pkt = DICT_RAW.pop(0)
            frames = pkt.split(delimeter)
            frames = [delimeter + x for x in frames if len(x) > 0]

            for frm in frames:
                frm_length = len(frm)
                # print('frm_length: ', frm_length)
                
                # for b in frm:
                #     print(' {:02x}'.format(b), end='')
                # print('\n')
                if frm_length - OFFSET != 6+4*num_subcr+16:
                    continue

                core = frm[55+6] & 3                  ## number of rx antenna
                rxss = frm[55+6]>>3 & 3               ## number of spatial streams
                rx_idx  = core + 1
                # print(rx_idx, frm_length)
                if num_rxAnt == 3 and rx_idx == 4:
                    rx_idx = 3
                tx_idx  = rxss + 1
                pkt_idx = int(frm[52+6])
                tstamp_coded = frm[(frm_length-16):frm_length]
                tstamp = struct.unpack('qq', tstamp_coded)
                
                f = not bool(DICT_SUM['CSI'])
                if f:
                    tstamp_first = (tstamp[0],tstamp[1])
                    # print(tstamp_first)
                # print(tstamp,"type: ", type(tstamp))
                # print("rx_idx: ", rx_idx, "tx_idx: ", tx_idx, "pkt_idx: ", pkt_idx)
                # if pkt_idx == 255:
                #     continue

                H = frm[60+6:(num_subcr*4)+60+6]
                # print(len(H))
                H = struct.unpack('<' + ('I')*num_subcr, H)
                H = C_Hin(*[c_uint32(x) for x in H])
                H_out = C_Hout(*([c_int32()]*(num_subcr*2)))
                r = libunpackf.unpack_float_acphy(c_int(num_subcr), H, H_out)          # get CSI
                Hi = np.array(H_out[0::2])
                Hq = np.array(H_out[1::2])
                H_out = Hi + Hq*1j
                # print(H_out)
                CSI_array[rx_idx-1,tx_idx-1,:] = H_out
                # print("\n", CSI_array)

                # print(rx_idx)
                if rx_idx == num_rxAnt and tx_idx == num_txAnt:
                    DICT_SUM['CSI'].append(copy(CSI_array))
                    DICT_SUM['TS'].append(tstamp)
                    tstamp_now = (tstamp[0], tstamp[1])
                    # print('tstamp_now: ', tstamp_now)

def csiSanitThread():
    global DICT_SUM
    global DICT_SANIT
    
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

            CSI_matrix_pha_tmp = CSI_matrix_pha.tolist()
            CSI_matrix_pha_pass = matlab.double(CSI_matrix_pha_tmp)
            CSI_sanit_pha = eng.func2_sanitCSI(CSI_matrix_pha_pass)
            CSI_sanit_pha_nparray = np.array(CSI_sanit_pha)

            CSI_sanit = CSI_matrix_amp * np.exp(1j*CSI_sanit_pha_nparray)

            DICT_SANIT['CSI'].append(copy(CSI_sanit))
            DICT_SANIT['TS'].append(tstamp_tmp)

            # print(len(DICT_SANIT['CSI']))

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
    # threads_locate = []
    # tstamp_range = []

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
    # def realtime_CSI(i):
    # fig = plt.figure()
    # ax = fig.add_subplot(111)
    # lines, = ax.plot([], [], lw=2)

    # fig, ax = plt.subplots()
    # lines, = ax.plot([], [], lw=2)


    while True:
        if len(DICT_SANIT['CSI']) > 0:
            CSI_len = len(DICT_SANIT['CSI'])
            print(CSI_len)

            CSI = DICT_SANIT['CSI'][CSI_len-1]
            [n_rx, n_tx, n_sc] = CSI.shape

            CSI_amp = np.absolute(CSI)
            CSI_pha = np.angle(CSI)

            # print(len(DICT_SANIT['CSI']))
            # time.sleep(1)
            # for rx_idx in range(n_rx):
                # for tx_idx in range(n_tx):
            CSI_amp_plt = CSI_amp[1][1]
            CSI_pha_plt = CSI_pha[1][1]
            
            plt.plot(np.unwrap(CSI_pha_plt))
            plt.show()
    
    # # plt.tight_layout()

#     # Enter processing after <duration> sec system starts
# while True:
#     time_elapse = (tstamp_now[0]-tstamp_first[0], tstamp_now[1]-tstamp_first[1])
#     # print('time_elapse: ', time_elapse)
#     if time_elapse[0] >= duration_monitor:
#         np.save('DICT_TEST.npy', DICT_SUM)
#         break


for i in threads_pool:
    i.join()