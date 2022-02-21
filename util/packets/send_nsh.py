#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct

from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP
from scapy.all import hexdump, BitField, BitFieldLenField, ShortEnumField, X3BytesField, ByteField, XByteField

# src / dst / veth
# SPI = 1 / SI = 255


class weightwriting(Packet):
    """Network Service Header.
       NSH MD-type 1 if there is no ContextHeaders"""
    name = "weightwriting"

    fields_desc = [
		BitField("index", 1, 32),
		BitField("weight", 10, 120)
    ]

def main():

    if len(sys.argv)<3:
        print 'pass 1 arguments: <destination> '
        exit(1)

#src addr
    addr = socket.gethostbyname(sys.argv[1])

#dst addr
    addr1 = socket.gethostbyname(sys.argv[2])

    iface = sys.argv[3]

    
#   out_ether = Ether(src=get_if_hwaddr(iface), dst='00:00:00:00:00:01', type=0x894f)
#   in_ether =  Ether(src=get_if_hwaddr(iface), dst='00:00:00:00:00:01', type=0x800)

# pkt1 = Ether() / IP(src=addr,dst=addr1) / weightwriting() / TCP(dport=80, sport=20) / "hi"
#   pkt1.show()
# hexdump(pkt1)
#sendp(pkt1, iface=iface, verbose=False)
    print "sending on interface %s (Bmv2 port 0) to dmac=00:00:00:00:00:01" % (iface)

    for i in range(0,120):
        pkt = Ether() / IP() / weightwriting(index=i, weight=1) / UDP() 
        pkt.show()
        pkt.hexdump()
        sendp(pkt, iface=iface, verbose=False)

if __name__ == '__main__':
    main()

#sudo python sedn.py 
