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

    iface = 'veth0'
    src_addr = '0.0.0.1'
    dst_addr = '0.0.0.2'

    # pkt =  Ether(src='00:00:00:00:00:00', dst='00:00:00:00:00:01', type=0x800)
    for i in range(20):
        pkt = Ether(type=0x800) / IP(src=src_addr,dst=dst_addr) / TCP(dport=0, sport=0)

    # test case A
        j = i%10
        pkt = Ether(type=0x800) / IP(src=src_addr,dst=dst_addr) / TCP(dport=j, sport=j)
        # print(j)

    # test case B
        # if (0 <= i < 2):
        #     pkt = Ether(type=0x800) / IP(src=src_addr,dst=dst_addr) / TCP(dport=0, sport=0)
        # if (2 <= i < 4):
        #     pkt = Ether(type=0x800) / IP(src=src_addr,dst=dst_addr) / TCP(dport=1, sport=1)
        # if (4 <= i < 6):
        #     pkt = Ether(type=0x800) / IP(src=src_addr,dst=dst_addr) / TCP(dport=2, sport=2)

    # test case C
        # pkt = Ether(type=0x800) / IP(src=src_addr,dst=dst_addr) / TCP(dport=i, sport=i)


        # # elif (i<8):
        # #     pkt = Ether(type=0x800) / IP(src=src_addr,dst=dst_addr) / TCP(dport=0, sport=0)
        # # elif (i<12):
        # #     pkt = Ether(type=0x800) / IP(src=src_addr,dst=dst_addr) / TCP(dport=i, sport=i)
        # else:
        #     pkt = Ether(type=0x800) / IP(src=src_addr,dst=dst_addr) / TCP(dport=0, sport=0)



        # pkt.show()
        # hexdump(pkt) # show hexadecimal expression of packet
        sendp(pkt, iface=iface, verbose=False)


if __name__ == '__main__':
    main()


# usage : python send.py src dst veth
