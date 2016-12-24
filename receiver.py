import socket
import struct

multicast_addr = '224.0.0.1'
port = 3000

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
membership = socket.inet_aton(multicast_addr)
mreq = struct.pack('4sL', membership, socket.INADDR_ANY)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

sock.bind(('', port))

while True:
    print 'waiting to receive message'
    message, address = sock.recvfrom(255)
    print 'received %s bytes from %s' % (len(message), address)
    print message
	