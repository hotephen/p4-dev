#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct

from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP
from scapy.all import hexdump

def main():

    iface = "veth0"
    
    pkt =  Ether(src=get_if_hwaddr(iface), dst='00:00:00:00:00:01', type=0x800)
    pkt.show()
    hexdump(pkt) # show hexadecimal expression of packet
    sendp(pkt, iface=iface, verbose=False)
    print "sending on interface %s to dmac=00:00:00:00:00:01" % (iface)


if __name__ == '__main__':
    main()
