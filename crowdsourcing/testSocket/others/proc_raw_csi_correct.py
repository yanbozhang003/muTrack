from ctypes import *
from unpack_float import *
import numpy as np

libunpackf = CDLL("./unpack_float/libunpackf.so")
unpack_float_acphy = libunpackf.unpack_float_acphy
unpack_float_acphy.argtypes = (c_int, POINTER(c_uint32))
unpack_float_acphy.restype = POINTER(c_int32)

data = np.load("data.npz")
frame = data['arr_0'].tolist()

n_frame = len(frame)
f_count = 0
offset = 60
nfft = 64
H_out = [c_int32(100)]*nfft*2
sc_count = 0

while f_count < n_frame:
    f_count += 1
    pkt = frame[f_count-1]
    len_pkt = len(pkt)

    while offset < len_pkt:
        H = pkt[offset:offset+4]
        for b in H:
            print(' {:02x}'.format(b), end='')
        H = int.from_bytes(H,'little')
        H = c_uint32(H)
        # H_out = c_int32()
        r = libunpackf.unpack_float_acphy(c_int(nfft), pointer(H))
        H_out[sc_count*2] = r[0]
        H_out[sc_count*2+1] = r[1]
        print("\n")
        offset += 4
        print(H_out[sc_count*2],' ',H_out[sc_count*2+1],'\n')

        sc_count += 1
        print(sc_count)
        print("\n")
        

    for b in pkt[60:]:
        print(' {:02x}'.format(b), end='')
    print('\n')

        
        
        
        
        
    


