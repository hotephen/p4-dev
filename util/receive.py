#!/usr/bin/env python

import sys
import struct

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import IP, UDP, Raw
from scapy.layers.inet import _IPOption_HDR


#sys.path.append("~/p4-dev/util")
#from send_nsh_manual import NSH

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

def get_if():
    ifs=get_if_list()
    iface=None
    for i in get_if_list():
        if iface in i:
            iface=i
            break;
    if not iface:
        print "Cannot find %s interface" % (iface)
        exit(1)
    return iface

def handle_pkt(pkt):
    print "##############################got a packet##############################"
    pkt.show()
    hexdump(pkt)
    sys.stdout.flush()


def main():
    iface = sys.argv[1]
    print "sniffing on %s" % iface
    sys.stdout.flush()
    sniff(iface = iface,
          prn = lambda x: handle_pkt(x))


if __name__ == '__main__':
    main()