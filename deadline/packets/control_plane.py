#!/usr/bin/env python

import sys
import struct

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr, bind_layers 
from scapy.all import Packet, IPOption
from scapy.all import IP, UDP, Raw, hexdump, BitField, BitFieldLenField, ShortEnumField, X3BytesField, ByteField, XByteField, IntField
from scapy.layers.inet import _IPOption_HDR
from scapy.all import IP, TCP, UDP, Raw, Ether, Padding
from time import sleep
import argparse


parser = argparse.ArgumentParser(description='send entry packet')
parser.add_argument('--i', required=False, type=str, default='veth0', help='i')
a = parser.parse_args()
iface = a.i

class frame_type(Packet):
    """ Frame_type Header """
    name = "frame_type"
    fields_desc = [
        BitField("frame_type", 0, 8),
        BitField("switch_id", 0, 8),
    ] 

class preamble(Packet):
    """ preamble Header """
    name = "preamble"
    fields_desc = [
        IntField("number_of_entries", 10),
        IntField("seg_number", 0),
    ] 

bind_layers(UDP,frame_type)
bind_layers(frame_type,preamble)


def get_if():
    ifs=get_if_list()
    iface=None
    for i in get_if_list():
        if iface in i:
            iface=i
            break;
    if not iface:
        print ("Cannot find %s interface" % (iface))
        exit(1)
    return iface

def handle_pkt(pkt):
    pkt.show()
    hexdump(pkt)
    # print ("############################## got a packet ##############################")
    try:
        if pkt[IP].dst == '10.10.0.1': ##
        # if pkt[frame_type].frame_type == 3: # if timer packet
            print("got a packet")
            pkt.show()
            # sleep(1)
            sendp(pkt, iface=a.i, verbose=False)
    
    except IndexError:
        # print('IndexError')
        pass
        

def main():
    print ("sniffing on %s" % iface)

    sys.stdout.flush()
    sniff(iface = iface,
          prn = lambda x: handle_pkt(x))
    



if __name__ == '__main__':
    main()


# sudo python ~/p4-dev/deadline/packets/control_plane.py -i veth4