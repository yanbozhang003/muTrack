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

### CSI decoding function and config
libunpackf = CDLL("./unpack_float/libunpackf.so")
unpack_float_acphy = libunpackf.unpack_float_acphy
unpack_float_acphy.argtypes = (c_int, POINTER(c_uint32), POINTER(c_int32))
unpack_float_acphy.restype = c_int

### control
num_AP = 3
tstamp_first = (0,0)
tstamp_pre = (0,0)
tstamp_now = (0,0)
duration_monitor = 10

### process
delimeter = b'\xaa\xaa\xaa\xaa\xaa\xaa'
OFFSET    = 60
BW        = 20
num_txAnt = 1
num_rxAnt = 4
num_subcr = int(BW * 3.2)
C_Hin = c_uint32*64
C_Hout = c_int32*(64*2)

### data management
DICT_RAW = {}               # {'addr1': packet queue, 'addr2': packet queue, ...}
DICT_SUM = {}               # {'ip1': {'MAC1': {'CSI': array queue, 'ts': tuple queue}, 'MAC2': {'CSI': array queue, 'ts': tuple queue}, ...}, 
                            #  'ip2': {'MAC1': {'CSI': array queue, 'ts': tuple queue}, 'MAC2': {'CSI': array queue, 'ts': tuple queue}, ...}, 
                            #  'ip3': {'MAC1': {'CSI': array queue, 'ts': tuple queue}, 'MAC2': {'CSI': array queue, 'ts': tuple queue}, ...}}}}
DICT_USR = {}               # {'ip1': {'user1': {'CSI': array queue, 'ts': tuple queue}, 'user2': {'CSI': array queue, 'ts': tuple queue}, ...}, 
                            #  'ip2': {'user1': {'CSI': array queue, 'ts': tuple queue}, 'user2': {'CSI': array queue, 'ts': tuple queue}, ...}, 
                            #  'ip3': {'user1': {'CSI': array queue, 'ts': tuple queue}, 'user2': {'CSI': array queue, 'ts': tuple queue}, ...}}}}
DICT_LOC = {}               # {'ip1': {'user1': {'(x,y): tuple queue', 'ts': tuple queue, 'user2': {'(x,y)': tuple queue, 'ts': tuple queue, ...},
                            #  'ip1': {'user1': {'(x,y): tuple queue', 'ts': tuple queue, 'user2': {'(x,y)': tuple queue, 'ts': tuple queue, ...},
                            #  'ip1': {'user1': {'(x,y): tuple queue', 'ts': tuple queue, 'user2': {'(x,y)': tuple queue, 'ts': tuple queue, ...}}}}

class clientThread(threading.Thread):
    def __init__(self, conn, ip):
        threading.Thread.__init__(self)
        global DICT_RAW
        self.conn = conn
        self.ip = ip

    def run(self):
        while True: 
            data = conn.recv(4096)
            if self.ip in DICT_RAW:
                DICT_RAW[self.ip].append(data)
            else:
                DICT_RAW[self.ip] = []
                DICT_RAW[self.ip].append(data)
   
            # print(list(DICT_RAW.keys()))
            # for i in DICT_RAW:
            #     print(len(DICT_RAW[i]))

class CSIprocThread(threading.Thread):
    def __init__(self, ip):
        threading.Thread.__init__(self)
        global delimeter
        global DICT_RAW
        global tstamp_first
        global tstamp_now
        self.ip = ip
        self.CSI_array = np.zeros((num_rxAnt, num_txAnt, num_subcr),dtype=complex)
        self.CSI_array_pha = np.zeros((num_rxAnt, num_txAnt, num_subcr),dtype=float)
    
    def run(self):
        while True:
            if self.ip in DICT_RAW and len(DICT_RAW[self.ip]) > 0:
                # print('ip: ', self.ip, '\n')
                pkt = DICT_RAW[self.ip].pop(0)
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
                    self.CSI_array[rx_idx-1,tx_idx-1,:] = H_out
                    # print("\n", CSI_array)
                    for sc_idx in range(64):
                        self.CSI_array_pha[rx_idx-1,tx_idx-1,sc_idx] = cmath.phase(H_out[sc_idx])

                    if rx_idx == 4:
                        MAC = ':'.join(['{:02x}'.format(x) for x in frm[46+6:46+6+6]])
                        try:
                            DICT_SUM[self.ip][MAC]
                        except:
                            try:
                                DICT_SUM[self.ip]
                            except:
                                DICT_SUM[self.ip] = {}
                            finally:
                                DICT_SUM[self.ip][MAC] = {}
                                DICT_SUM[self.ip][MAC]['CSI'] = []
                                DICT_SUM[self.ip][MAC]['TS'] = []
                        finally:
                            DICT_SUM[self.ip][MAC]['CSI'].append(self.CSI_array)
                            DICT_SUM[self.ip][MAC]['TS'].append(tstamp)
                            tstamp_now = (tstamp[0], tstamp[1])
                        
                        # print_ts = DICT_SUM[self.ip][MAC]['TS'].pop()
                        # DICT_SUM[self.ip][MAC]['TS'].append(print_ts)
                        # print('ip:', self.ip, 'MAC: ', MAC, 'CSI queue length: ', len(DICT_SUM[self.ip][MAC]['CSI']), 'TS length: ', len(DICT_SUM[self.ip][MAC]['TS']), 'TS: ', print_ts)

def user_identify(ts_range):
    global DICT_SUM
    global DICT_USR
    # user indentification algorithm goes here
    num_user = 1
    return num_user

class locateThread(threading.Thread):
    def __init__(self, ip):
        threading.Thread.__init__(self)
        global DICT_USR
        global DICT_LOC
        self.ip = ip
    
    def run(self):
        print('\n')

### main start here
SERVER_IP   = ''
SERVER_PORT = 8080

SERVER = socket.socket(socket.AF_INET, socket.SOCK_STREAM)		 
SERVER.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
print("Socket successfully created")

SERVER.bind((SERVER_IP, SERVER_PORT))
print("socket binded to ", SERVER_PORT)

SERVER.listen(5)	 
print("socket is listening")

threads_preprc = []
threads_locate = []
AP_ip = []
AP_cnt = 0
tstamp_range = []
# global tstamp_first
# global tstamp_pre
# global tstamp_now
# global duration_monitor

while True:
    (conn, (ip, port)) = SERVER.accept()	 
    print('Got connection from', ip)
    thread_recv = clientThread(conn,ip)
    thread_recv.start()
    threads_preprc.append(thread_recv)
    thread_proc = CSIprocThread(ip)
    thread_proc.start()
    threads_preprc.append(thread_proc)
    AP_cnt += 1
    AP_ip.append(ip)
    if AP_cnt == num_AP:
        break

print('Time to start process')

# Enter processing after <duration> sec system starts
while True:
    time_elapse = (tstamp_now[0]-tstamp_first[0], tstamp_now[1]-tstamp_first[1])
    if time_elapse[0] >= duration_monitor:
        tstamp_range = [tstamp_first, tstamp_now]
        tstamp_pre = (tstamp_now[0], tstamp_now[1])
        num_user = user_identify(tstamp_range)
        break

# Enter the identification-localization cycle
while True:
    for ip_addr in AP_ip:
        thread_locate = locateThread(ip_addr)
        thread_locate.start()
        threads_locate.append(thread_locate)
    for i in threads_locate:
        i.join()
    # show the location here

    # start a new round of identify-locate
    tstamp_range = [tstamp_pre, tstamp_now]
    tstamp_pre = (tstamp_now[0],tstamp_now[1])
    num_user = user_identify(tstamp_range)

for i in threads_preprc:
    i.join()










