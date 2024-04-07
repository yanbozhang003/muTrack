import matlab.engine
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

### CSI decoding function and config
libunpackf = CDLL("./unpack_float/libunpackf.so")
unpack_float_acphy = libunpackf.unpack_float_acphy
unpack_float_acphy.argtypes = (c_int, POINTER(c_uint32), POINTER(c_int32))
unpack_float_acphy.restype = c_int

## MATLAB functions
eng = matlab.engine.start_matlab()
eng.addpath(r'/home/project6/work/muTrack/AoAest/MUSIC')

### control
num_AP = 1
tstamp_first = (0,0)
tstamp_pre = (0,0)
tstamp_now = (0,0)
duration_monitor = 10
n_pkt_MUSIC = 10

### process
delimeter = b'\xaa\xaa\xaa\xaa\xaa\xaa'
OFFSET    = 60
BW        = 20
num_txAnt = 1
num_rxAnt = 4
num_subcr = int(BW * 3.2)
C_Hin = c_uint32*64
C_Hout = c_int32*(64*2)

head = 1
tail = 63
left_len = 25
right_len = 25

### data management
DICT_RAW = {}               # {'addr1': packet queue, 'addr2': packet queue, ...}
DICT_SUM = {}               # {'ip1': {'MAC1': {'CSI': array queue, 'ts': tuple queue}, 'MAC2': {'CSI': array queue, 'ts': tuple queue}, ...}, 
                            #  'ip2': {'MAC1': {'CSI': array queue, 'ts': tuple queue}, 'MAC2': {'CSI': array queue, 'ts': tuple queue}, ...}, 
                            #  'ip3': {'MAC1': {'CSI': array queue, 'ts': tuple queue}, 'MAC2': {'CSI': array queue, 'ts': tuple queue}, ...}}}}
DICT_USR = {}               # {'ip1': {'user1': {'CSI': array queue, 'ts': tuple queue}, 'user2': {'CSI': array queue, 'ts': tuple queue}, ...}, 
                            #  'ip2': {'user1': {'CSI': array queue, 'ts': tuple queue}, 'user2': {'CSI': array queue, 'ts': tuple queue}, ...}, 
                            #  'ip3': {'user1': {'CSI': array queue, 'ts': tuple queue}, 'user2': {'CSI': array queue, 'ts': tuple queue}, ...}}}}
DICT_LOC = {}               # {'ip1': {'user1': {'AoA: float queue', 'ts': tuple queue, 'user2': {'AoA: float queue', 'ts': tuple queue, ...},
                            #  'ip1': {'user1': {'AoA: float queue', 'ts': tuple queue, 'user2': {'AoA: float queue', 'ts': tuple queue, ...},
                            #  'ip1': {'user1': {'AoA: float queue', 'ts': tuple queue, 'user2': {'AoA: float queue', 'ts': tuple queue, ...}}}}
CSI_MUSIC_queue = np.zeros((4,1,52,n_pkt_MUSIC),dtype=float)

def clientThread(conn, ip):
    global DICT_RAW
    while True: 
        data = conn.recv(4096)
        if ip in DICT_RAW:
            DICT_RAW[ip].append(data)
        else:
            DICT_RAW[ip] = []
            DICT_RAW[ip].append(data)
        # print('Queue length:', len(DICT_RAW[ip]))

