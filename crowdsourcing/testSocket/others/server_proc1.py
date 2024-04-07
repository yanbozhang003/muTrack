import socket
import threading
import time
import numpy as np
import struct
from ctypes import *
from unpack_float import *

### socket config
port           = 8080
max_queue_len  = 10000
queue          = []
delimeter      = b'\xff\xff\xff\xff\xff'

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

OFFSET    = 60                  # first 60 bytes are UDP header
C_Hin = c_uint32*64
C_Hout = c_int32*(64*2)
CSI_array = np.zeros((num_rxAnt, num_txAnt, num_subcr),dtype=complex)
CSI_dict = {}                   # MAC address: CSI queue, save CSI from all clients

poll_flag = 0
poll_MAC  = 'ff:ff:ff:ff:ff:ff'
CSI_dict_poll = {}              # MAC address: CSI queue, save CSI from certain client during polling

def sock_recv(q):
    while True:
        data = conn.recv(4096)
        q.append(data)
        if len(q) == max_queue_len:
            break

def raw_data_proc(q):
    while True:
        if len(q) > 0:
            socket_pkt = q.pop(0)
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
                if frm_length - OFFSET != 4*num_subcr:
                    continue
                # print(frm, "\nfrm length: ", frm_length)
                
                # for b in frm:
                #     print(' {:02x}'.format(b), end='')
                # print('\n')
                
                core = frm[55] & 3                  ## number of rx antenna
                rxss = frm[55]>>3 & 3               ## number of spatial streams
                rx_idx  = core + 1
                tx_idx  = rxss + 1
                pkt_idx = int(frm[52])
                # print("rx_idx: ", rx_idx, "tx_idx: ", tx_idx, "pkt_idx: ", pkt_idx)
                if pkt_idx == 255:
                    continue
                
                H = frm[60:(64*4)+60]
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

                if rx_idx == 4:
                    MAC = ':'.join(['{:02x}'.format(x) for x in frm[46:(46+6)]])
                    if MAC in CSI_dict:
                        CSI_dict[MAC].append(CSI_array)
                    else:
                        CSI_dict[MAC] = []
                        CSI_dict[MAC].append(CSI_array)
                    # for key, value in CSI_dict.items():
                    #     print(key, len(value))
                    
                    # if poll_flag == 1 and poll_MAC == MAC:
                    if poll_flag == 1:
                            CSI_dict_poll[MAC].append(CSI_array)

def polling_ctrl():
    ### no control period (collect device info)
    time.sleep(10)

    ### start polling
    CSI_dict_tmp = CSI_dict
    num_device = len(CSI_dict_tmp)
    print("Total device number: ", num_device)
    for key, value in CSI_dict_tmp.items():
        MAC = key
        poll_flag = 1
        CSI_dict_poll = {}
        CSI_dict_poll[MAC]=[]
        conn.send(MAC.encode())

        time.sleep(5)
        for key, value in CSI_dict_poll.items():
            print(key, len(value))
        ### call MUSIC



if __name__ == "__main__":

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
    th1 = threading.Thread(target=sock_recv,args=(queue,))
    th2 = threading.Thread(target=raw_data_proc,args=(queue,))
    th3 = threading.Thread(target=polling_ctrl,args=())

    th1.start()
    th2.start()
    th3.start()

    th1.join()
    th2.join()
    th3.join()




 
