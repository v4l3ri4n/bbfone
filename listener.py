import time
import RPi.GPIO as GPIO
import socket
import struct
import sys

# sound sensor setup
GPIO.setmode(GPIO.BOARD)
pin = 7
GPIO.setup(pin, GPIO.IN)

# multicast setup
MULTICAST_ADDR = '224.0.0.1'
MULTICAST_PORT = 3000
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
ttl = struct.pack('b', 1)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_MULTICAST_TTL, ttl)

# mic setup
DEVICE = "plughw:1,0"
NETCATPORT = "5000"

# send sound over network
def diffuse_sound():
    while 1:
        call("arecord -f cd -D "+DEVICE+" | netcat -v -l -p "+NETCATPORT, shell=True)

def send_message():
	sock.sendto("sound_detected", (MULTICAST_ADDR, MULTICAST_PORT))

def check_noise():
	while GPIO.input(pin) == GPIO.HIGH:
		time.sleep(0.01) # wait 10 ms to give CPU chance to do other things
	print("sound detected")
	send_message()
	time.sleep(10)
	check_noise()
	
check_noise()
diffuse_sound()