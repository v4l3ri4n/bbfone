import socket
import struct
import stat, os
from subprocess import call

# create socket for message
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
membership = socket.inet_aton(MULTICAST_ADDR)
mreq = struct.pack('4sL', membership, socket.INADDR_ANY)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(('', MULTICAST_PORT))

def listen_message():
    while 1:
        print 'waiting to receive message'
        message, address = sock.recvfrom(255)
        print 'received %s bytes from %s' % (len(message), address)
        print message
        call("amixer sset Master toggle", shell=True)

listen_message()