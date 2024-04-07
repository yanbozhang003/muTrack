from random import random
from random import seed
import numpy as np
import matplotlib.pyplot as plt

seed(1)

pha_v = np.zeros(64,dtype=float)
sc_idx = np.zeros(64, dtype=float)
for idx in range(64):
    if idx < 32:
        pha_v[idx] = idx
    else:
        pha_v[idx] = 63 - idx
    sc_idx[idx] = idx+1

head = 1
tail = 61
left_len = 25
right_len = 25
seg1 = pha_v[head:(head+left_len)]
seg2 = pha_v[(tail-right_len):tail]

pha_new = np.concatenate((seg2,seg1),axis=0)

plt.subplot(211)
plt.plot(pha_v)
plt.subplot(212)
plt.plot(pha_new)
plt.show()

