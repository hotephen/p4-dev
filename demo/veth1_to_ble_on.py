#!/usr/bin/env python
import sys, time
from bledevice import scanble, BLEDevice

# if len(sys.argv) != 2:
 #   print "Usage: python blecomm.py <ble address>"
 #   print "Scan devices are as follows:"
#    print scanble(timeout=3)
#    sys.exit(1)

def send_pkt(pkt):
    if pkt
        print pkt[1]
        print pkt[2]
        print(type(pkt))
        hm10.writecmd(vh, "y".encode('hex'))

    


hm10 = BLEDevice("A8:10:87:1B:62:B0")
while True:
    vh=hm10.getvaluehandle("ffe1")

    sniff(iface = 'veth4', prn = lambda x: send_pkt(x))
     

