#!/usr/bin/env python
import serial

import sys
import socket
import random
import struct
from scapy.all import Packet, Ether, IP, UDP, TCP, hexdump, time, Raw
from scapy.all import sendp, send, sniff

from binascii import hexlify

def send_pkt(pkt):
    hexpkt = hexlify(str(pkt[0]))
    print(hexpkt)
    print(hexpkt[81])
    print(hexpkt[82])
    print(hexpkt[83])

    if hexpkt[83] == "1":
        xbee.write("y")
        print "sending string y"
    if hexpkt[83] == "0":
        xbee.write("n")
        print "sending string n"
        

if __name__ == '__main__':
    xbee = serial.Serial()
    xbee.port = '/dev/ttyUSB1'
    xbee.baudrate = 9600
    xbee.timeout = 1
    xbee.writeTimeout = 1
    xbee.open()
    
    print "xbee complete"

    sniff(iface = 'veth3', filter="ether dst 88:61:00:07:00:00", prn = lambda x: send_pkt(x))
    
xbee.close()
