#!/usr/bin/env python

import sys
import struct

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import IP, UDP, Raw, hexdump, BitField, BitFieldLenField, ShortEnumField, X3BytesField, ByteField, XByteField
from scapy.layers.inet import _IPOption_HDR


sys.path.append("~/p4-dev/util/packets/")
# from send_nsh_manual import NSH

def get_if():
    ifs=get_if_list()
    iface=None
    for i in get_if_list():
        if iface in i:
            iface=i
            break;
    if not iface:
        print("Cannot find %s interface" % (iface))
        exit(1)
    return iface

def handle_pkt(pkt):
    print ("############################## got a packet ##############################")
    pkt.show()
    hexdump(pkt)
    sys.stdout.flush()


def main():
    iface = sys.argv[1]
    print("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(iface = iface,
          prn = lambda x: handle_pkt(x))


if __name__ == '__main__':
    main()