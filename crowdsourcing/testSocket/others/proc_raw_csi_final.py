from ctypes import *
from unpack_float import *
import numpy as np
import struct

libunpackf = CDLL("./unpack_float/libunpackf.so")
unpack_float_acphy = libunpackf.unpack_float_acphy
unpack_float_acphy.argtypes = (c_int, POINTER(c_uint32), POINTER(c_int32))
unpack_float_acphy.restype = c_int

data = np.load("data.npz")
frame = data['arr_0'].tolist()

n_frame = len(frame)
f_count = 0

C_Hin = c_uint32*64
C_Hout = c_int32*(64*2)

while f_count < n_frame:
    f_count += 1
    pkt = frame[f_count-1]
    print(len(pkt[60:]))
    for b in pkt[60:]:
       print(' {:02x}'.format(b), end='')
    print('\n')
    
    H = pkt[60:(64*4)+60]
    print(len(H))
    H = struct.unpack('<' + ('I')*64, H)
    H = C_Hin(*[c_uint32(x) for x in H])
    H_out = C_Hout(*([c_int32()]*(64*2)))
    r = libunpackf.unpack_float_acphy(c_int(64), H, H_out)
    Hi = np.array(H_out[0::2])
    Hq = np.array(H_out[1::2])
    H_out = Hi + Hq*1j
    print(H_out)


