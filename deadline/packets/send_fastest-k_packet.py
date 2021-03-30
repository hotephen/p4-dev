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
parser.add_argument('--num_workers', required=False, type=int, default=0, help='number of workers')
parser.add_argument('--num_packets', required=False, type=int, default=10, help='number of steps')
parser.add_argument('--epoch', required=False, type=int, default=2, help='number of epochs')
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
        BitField("k", 0, 7),
        BitField("end", 0, 1),
        BitField("worker_id", 1, 8),
        BitField("epoch", 1, 16),
        IntField("seg_number", 0),
        BitField("pool_version", 1, 8),
        IntField("pool_index", 1),
    ] 

class ENTRY(Packet):
    name = "ENTRY"
    fields_desc = [
        SignedIntField("value", 0)
    ]

    def guess_payload_class(self, payload):
        return ENTRY


seg_number = 0
count = 0 

for k in (range(args.epoch)):
    seg_number = 0
    pool_version = k%2 + 1
    
    for j in range(args.num_packets):   # The number of packets in one epoch
        pool_index = j*32
        end = 0

        if j == (args.num_packets-1) :  # If last packet in the epoch
            end = 1

        for i in range(args.num_workers): # The number of workers
            
            value = 0
            value_ = 0
            pkt = Ether() / IP(dst="10.10.0.1") / UDP(sport=1234, dport=5678) / frame_type(frame_type=1)/ \
                preamble(end=end, seg_number=seg_number, pool_index=pool_index, pool_version=pool_version)
            if k % 2 == 0:
                for z in range(32):
                    value_ += 1 * 10000000
                    value = value_
                    value = value_ * -1
                    # if count % 2 == 1 :
                    #     value = value_ * -1
                    pkt = pkt / ENTRY(value=value)
            else:
                for z in range(32):
                    value_ += 1 * 10000000
                    value = value_
                    # if count % 2 == 1 :
                    #     value = value_ * -1
                    pkt = pkt / ENTRY(value=value)

            pkt.show()
            print(hexdump(pkt))
            print(len(pkt))
            count += 1
            print(count)
            sendp(pkt, iface = args.i)
        seg_number += 1


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

# ENTRY(value=1) / ENTRY(value=2) / ENTRY(value=3) / ENTRY(value=4) / ENTRY(value=5) / ENTRY(value=6) / \
#                 ENTRY(value=7) / ENTRY(value=8) / ENTRY(value=9) / ENTRY(value=10) / ENTRY(value=11) / ENTRY(value=12) / \
#                 ENTRY(value=7) / ENTRY(value=8) / ENTRY(value=9) / ENTRY(value=10) / ENTRY(value=11) / ENTRY(value=12) / \
#                 ENTRY(value=7) / ENTRY(value=8) / ENTRY(value=9) / ENTRY(value=10) / ENTRY(value=11) / ENTRY(value=12) / \
#                 ENTRY(value=7) / ENTRY(value=8) / ENTRY(value=9) / ENTRY(value=10) / ENTRY(value=11) / ENTRY(value=12) / \
#                 ENTRY(value=7) / ENTRY(value=32)