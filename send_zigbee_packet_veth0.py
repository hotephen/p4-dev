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

    if len(sys.argv)<3:
        print 'pass 1 arguments: <destination> '
        exit(1)


    iface = "veth0"
      
    pkt = "0x88610007000000011a88000000010a00000fff00001b1bdf000fff00001fe9c140010006010401033000000000000000" 
    pkt.show()
    hexdump(pkt) # show hexadecimal expression of packet
    sendp(pkt, iface=iface verbose=False)
    print "sending on interface %s to dmac=00:00:00:00:00:01" % (iface)


if __name__ == '__main__':
    main()

