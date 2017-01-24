import socket
import struct
import stat, os
from subprocess import call
import alsaaudio
import threading
from functools import wraps

# create socket for message
MULTICAST_ADDR = '224.0.0.1'
MULTICAST_PORT = 3000
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
membership = socket.inet_aton(MULTICAST_ADDR)
mreq = struct.pack('4sL', membership, socket.INADDR_ANY)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(('', MULTICAST_PORT))

# First find a mixer. Use the first one.
try :
    mixer = alsaaudio.Mixer('Softmaster', 0)
except alsaaudio.ALSAAudioError :
    sys.stderr.write("No such mixer\n")
    sys.exit(1)

# Decorator delaying the execution of a function for a while.
def delay(delay=0.):
    def wrap(f):
        @wraps(f)
        def delayed(*args, **kwargs):
            timer = threading.Timer(delay, f, args=args, kwargs=kwargs)
            timer.start()
        return delayed
    return wrap

#  socket listener
def listen_message():
    while 1:
        print 'waiting to receive message'
        message, address = sock.recvfrom(255)
        print 'received %s bytes from %s' % (len(message), address)
        print message
        vol = mixer.getvolume()[0]
        if vol <= 0:
            mixer.setvolume(100) # set volume up
            lower_volume() # set volume down after 300 seconds (5 mins)

@delay(300.0)
def lower_volume():
    mixer.setvolume(0)
    
listen_message()