#!/usr/bin/env python

# USAGE: send_daiet_packet.py iface number_of_packets
# python send_daiet.py veth0 1
import argparse
import sys
from scapy.all import *
# from headers import *
from scapy.layers.l2 import Ether
from scapy.layers.inet import IP, UDP

parser = argparse.ArgumentParser(description='parser')
parser.add_argument('--seg', required=False, type=int, default=1, help='seg_number')
parser.add_argument('--i', required=False, type=str, default='veth0', help='i')
parser.add_argument('--num', required=False, type=int, default=0, help='number of packets')
args = parser.parse_args()


class frame_type(Packet):
    """ Frame_type Header """
    name = "frame_type"
    fields_desc = [
        BitField("frame_type", 0, 8),
        BitField("switch_id", 1, 8),
    ] 

class preamble(Packet):
    """ preamble Header """
    name = "preamble"
    fields_desc = [
        IntField("number_of_entries", 10),
        IntField("seg_number", 0),
    ] 

class ENTRY(Packet):
    name = "ENTRY"
    fields_desc = [ StrFixedLenField("key", 0, 4),
                    IntField("value", 0)]

    def guess_payload_class(self, payload):
        return ENTRY






for i in range(args.num):
    data1 = Ether() / IP(dst="10.10.0.1") / UDP(sport=1234, dport=5678) / frame_type(frame_type=1) / preamble(number_of_entries=9,seg_number=args.seg) / ENTRY(key=1,value=1) / ENTRY(key="b",value=2) / ENTRY(key="c",value=3) / ENTRY(key="d",value=4)/ ENTRY(key="d",value=5) / ENTRY(key="d",value=6) / ENTRY(key="d",value=7) / ENTRY(key="d",value=8) / ENTRY(key="d",value=9) / ENTRY(key="d",value=10)
    sendp(data1, iface = args.i)


# data1 = Ether(dst=MACS[sys.argv[2]]) / IP(dst="10.10.0.1") / UDP(dport=10000) / PREAMBLE(number_of_entries=4,seg_number=1) / ENTRY(key=1,value=1) / ENTRY(key="b",value=2) / ENTRY(key="c",value=3) / ENTRY(key="d",value=4)/ ENTRY(key="d",value=5) / ENTRY(key="d",value=6) / ENTRY(key="d",value=7) / ENTRY(key="d",value=8) / ENTRY(key="d",value=9) / ENTRY(key="d",value=10)

# data2 = Ether(dst=MACS[sys.argv[2]]) / IP(dst="10.0.1.10") / UDP(dport=10000) / PREAMBLE(number_of_entries=2,tree_id=2) / ENTRY(key='AA',value=5) / ENTRY(key="BB",value=6) 

# for i in range(int(sys.argv[3])):
#     sendp(data2, iface = sys.argv[1])

# PACKET TO SKIP
# data1 = Ether(dst="aa:aa:aa:aa:aa:aa") / IP(dst="10.0.1.10") / UDP(dport=10000) / PREAMBLE(number_of_entries=4,tree_id=151) / ENTRY(key='a',value=10) / ENTRY(key="b",value=20) / ENTRY(key="c",value=30) / ENTRY(key="d",value=40) 
# sendp(data1, iface = sys.argv[1])

# data1 = Ether(dst=MACS[sys.argv[2]]) / IP(dst="10.0.1.10") / UDP(dport=10000) / PREAMBLE(number_of_entries=4,tree_id=3) / ENTRY(key='a',value=10) / ENTRY(key="b",value=20) / ENTRY(key="c",value=30) / ENTRY(key="d",value=40) 

# data2 = Ether(dst=MACS[sys.argv[2]]) / IP(dst="10.0.1.10") / UDP(dport=10000) / PREAMBLE(number_of_entries=2,tree_id=4) / ENTRY(key='AA',value=50) / ENTRY(key="BB",value=60) 

# for i in range(int(sys.argv[3])):
#     sendp(data1, iface = sys.argv[1])

# for i in range(int(sys.argv[3])):
#     sendp(data2, iface = sys.argv[1])

# END
# for i in range(int(sys.argv[4])):
#     end = Ether(dst=MACS[sys.argv[2]]) / IP(dst="10.0.1.10") / UDP(dport=10000) / END (tree_id=7)
#     sendp(end, iface = sys.argv[1])
    # end = Ether(dst=MACS[sys.argv[2]]) / IP(dst="10.0.1.10") / UDP(dport=10000) / END (tree_id=8)
    # sendp(end, iface = sys.argv[1])