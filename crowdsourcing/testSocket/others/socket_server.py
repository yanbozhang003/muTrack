# first of all import the socket library 
import socket		
import numpy as np

queue = []
queue_len = 30

# next create a socket object 
s = socket.socket()		 
print("Socket successfully created")

s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

# reserve a port on your computer in our 
# case it is 12345 but it can be anything 
port = 8080				

# Next bind to the port 
# we have not typed any ip in the ip field 
# instead we have inputted an empty string 
# this makes the server listen to requests 
# coming from other computers on the network 
s.bind(('', port))		 
print("socket binded to %s" %(port) )

# put the socket into listening mode 
s.listen(5)	 
print("socket is listening")			

# Establish connection with client. 
conn, addr = s.accept()	 
print('Got connection from', addr)

# a forever loop until we interrupt it or 
# an error occurs 
while True: 
    data = conn.recv(4096)
    queue.append(data)
    if len(queue) == queue_len:
        break
    # send a thank you message to the client. 
    #conn.send(data) 

    # Close the connection with the client 
    #conn.close() 

np.savez("data",queue)