import matlab.engine
eng = matlab.engine.start_matlab()
ret = eng.triarea(2.0,5.0)   #sending input to the function
print("Triarea : ")
print(ret)
