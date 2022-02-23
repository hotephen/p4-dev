#!/usr/bin/env python

import sys
import struct

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr, bind_layers 
from scapy.all import Packet, IPOption
from scapy.all import *
from scapy.layers.inet import _IPOption_HDR
from scapy.all import IP, TCP, UDP, Raw, Ether, Padding
from time import sleep
import argparse


parser = argparse.ArgumentParser(description='send entry packet')
parser.add_argument('--i', required=False, type=str, default='veth0', help='i')
parser.add_argument('--save', required=False, type=bool, default=True, help='save')
parser.add_argument('--show', required=False, type=bool, default=False, help='save')
args = parser.parse_args()

def handle_pkt(pkt):

    if(IP in pkt and (UDP in pkt or TCP in pkt)):
        if (UDP in pkt):
            print(str(pkt[IP].src) + " / " + str(pkt[IP].dst) + " / " + str(pkt[UDP].sport) + " / " + str(pkt[UDP].dport))
        else:
            print(str(pkt[IP].src) + " / " + str(pkt[IP].dst) + " / " + str(pkt[TCP].sport) + " / " + str(pkt[TCP].dport))

def main():
    
    iface = args.i
    print ("sniffing on %s" % iface)
    sys.stdout.flush()

    sniff(iface = iface,
        prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()




