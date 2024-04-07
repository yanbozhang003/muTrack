
import numpy as np

# test_dict = {'a': 'b', 'c': 'd', 'e': 'f','g':'h','i':6}

# np.save('./test/test_dict_save.npy',test_dict)
test_dict_load = np.load('./test/test_dict_save.npy',allow_pickle=True).item()
print(test_dict_load)

# test_dict_empty = {}

# a = not bool(test_dict)
# b = not bool(test_dict_empty)
# print(a,'\n', b, '\n')

# ip = '192.168.1.1'
# MAC = '04:f0:21:32:22:22'
# CSI_array = np.zeros((4, 1, 64),dtype=complex)

# DICT_SUM = {}
# # DICT_SUM[ip] = {}
# # DICT_SUM[ip][MAC] = []

# try:
#     DICT_SUM[ip][MAC]
# except:
#     try:
#         DICT_SUM[ip]
#     except:
#         DICT_SUM[ip] = {}
#     finally:
#         DICT_SUM[ip][MAC] = []
# finally:
#     DICT_SUM[ip][MAC].append(CSI_array)

# print('\n')