def csiProcThread(ip):
    global tstamp_first
    global tstamp_now
    global delimeter
    global DICT_RAW
    global DICT_SUM
    CSI_array = np.zeros((num_rxAnt, num_txAnt, num_subcr),dtype=complex)
    CSI_array_pha = np.zeros((num_rxAnt, num_txAnt, num_subcr),dtype=float)
    tstamp = ()
    
    while True:
        if ip in DICT_RAW and len(DICT_RAW[ip]) > 0:
            # print('ip: ', self.ip, '\n')
            pkt = DICT_RAW[ip].pop(0)
            frames = pkt.split(delimeter)
            frames = [delimeter + x for x in frames]

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
                tx_idx  = rxss + 1
                pkt_idx = int(frm[52+6])
                tstamp_coded = frm[322:338]
                tstamp = struct.unpack('qq', tstamp_coded)
                f = not bool(DICT_SUM)
                if f:
                    tstamp_first = (tstamp[0],tstamp[1])
                    print(tstamp_first)
                # print(tstamp,"type: ", type(tstamp))
                # print("rx_idx: ", rx_idx, "tx_idx: ", tx_idx, "pkt_idx: ", pkt_idx)
                if pkt_idx == 255:
                    continue

                H = frm[60+6:(64*4)+60+6]
                # print(len(H))
                H = struct.unpack('<' + ('I')*64, H)
                H = C_Hin(*[c_uint32(x) for x in H])
                H_out = C_Hout(*([c_int32()]*(64*2)))
                r = libunpackf.unpack_float_acphy(c_int(64), H, H_out)          # get CSI
                Hi = np.array(H_out[0::2])
                Hq = np.array(H_out[1::2])
                H_out = Hi + Hq*1j
                # print(H_out)
                CSI_array[rx_idx-1,tx_idx-1,:] = H_out
                # print("\n", CSI_array)
                for sc_idx in range(64):
                    # self.CSI_array_pha[rx_idx-1,tx_idx-1,sc_idx] = cmath.phase(H_out[sc_idx])
                    CSI_array_pha[rx_idx-1,tx_idx-1,sc_idx] = cmath.phase(CSI_array[rx_idx-1,tx_idx-1,sc_idx])

                if rx_idx == 4:
                    MAC = ':'.join(['{:02x}'.format(x) for x in frm[46+6:46+6+6]])
                    try:
                        DICT_SUM[ip][MAC]
                    except:
                        try:
                            DICT_SUM[ip]
                        except:
                            DICT_SUM[ip] = {}
                        finally:
                            DICT_SUM[ip][MAC] = {}
                            DICT_SUM[ip][MAC]['CSI'] = []
                            DICT_SUM[ip][MAC]['TS'] = []
                    finally:
                        # print(self.ip, MAC, CSI_array[3][0][0])
                        DICT_SUM[ip][MAC]['CSI'].append(copy(CSI_array))
                        DICT_SUM[ip][MAC]['TS'].append(tstamp)
                        tstamp_now = (tstamp[0], tstamp[1])
                        # print('tstamp_now: ', tstamp_now)

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

    for index in range(num_AP):
        (main_conn, (main_ip, port)) = SERVER.accept()	 
        print('Got connection from', main_ip)
        th_sock = threading.Thread(target=clientThread, args=(main_conn,main_ip))
        threads_preprc.append(th_sock)
        th_proc = threading.Thread(target=csiProcThread, args=(main_ip,))
        threads_preprc.append(th_proc)
        th_sock.start()
        th_proc.start()
        AP_ip.append(main_ip)

    # Enter processing after <duration> sec system starts
while True:
    for ip in DICT_SUM:
        for MAC in DICT_SUM[ip]:
            num_CSI = len(DICT_SUM[ip][MAC]['CSI'])
            # print(num_CSI)
            if num_CSI > n_pkt_MUSIC:
                for idx in range(n_pkt_MUSIC):
                    CSI_array = DICT_SUM[ip][MAC]['CSI'][num_CSI-idx-1]
                    seg1 = CSI_array[:,:,head:(head+left_len+1)]
                    seg2 = CSI_array[:,:,(tail-right_len-1):tail]
                    CSI_array_correct = np.concatenate((seg2, seg1), axis=2)
                    CSI_MUSIC_queue[:,:,:,idx] = CSI_array_correct
                CSI_MUSIC_list = CSI_MUSIC_queue.tolist()
                arr_pass = matlab.double(CSI_MUSIC_list)
                MUSIC_ret = eng.AoAest(arr_pass)
                print(MUSIC_ret[0])
                ret_array = np.asarray(MUSIC_ret)
                idx = np.argmax(ret_array[1])
                AoA = ret_array[0][idx]
                # print(AoA)


for i in threads_preprc:
    i.join()