import numpy as np
import json
import matplotlib.pyplot as plt

FILENAME_v = ['chrome','chessgame','chat','videocall',
                'voicecall','spotify','youtube']
traceIdx = '2'
num_FILEs  = len(FILENAME_v)

plt_tWinLen = 5                                # plot time window length
dictAppFeatures = {}
for FILE_idx in range(num_FILEs):
    ### load data
    FILENAME = FILENAME_v[FILE_idx]
    fp = open('./data/networkTraffic/trace'+traceIdx+'/'+FILENAME+'.json','r')
    DICT_ALL = json.load(fp)

    ### plot timestamp
    D_MAC = '76:ac:75:45:1a:71'     # look at this device
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

    # plot samples of all applications
    plt_tsR_vec = np.array(D_tsR_Q)
    plt_sample_head = np.argwhere(plt_tsR_vec > 0)
    plt_sample_tail = np.argwhere(plt_tsR_vec <= plt_tWinLen)
    plt_sample_head_idx = plt_sample_head[0]-1
    plt_sample_tail_idx = plt_sample_tail[-1]                       # get both edge points

    plt_sample = plt_tsR_vec[plt_sample_head_idx[0]:plt_sample_tail_idx[0]]
    plt_sample_len = len(plt_sample)

    pltX = np.linspace(1,plt_sample_len,num=plt_sample_len)
    pltY = plt_sample
    plt.plot(pltX,pltY,markersize=0.5,label=FILENAME)
    plt.xlabel('packet index')
    plt.ylabel('Time duration  (sec)')
plt.legend()
plt.show()

#     #################################################### feature selection ############################################################

#     tWinLen     = 10                                                 # time window length (sec)
#     tWinHead    = 0                                                  # time window head
#     tsLast      = D_tsR_Q[-1]

#     D_tsR_vec   = np.array(D_tsR_Q)
#     # first try
#     avg_diffTsR_list = []
#     std_diffTsR_list = []
#     # second try
#     slope_list = []
#     sqErr_list = []
#     # third try
#     num_pkts_list = []

#     sample_count    = 0
#     while tWinHead < tsLast:
#         tWinTail = tWinHead+tWinLen
#         if tWinTail >= tsLast:
#             tWinTail = tsLast

#         # get all samples within the time window
#         sample_head_tmp = np.argwhere(D_tsR_vec > tWinHead)
#         sample_tail_tmp = np.argwhere(D_tsR_vec <= tWinTail)
#         sample_head_idx = sample_head_tmp[0]-1
#         sample_tail_idx = sample_tail_tmp[-1]                       # get both edge points

#         sample_vec = D_tsR_vec[sample_head_idx[0]:sample_tail_idx[0]]

#         if sample_vec.size == 0:
#             tWinHead = tWinTail
#             continue
#         sample_count = sample_count+1

#         # ### obtain features:
#         # #   as first try, I'm planning to use two features:
#         # #   the mean and std of diff(tstamp) within given
#         # #   time window (say 5 seconds).
#         # #   I use diff(tstamp) as an indicator of network
#         # #   traffic intensity. 
#         # sample_vec_diff = np.diff(sample_vec)
#         # avg_diffTsR_list.append(np.mean(sample_vec_diff))
#         # std_diffTsR_list.append(np.std(sample_vec_diff))

#         # ### obtain features:
#         # #   as second try, I'm planning to use two features:
#         # #   the slope and fit error 
#         # x = np.linspace(1,len(sample_vec),len(sample_vec))
#         # p = np.polyfit(x,sample_vec,1)

#         # fitErr_list = []
#         # for idx in range(len(x)):
#         #     y_meas = sample_vec[idx]
#         #     y_pred = np.polyval(p,x[idx])
#         #     fitErr_list.append(y_pred-y_meas)
#         # fitErr_vec = np.array(fitErr_list)

#         # sqErr_list.append(np.sqrt(np.sum(np.square(fitErr_vec))))
#         # slope_list.append(p[0])

#         ### obtain features:
#         #   simply obtain the number of received pkts within
#         #   given time window. 
#         num_pkts_list.append(len(sample_vec))

#         tWinHead = tWinTail                                         # move to the next window

#     # # first try
#     # avg_diffTsR_vec = np.array(avg_diffTsR_list)
#     # std_diffTsR_vec = np.array(std_diffTsR_list)
#     # dictFeatures = {'diffStd':std_diffTsR_vec,'diffMean':avg_diffTsR_vec}
#     # print('length of mean(diff): ', len(avg_diffTsR_vec))
#     # print('length of std(diff): ', len(std_diffTsR_vec))

#     # # second try
#     # sqErr_vec = np.array(sqErr_list)
#     # slope_vec = np.array(slope_list)
#     # dictFeatures = {'sqErr':sqErr_vec,'slope':slope_vec}  
#     # print('length of sqErr: ', len(sqErr_vec))
#     # print('length of slope: ', len(slope_vec))  

#     # third try
#     num_pkts_vec = np.array(num_pkts_list)
#     dictFeatures = {'numPkts':num_pkts_vec}

#     dictAppFeatures[FILENAME] = dictFeatures

# ## plot features (2D clustering)
# plt_cfg = ['ko','ro','k*','r*','kv','rv','k<']
# plt_count = 0
# for appName in dictAppFeatures:
#     # # first try
#     # mean_diff_vec = dictAppFeatures[appName]['diffMean']
#     # std_diff_vec  = dictAppFeatures[appName]['diffStd']
#     # # second
#     # f_rse = dictAppFeatures[appName]['sqErr']
#     # f_slp = dictAppFeatures[appName]['slope']
#     # third
#     numP = dictAppFeatures[appName]['numPkts']

#     plt_count = plt_count + 1

#     plt.figure()
    
#     plt.plot(numP,np.ones(len(numP)),plt_cfg[plt_count-1],
#                 label=appName,markersize=8.0)
#     plt.xlabel('root squared error')
#     plt.ylabel('slope')

#     plt.legend()
# plt.show()
