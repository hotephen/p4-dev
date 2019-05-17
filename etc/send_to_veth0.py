import serial

import sys
import socket
import random
import struct
from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP
from scapy.all import hexdump

if __name__ == '__main__':
     xbee = serial.Serial()
     xbee.port = '/dev/ttyUSB0'
     xbee.baudrate = 9600
     xbee.timeout = 1
     xbee.writeTimeout = 1
     xbee.open()

while True:
     try:
         data = xbee.readline().strip()
         if data :
                 print data
		 print(type(data))


		 iface = "veth0"
		 sendp(data, iface=iface, verbose=False)
		 print "sending on interface veth0"
     except KeyboardInterrupt:
         break
xbee.close()
