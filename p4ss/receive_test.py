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
parser.add_argument('--save', required=False, type=bool, default=True, help='save')
parser.add_argument('--show', required=False, type=bool, default=False, help='save')
args = parser.parse_args()

def handle_pkt(pkt,f):

    if(IP in pkt and (UDP in pkt or TCP in pkt)):
        f.write(str(pkt[IP].id) + '\n')
        if(args.show==1):
            
            if( str(pkt[IP].version) == '1'):
                on_off = "on"
            else:
                on_off = "off"

            if( str(pkt[IP].ihl) == '1'):
                long_short = "long"
            else:
                long_short = "short"

            # if( str(pkt[IP].tos) == 1):
            #     high_low = "high"
            # elif( str(pkt[IP].tos) == 2 ):
            #     high_low = "low"

            print('The number of active flows: ' + str(pkt[IP].id) 
                + " / " + on_off + " / " + long_short + " / "
                + "queue : " + str(pkt[IP].tos))



def main():
    
    iface = args.i
    print ("sniffing on %s" % iface)
    sys.stdout.flush()

    if(args.save == True):
        with open('bf_result.txt', 'w') as f:
            sniff(iface = iface,
                prn = lambda x: handle_pkt(x,f))

if __name__ == '__main__':
    main()




