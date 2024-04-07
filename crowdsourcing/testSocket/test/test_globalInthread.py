
import threading
import time

a = 0
b = 0

class thread1(threading.Thread):
    def __init__(self, ):
        threading.Thread.__init__(self)

    def run(self):
        global a
        while True: 
            a += 1
            print('a within thread: ', a)
            time.sleep(2)
            
            
while True:
    thread_test = thread1()
    thread_test.start()
    print('a outside thread: ', a)