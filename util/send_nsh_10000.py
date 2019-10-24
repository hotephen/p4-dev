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

"""
usage : send_nsh_10000.py [src] [dst] [interface] [spi] [si] [number of packets]

the 6 arguments are needed
"""

class NSH(Packet):
    """Network Service Header.
       NSH MD-type 1 if there is no ContextHeaders"""
    name = "NSH"

    fields_desc = [
        BitField('Ver', 0, 2),
        BitField('OAM', 0, 1),
        BitField('Un1', 0, 1),
        BitField('TTL', 0, 6),
        BitField('Len', None, 6),
	    BitField('Un4', 1, 4),
        BitField('MDType', 1, 4),
        ByteField("NextProto", 0x65),
        ByteField("NextProto_2", 0x58),
        X3BytesField('SPI', 1),
        ByteField('SI', 255)
    ]

def main():

    if len(sys.argv)<6:
        print '[src] [dst] [interface] [spi] [si] [number of packets]'
        exit(1)

#src addr
    addr = socket.gethostbyname(sys.argv[1])
    addr1 = socket.gethostbyname(sys.argv[2])
    iface = sys.argv[3]
    spi = int(sys.argv[4])
    si = int(sys.argv[5])
    num_pkts = int(sys.argv[6])

    print(addr,
    addr1,
    iface,
    spi,
    si,
    num_pkts)

    
    out_ether = Ether(src=get_if_hwaddr(iface), dst='00:00:00:00:00:01', type=0x894f)
    in_ether =  Ether(src=get_if_hwaddr(iface), dst='00:00:00:00:00:01', type=0x800)

    pkt1 = out_ether / NSH(SPI=spi, SI=si) / in_ether / IP(src=addr,dst=addr1) / "hi"
    pkt1.show()
    hexdump(pkt1)
    
    for i in range(1, num_pkts+1):
        sendp(pkt1, iface=iface, verbose=False)
        print "sending %s th SFC %s packets to interface %s " % (i, spi, iface)


if __name__ == '__main__':
    main()
