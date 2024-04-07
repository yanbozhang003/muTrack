import numpy as np
import json
import matplotlib.pyplot as plt
import matplotlib.image as mpimg

from funcTraj import get_loc_samples

### simulate location samples
Device_idx = 1
D_locVec,D_tsVec = get_loc_samples(Device_idx)
D_locVec = D_locVec*100.0

# # plot trace on map
# img = mpimg.imread('./data/cncl_map.png')

# plt.figure()
# plt.imshow(img)
# plt.plot(D_locVec[0,:],D_locVec[1,:],'ro',markersize=0.5)

# plt.figure()
# plt.plot(D_tsVec,'bo',markersize=0.5)

# plt.show()

### load data
FILENAME = 'voicecall'
fp = open('./data/'+FILENAME+'.json','r')
DICT_ALL = json.load(fp)

### plot timestamp
D_MAC = '76:ac:75:45:1a:71'
D_pkt_Q = DICT_ALL[D_MAC]
D_ts_Q  = []               # absolute value
D_tsR_Q  = []              # relative value
iterate_idx  = 0
for D_pkt in D_pkt_Q:
    D_ts_Q.append(D_pkt['tstamp'])
    iterate_idx = iterate_idx + 1
    if iterate_idx == 1:
        ts_pkt1 = D_pkt['tstamp']
        D_tsR_Q.append(0.0)
    else:
        tsR = D_pkt['tstamp'] - ts_pkt1
        D_tsR_Q.append(tsR)

tsPltLen = len(D_ts_Q)
pltX = np.linspace(1,tsPltLen,num=tsPltLen)
pltY = D_tsR_Q
plt.plot(pltX,pltY,'ro',markersize=0.5)
plt.show()

### allocate loc samples to the captured pkts

## 
