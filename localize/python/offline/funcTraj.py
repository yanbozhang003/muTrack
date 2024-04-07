import numpy as np

mapScale = 1/100                                           # 100 grid is 1 m

def up_sampling(turnPtVec):
    space_sample_rate = 1/100.0                              # 100 samples for each meter

    locs_x_Q = np.array([])
    locs_y_Q = np.array([])

    num_turnPts,num_axis = turnPtVec.shape

    for idx in range(num_turnPts-1):
        x1 = turnPtVec[idx,0]
        y1 = turnPtVec[idx,1]
        x2 = turnPtVec[idx+1,0]
        y2 = turnPtVec[idx+1,1]

        pt1 = turnPtVec[idx,:]
        pt2 = turnPtVec[idx+1,:]

        dist_turnPts = np.linalg.norm(pt1-pt2)
        num_sample_add = int(np.floor(dist_turnPts/space_sample_rate))

        locs_x_Q_add = np.linspace(x1,x2,num=num_sample_add)
        locs_y_Q_add = np.linspace(y1,y2,num=num_sample_add)

        locs_x_Q = np.append(locs_x_Q,locs_x_Q_add)
        locs_y_Q = np.append(locs_y_Q,locs_y_Q_add)

    locs_upsampled = np.zeros((2,len(locs_x_Q)))                          # ((x,y),samples)
    locs_upsampled[0,:] = locs_x_Q
    locs_upsampled[1,:] = locs_y_Q

    return locs_upsampled

def alloc_tstamp(loc_samples,speed):
    num_axis,num_samples = loc_samples.shape
    tsVec = np.zeros((num_samples,1))

    ts_head = 0.0
    for idx in range(num_samples):
        if idx == 0:
            tsVec[idx] = ts_head
        else:
            loc_prev = loc_samples[:,idx-1]
            loc_cur  = loc_samples[:,idx]

            dist_prev_cur = np.linalg.norm(loc_prev-loc_cur)
            delta_ts = dist_prev_cur/speed
            tsVec[idx] = tsVec[idx-1]+delta_ts
    
    return tsVec

def get_loc_samples(D_idx):
    
    speed_D1 = 0.5                                         # 0.9 m/s

    traj_D1_turnPt = np.array([[270,120],[270,350],[610,350],[610,250],[830,250],[830,120]])

    loc_samples = up_sampling(traj_D1_turnPt*mapScale)

    ts_samples = alloc_tstamp(loc_samples,speed_D1)
    
    return loc_samples,ts_samples
