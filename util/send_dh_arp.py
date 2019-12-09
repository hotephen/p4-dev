#!/usr/bin/env python


# <src_mac>

import argparse
import sys
import socket
import random
import struct

from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP, ARP
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
    
    src_mac = sys.argv[1]
    src_addr = socket.gethostbyname(sys.argv[2])
    dst_addr = socket.gethostbyname(sys.argv[3])
    iface = sys.argv[4]
    vdp_id = int(sys.argv[5])


    ether =  Ether(src=src_mac, dst="FF:FF:FF:FF:FF:FF", type=0x0806)
    pkt = DH(vdp_id=vdp_id) / ether / ARP(op=1,hwsrc=src_mac, psrc=src_addr, pdst=dst_addr) 
    pkt.show()
    hexdump(pkt)
    sendp(pkt, iface=iface, verbose=False)
    print("sending on interface %s to dmac=00:00:00:00:00:01" % (iface))


if __name__ == '__main__':
    main()

#usage 
""" parser = argparse.ArgumentParser(description='parsing')
    parser.add_argument("--src_mac", help="src MAC address", default="00:00:00:00:00:01")
    parser.add_argument("--dst_mac", help="dst MAC address", default="00:00:00:00:00:02")
    parser.add_argument("--src_port", help="src Port", default=1234)
    parser.add_argument("--dst_port", help="dst Port", default=1234)
    args = parser.parse_args()
    """