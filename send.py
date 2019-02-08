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

#def get_if():
#    ifs=get_if_list()
#    iface=None # "h1-eth0"
#    for i in get_if_list():
#        if "eth0" in i:
#            iface=i
#            break;
#    if not iface:
#        print "Cannot find eth0 interface"
#        exit(1)
#    return iface

def main():

    if len(sys.argv)<3:
        print 'pass 1 arguments: <destination> '
        exit(1)

#dst addr
    addr = socket.gethostbyname(sys.argv[1])
#src addr
    addr1 = socket.gethostbyname(sys.argv[2])

    iface = "veth0"
    iface_1 = "veth2"
    iface_2 = "veth4"
    nsh = int('0x0000006558000001ff', 16)
    
    pkt =  Ether(src=get_if_hwaddr(iface), dst='00:00:00:00:00:01')
#    pkt = Ether(dst='00:00:00:00:00:02') / pkt / IP(src=addr1,dst=addr) / "hi"
    pkt1 = 'nsh' / pkt / IP(src=addr1,dst=addr) / "hi"
# pkt = pkt /IP(src=addr1,dst=addr) / TCP(dport=1234, sport=random.randint(49152,65535)) / "hi"
#    pkt.show2()
    pkt1.show()
    hexdump(pkt1)
    sendp(pkt1, iface=iface, verbose=False)
    print "sending on interface %s (Bmv2 port 0) to dmac=00:00:00:00:00:01" % (iface)


#    sendp(pkt1, iface=iface_1, verbose=False)
#    print "sending on interface %s (Bmv2 port 1) from Ipv4.srcAddr= %s" % (iface_1, str(addr1))

if __name__ == '__main__':
    main()
