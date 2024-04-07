import matlab.engine
import numpy as np

eng = matlab.engine.start_matlab()
eng.addpath(r'/home/project6/work/muTrack/test')
# eng.ls(nargout=0)
# arr = np.random.rand(3,2)
# arr = matlab.double(arr)
arr_1 = np.random.rand(3,2)
# arr = [[1.0,2.0,3.0],[1.0,2.0,3.0]]
arr = arr_1.tolist()
arr_pass = matlab.double(arr)
ret_arr = eng.passByArray(arr_pass)
print(arr)
print(ret_arr)