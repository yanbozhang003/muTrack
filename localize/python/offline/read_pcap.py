from scapy.all import *
import numpy as np
import json

DICT_ALL = {}

traceIdx = '2'
FILENAME = 'youtube'
pkts_AP1 = rdpcap('./data/networkTraffic/trace'+traceIdx+'/'+FILENAME+'.pcap')

for p in pkts_AP1:
    macADDR    = p.payload.addr2
    timeStamp  = float(p.time)
    frmType    = p.payload.type
    frmSubtype = p.payload.subtype

    if macADDR in DICT_ALL:
        pass
    else:
        DICT_ALL[macADDR] = []

    frmDictTmp = {'tstamp': timeStamp,
                  'type': frmType,
                  'subtype': frmSubtype}
    DICT_ALL[macADDR].append(frmDictTmp)

toSaveJson = json.dumps(DICT_ALL)
f = open('./data/networkTraffic/trace'+traceIdx+'/'+FILENAME+'.json','w')
f.write(toSaveJson)
f.close()
