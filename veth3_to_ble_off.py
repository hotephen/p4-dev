#!/usr/bin/env python
import sys, time
import struct
from bledevice import scanble, BLEDevice

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import IP,UDP, Raw
from scapy.layers.inet import _IPOption_HDR


# if len(sys.argv) != 2:
 #   print "Usage: python blecomm.py <ble address>"
 #   print "Scan devices are as follows:"
#    print scanble(timeout=3)
#    sys.exit(1)

def send_pkt(pkt):
    if pkt :
        pkt.show()
        print(type(pkt))
        hm10.writecmd(vh, "n".encode('hex'))

    


hm10 = BLEDevice("A8:10:87:1B:62:B0")
while True:
    vh=hm10.getvaluehandle("ffe1")

    sniff(iface = 'veth3',filter="ether dst 02:40:00:08:00:04", prn = lambda x: send_pkt(x))
     

