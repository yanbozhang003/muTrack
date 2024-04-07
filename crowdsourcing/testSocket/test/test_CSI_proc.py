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

### socket config
port           = 8080
max_queue_len  = 10000
queue          = []
# delimeter      = b'\xff\xff\xff\xff\xff'
delimeter = b'\xaa\xaa\xaa\xaa\xaa\xaa'

### AP config
BW        = 20
num_txAnt = 1
num_rxAnt = 4
num_subcr = int(BW * 3.2)

### CSI decoding function and config
libunpackf = CDLL("./unpack_float/libunpackf.so")
unpack_float_acphy = libunpackf.unpack_float_acphy
unpack_float_acphy.argtypes = (c_int, POINTER(c_uint32), POINTER(c_int32))
unpack_float_acphy.restype = c_int

OFFSET = 60                  # first 60 bytes are UDP header
C_Hin = c_uint32*64
C_Hout = c_int32*(64*2)
CSI_dict = {}                   # MAC address: CSI queue, save CSI from all clients
CSI_pha_dict = {}
CSI_array = np.zeros((num_rxAnt, num_txAnt, num_subcr),dtype=complex)
CSI_array_pha = np.zeros((num_rxAnt, num_txAnt, num_subcr),dtype=float)
array_pha_diff = np.zeros(52,dtype=float)

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

class Thread_A(threading.Thread):
    def __init__(self, name, q):                        
        threading.Thread.__init__(self)
        self.name = name
        self.q    = q

    def run(self):
        while True:
            data = conn.recv(4096)
            self.q.append(data)
            if len(self.q) == max_queue_len:
                break

class Thread_B(threading.Thread):
    def __init__(self, name, q):
        threading.Thread.__init__(self)
        self.name = name
        self.q    = q

    def run(self):
        while True:
            if len(self.q) > 0:
                socket_pkt = self.q.pop(0)
                # print(pkt)
                # print("pkt_len: ", len(pkt), "\n")
                # print("\nqueue length: ", len(q))
                ### split socket frame
                frames = socket_pkt.split(delimeter)
                frames = [delimeter + x for x in frames]    # remove the first empty frame later
                # for x in frame:
                #     print(x)
                # print("\n", "number of frame: ", num_frame)

                ### fill in CSI dictionary
                for frm in frames:
                    frm_length = len(frm)
                    if frm_length - OFFSET != 4*num_subcr+6+16:
                        continue
                    # print(frm, "\nfrm length: ", frm_length)
                    
                    # for b in frm:
                    #     print(' {:02x}'.format(b), end='')
                    # print('\n')
                    
                    core = frm[55+6] & 3                  ## number of rx antenna
                    rxss = frm[55+6]>>3 & 3               ## number of spatial streams
                    rx_idx  = core + 1
                    tx_idx  = rxss + 1
                    pkt_idx = int(frm[52+6])
                    print("rx_idx: ", rx_idx, "tx_idx: ", tx_idx, "pkt_idx: ", pkt_idx)
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
                        CSI_array_pha[rx_idx-1,tx_idx-1,sc_idx] = cmath.phase(H_out[sc_idx])

                    if rx_idx == 4:
                        MAC = ':'.join(['{:02x}'.format(x) for x in frm[46:(46+6)]])
                        if MAC in CSI_dict:
                            CSI_dict[MAC].append(CSI_array)
                            CSI_pha_dict[MAC].append(CSI_array_pha)
                        else:
                            CSI_dict[MAC] = []
                            CSI_dict[MAC].append(CSI_array)
                            CSI_pha_dict[MAC] = []
                            CSI_pha_dict[MAC].append(CSI_array_pha)

                        # for key, value in CSI_pha_dict.items():
                        #     print(key, value)

                        head = 1
                        tail = 63
                        left_len = 25
                        right_len = 25
                        seg1 = CSI_array_pha[:,:,head:(head+left_len+1)]
                        seg2 = CSI_array_pha[:,:,(tail-right_len-1):tail]
                        CSI_pha_correct = np.concatenate((seg2, seg1), axis=2)

                        for idx in range(52):
                            pha_rx1 = CSI_pha_correct[0,0,idx]
                            pha_rx2 = CSI_pha_correct[1,0,idx]
                            # print("pha_rx1: ", pha_rx1, " | pha_rx2: ", pha_rx2)
                            pha_rx1_2pi = wrapTo2Pi(pha_rx1)
                            pha_rx2_2pi = wrapTo2Pi(pha_rx2)
                            array_pha_diff[idx] = wrapToPi(pha_rx2_2pi - pha_rx1_2pi)
                        
                        plt.plot(array_pha_diff)
                        plt.ylim(-np.pi,np.pi)
                        plt.pause(0.05)
                        plt.hold(True)

                        # plt.subplot(121)
                        # plt.plot(CSI_array_pha[0,0,:])
                        # plt.pause(0.05)
                        # plt.hold(False)
                        # plt.subplot(122)
                        # plt.plot(CSI_array_pha[1,0,:])
                        # plt.pause(0.05)
                        # plt.hold(False)
                        # plt.subplot(143)
                        # plt.plot(CSI_array_pha[2,0,:])
                        # # plt.pause(0.05)
                        # plt.hold(False)
                        # plt.subplot(144)
                        # plt.plot(CSI_array_pha[3,0,:])
                        # plt.pause(0.05)
                        # plt.hold(False)
        # plt.show()


### main start here
s = socket.socket()		 
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
print("Socket successfully created")

s.bind(('', port))		 
print("socket binded to %s" %(port) )

s.listen(5)	 
print("socket is listening")			

conn, addr = s.accept()	 
print('Got connection from', addr)

# create threads
a = Thread_A("sock_recv", queue)
b = Thread_B("proc_raw_data", queue)

a.start()
b.start()

a.join()
b.join()




 
