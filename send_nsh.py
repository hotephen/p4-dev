#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct

from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP
from scapy.all import hexdump, BitField, BitFieldLenField, ShortEnumField, X3BytesField, ByteField, XShortField

from binascii import hexlify

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
	    BitField('Un2', 0, 4),
        BitField('MDType', 1, 4),
        XShortField('NextProto', 0x6558),
        X3BytesField('SPI', 1),
        ByteField('SI', 255)
    ]

def main():

    if len(sys.argv)<2:
        print '<src> <dst> <SPI> <SI>'
        exit(1)

#src addr
    addr = socket.gethostbyname(sys.argv[1])
#dst addr
    addr1 = socket.gethostbyname(sys.argv[2])
#    spi = sys.argv[3]
#    si = sys.argv[4]
    
    iface = "veth0"

    pkt1 = Ether(type=0x894f) / NSH() / Ether(type=0x0800) / IP(src=addr,dst=addr1) / "hi"

    pkt1.show()
    hexdump(pkt1)
    sendp(pkt1, iface=iface, verbose=False)
    print "sending on interface %s (bmv2 port 0)" % (iface)



if __name__ == '__main__':
    main()
