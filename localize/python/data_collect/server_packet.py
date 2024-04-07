import socket
import threading
import time
import numpy as np
import struct
from ctypes import *
from unpack_float import *
import cmath
import math
import matplotlib.pyplot as plt
from copy import copy, deepcopy
import logging
import h5py
from scipy.io import savemat

### CSI decoding function and config
libunpackf = CDLL("./unpack_float/libunpackf.so")
unpack_float_acphy = libunpackf.unpack_float_acphy
unpack_float_acphy.argtypes = (c_int, POINTER(c_uint32), POINTER(c_int32))
unpack_float_acphy.restype = c_int

### control
num_AP = 5

### process
delimeter = b'\xaa\xaa\xaa\xaa\xaa\xaa'
OFFSET    = 60
BW        = 20
num_txAnt = 1
num_rxAnt = 3
num_subcr = int(BW * 3.2)
C_Hin = c_uint32*num_subcr
C_Hout = c_int32*(num_subcr*2)

buf_len =  6 + OFFSET + (4 * num_subcr) + 16

### data management
DICT_RAW = {}               # {'addr1': packet queue, 'addr2': packet queue, ...}

def clientThread(conn, ip):
    global DICT_RAW
    while True: 
        data = conn.recv(buf_len)
        if ip not in DICT_RAW:
            DICT_RAW[ip] = []        
        # print(data)
        if len(data) > 0:
            DICT_RAW[ip].append(data)
        print('Queue length:', len(DICT_RAW[ip]))

def frmProcThread(ip):
    global tstamp_first
    global tstamp_now
    global delimeter
    global DICT_RAW
    tstamp = ()
    
    while True:
        if ip in DICT_RAW and len(DICT_RAW[ip]) > 0:
            # print('ip: ', self.ip, '\n')
            pkt = DICT_RAW[ip].pop(0)
            frames = pkt.split(delimeter)
            frames = [delimeter + x for x in frames if len(x) > 0]

            for frm in frames:
                frm_length = len(frm)
                # print('frm_length: ', frm_length)
                
                # for b in frm:
                #     print(' {:02x}'.format(b), end='')
                # print('\n')

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

    threads_preprc = list()
    threads_locate = []
    AP_ip = []
    AP_cnt = 0
    tstamp_range = []

    time_count = 0

    for index in range(num_AP):
        (main_conn, (main_ip, port)) = SERVER.accept()	 
        print('Got connection from', main_ip)
        th_sock = threading.Thread(target=clientThread, args=(main_conn,main_ip))
        threads_preprc.append(th_sock)
        th_proc = threading.Thread(target=frmProcThread, args=(main_ip,))
        threads_preprc.append(th_proc)
        AP_ip.append(main_ip)
        if index+1 == num_AP:
            th_sock.start()
            # th_proc.start()

    # Enter processing after <duration> sec system starts
    while True:
        time_count = time_count + 1
        if time_count == 1:
            t1 = time.time()
        t = time.time()
        # print(t-t1)
        if t-t1 >= 10:
            np.save('test_data.npy', DICT_RAW)
            savemat("test_frm.mat", DICT_RAW)
            break

        # # Enter the identification-localization cycle
        # while True:
        #     for ip_addr in AP_ip:
        #         thread_locate = locateThread(ip_addr)
        #         thread_locate.start()
        #         threads_locate.append(thread_locate)
        #     for i in threads_locate:
        #         i.join()
        #     # show the location here

        #     # start a new round of identify-locate
        #     tstamp_range = [tstamp_pre, tstamp_now]
        #     tstamp_pre = (tstamp_now[0],tstamp_now[1])
        #     num_user = user_identify(tstamp_range)

    for i in threads_preprc:
        i.join()