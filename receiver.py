import socket
import struct
import stat, os

MULTICAST_ADDR = '224.0.0.1'
MULTICAST_PORT = 3000
LISTENER_IP = '192.168.0.47'
LISTENER_PORT = 5000
PIPE="pifone.mp3"

# create socket for message
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
membership = socket.inet_aton(MULTICAST_ADDR)
mreq = struct.pack('4sL', membership, socket.INADDR_ANY)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(('', MULTICAST_PORT))

# create FIFO for netcat
if stat.S_ISFIFO(os.stat(PIPE).st_mode):
    os.mkfifo(PIPE)

def listen_message():
    while 1:
        print 'waiting to receive message'
        message, address = sock.recvfrom(255)
        print 'received %s bytes from %s' % (len(message), address)
        print message

def listen_sound():
    while 1:
        call("netcat -v "+LISTENER_IP+" "+LISTENER_PORT+" > "+PIPE, shell=True)

listen_message()
listen_sound()