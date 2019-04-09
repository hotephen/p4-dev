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

#src addr
    addr = socket.gethostbyname(sys.argv[1])
#dst addr
    addr1 = socket.gethostbyname(sys.argv[2])

    iface = "veth0"
      
    pkt =  Ether(src=get_if_hwaddr(iface), dst='80:00:00:00:00:01', type=0x800)
    pkt1 = pkt / IP(src=addr,dst=addr1) / "hi"
    pkt1.show()
    hexdump(pkt1) # show hexadecimal expression of packet
    sendp(pkt1, iface=iface, verbose=False)
    print "sending on interface %s " % (iface)


if __name__ == '__main__':
    main()


# ./send.py dst src
