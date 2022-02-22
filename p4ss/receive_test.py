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
parser.add_argument('--i', required=False, type=str, default='veth2', help='i')
a = parser.parse_args()

def handle_pkt(pkt):

    if(IP in pkt and (UDP in pkt or TCP in pkt)):
        print('The number of active flows: ' + str(pkt[IP].id))

def main():
    
    iface = a.i
    print ("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(iface = iface,
          prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()



