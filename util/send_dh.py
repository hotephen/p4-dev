#!/usr/bin/env python

# option
# <src_ip> | <dst_ip> | <interface> | <vdp_id> | src_mac | dst_mac | src_port | dst_port 

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

    src_addr = socket.gethostbyname(sys.argv[1])
    dst_addr = socket.gethostbyname(sys.argv[2])
    iface = sys.argv[3]
    vdp_id = int(sys.argv[4])
    src_mac = sys.argv[5]
    dst_mac = sys.argv[6]
    src_port = int(sys.argv[7])
    dst_port = int(sys.argv[8])


    """ parser = argparse.ArgumentParser(description='parsing')
    parser.add_argument("--src_mac", help="src MAC address", default="00:00:00:00:00:01")
    parser.add_argument("--dst_mac", help="dst MAC address", default="00:00:00:00:00:02")
    parser.add_argument("--src_port", help="src Port", default=1234)
    parser.add_argument("--dst_port", help="dst Port", default=1234)
    args = parser.parse_args()
    """
    
    ether =  Ether(src=src_mac, dst='00:00:00:00:00:01', type=0x800)
    pkt = DH(vdp_id=vdp_id) / ether / IP(src=src_addr,dst=dst_addr) / TCP(sport=src_port , dport=dst_port) /"hi"
    pkt.show()
    hexdump(pkt)
    sendp(pkt, iface=iface, verbose=False)
    print("sending on interface %s to dmac=00:00:00:00:00:01" % (iface))


if __name__ == '__main__':
    main()

#usage 