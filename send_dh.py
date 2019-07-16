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

#def get_if():
#    ifs=get_if_list()
#    iface=None # "h1-eth0"
#    for i in get_if_list():
#        if "eth0" in i:
#            iface=i
#            break;
#    if not iface:
#        print "Cannot find eth0 interface"
#        exit(1)
#    return iface

class DH(Packet):
    """Description Header"""
       
    name = "DH"

    fields_desc = [
        BitField('field1',0, 8),
        BitField('field2',0, 8),
        BitField('field3',0, 8),
        BitField('field4',0, 8)
   ]

def main():


#src addr
    addr = socket.gethostbyname(sys.argv[1])

#dst addr
    addr1 = socket.gethostbyname(sys.argv[2])

    iface = sys.argv[3]

   
    out_ether = Ether(src=get_if_hwaddr(iface), dst='00:00:00:00:00:01', type=0x894f)
    in_ether =  Ether(src=get_if_hwaddr(iface), dst='00:00:00:00:00:01', type=0x800)

    pkt1 = DH() / in_ether / IP(src=addr,dst=addr1) / "hi"
    pkt1.show()
    hexdump(pkt1)
    sendp(pkt1, iface=iface, verbose=False)
    print "sending on interface %s to dmac=00:00:00:00:00:01" % (iface)


if __name__ == '__main__':
    main()
