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
from kamene.all import *


def main():

    iface = 'veth0'
    sendpkts = []
    pkts = rdpcap("dataset.pcapng")
    print(len(pkts))

    for i in range(len(pkts)):
        
        src_addr = pkts[i][IP].src
        dst_addr = pkts[i][IP].dst
        sport = pkts[i][TCP].sport
        dport = pkts[i][TCP].dport
        pkt = Ether(type=0x800) / IP(src=src_addr,dst=dst_addr) / TCP(sport=sport, dport=dport)
        sendp(pkt, iface=iface, verbose=True)
        
    # print(len(sendpkts))
    # sendp(sendpkts, iface=iface, verbose=True)


if __name__ == '__main__':
    main()

