#!/usr/bin/env python

# option
# <src_ip> | <dst_ip> | <interface> | <vdp_id>

import argparse
import sys
import socket
import random
import struct

from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP
from scapy.all import hexdump, BitField, BitFieldLenField, ShortEnumField, X3BytesField, ByteField, XByteField

class DH(Packet):
    """Description Header"""
       
    name = "DH"

    fields_desc = [
        BitField('flag',0, 8),
        BitField('len',0, 8),
        BitField('vdp_id',0, 16)
   ]

def main():



    addr = socket.gethostbyname(sys.argv[1])
    addr1 = socket.gethostbyname(sys.argv[2])
    iface = sys.argv[3]
    vdp_id = int(sys.argv[4])
   
    ether =  Ether(src=get_if_hwaddr(iface), dst='00:00:00:00:00:01', type=0x800)
    pkt = DH(vdp_id=vdp_id) / ether / IP(src=addr,dst=addr1) / "hi"
    pkt.show()
    hexdump(pkt)
    sendp(pkt, iface=iface, verbose=False)
    print "sending on interface %s to dmac=00:00:00:00:00:01" % (iface)


if __name__ == '__main__':
    main()

#usage 