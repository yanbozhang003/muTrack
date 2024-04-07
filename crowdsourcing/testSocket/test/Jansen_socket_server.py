#! python3

import mysql.connector
import requests
import signal
import socket
import struct
import sys
from decimal import Decimal
from threading import Thread

PacketQueue = []

class PacketThread(Thread):
    def __init__(self):
        global PacketQueue
        super(PacketThread, self).__init__()

class PacketManager(Thread):
    def __init__(self):
        global PacketQueue
        super(PacketManager, self).__init__()

class ClientThread(Thread):
    def __init__(self, conn, ip, port):
        super(ClientThread, self).__init__()
        self.ip = ip
        self.port = port
        self.digest = PacketDigester()
        self.dbhost = 'giot.csaobbk4sgwj.ap-southeast-1.rds.amazonaws.com'
        self.dbuser = 'go_iot'
        self.dbpass = 'go-iot-sql'
        self.dbschema = 'iot'
        print('[sys]', str(ip) + ':' + str(port), 'joined')

    def run(self):
        while True:
            data = conn.recv(2048).decode().strip()
            if 'gw_ready' in data:
                print('[client]', ip, 'ready')
                conn.send('gw_start'.encode())
            else:
                if '00 #' in data and 'CRC_OK' in data:
                    try:
                        db = mysql.connector.connect(host=self.dbhost, user=self.dbuser, passwd=self.dbpass, database=self.dbschema)
                        dbcursor = db.cursor()
                        result = self.digest.eat(data, dbcursor, db)
                        dbcursor.close()
                        db.close()
                        conn.send(result.encode())    
                    except:
                        #print('[error]', 'skipped data', data)
                        conn.send('ERR'.encode())
                else:
                    if data != '':
                        #print('[sys]', data)
                        if 'exit' in data:
                            conn.close()
                            break
                    conn.send('ERR'.encode())

def handler(sig, frame):
    for t in threads:
        t.conn.close()
    SERVER.close()
    print('[exit]', 'exiting program')
    sys.exit(0)


#signal.signal(signal.SIGINT, handler)
#signal.signal(signal.SIGTERM, handler)

SERVER_IP = '0.0.0.0'
SERVER_PORT = 56100
BUFFER_SIZE = 20

SERVER = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
SERVER.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
try:
    SERVER.bind((SERVER_IP, SERVER_PORT))
    SERVER.listen(10)
    print('[sys]', 'server started')
except socket.error as err:
    print('[error]', err)
    sys.exit(0)
    
threads = []

while True:
    (conn, (ip, port)) = SERVER.accept()
    newthread = ClientThread(conn, ip, port)
    newthread.start()
    threads.append(newthread)

for t in threads:
    t.join()
