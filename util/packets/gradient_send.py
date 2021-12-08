#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct

from scapy.all import *
from scapy.all import sendp, send, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP
from scapy.all import hexdump, BitField, BitFieldLenField, ShortEnumField, X3BytesField, ByteField, XByteField, IntField


parser = argparse.ArgumentParser(description='parser')
parser.add_argument('--i', required=False, type=str, default='veth0', help='interface')
parser.add_argument('--c', required=False, type=int, default=0, help='continuous packet transmission')
parser.add_argument('--job_id', required=False, type=int, default=0, help='job id')
parser.add_argument('--src_ip', required=False, type=str, default="10.10.0.1", help='')
parser.add_argument('--dst_ip', required=False, type=str, default="10.10.0.12", help='')

args = parser.parse_args()

"""
usage : send_nsh_10000.py [src] [dst] [interface] [spi] [si] [number of packets]

 6 arguments are needed
"""

class switchml(Packet):
    """ Switchml Header. """
    
    name = "switchml"

    fields_desc = [
        BitField('msg_type', 0, 4),
        BitField('sign_packet_flag', 0, 1),
        BitField('size', 0, 3),
        ByteField('job_id', 0),
        BitField('tsi', 0, 32),
	    XByteField('pool_index', 0),
        BitField('k', 1, 8),
        XByteField("packet_id", 0), # ++
        ByteField("packet_type", 4) # CONSUME0 : 4
    ]

class data(Packet):
    """ data Header. """
    
    name = "data"

    fields_desc = [
        BitField('d00', 0, 32),
        BitField('d01', 0, 32),
        BitField('d02', 0, 32),
        BitField('d03', 0, 32),
        BitField('d04', 0, 32),
        BitField('d05', 0, 32),
        BitField('d06', 0, 32),
        BitField('d07', 0, 32),
        BitField('d08', 0, 32),
        BitField('d09', 0, 32),
        BitField('d10', 0, 32),
        BitField('d11', 0, 32),
        BitField('d12', 0, 32),
        BitField('d13', 0, 32),
        BitField('d14', 0, 32),
        BitField('d15', 0, 32),
        BitField('d16', 0, 32),
        BitField('d17', 0, 32),
        BitField('d18', 0, 32),
        BitField('d19', 0, 32),
        BitField('d20', 0, 32),
        BitField('d21', 0, 32),
        BitField('d22', 0, 32),
        BitField('d23', 0, 32),
        BitField('d24', 0, 32),
        BitField('d25', 0, 32),
        BitField('d26', 0, 32),
        BitField('d27', 0, 32),
        BitField('d28', 0, 32),
        BitField('d29', 0, 32),
        BitField('d30', 0, 32),
        BitField('d31', 0, 32)
    ]

class exponents(Packet):

    name ="exponents"

    fields_desc = [
        BitField('first', 0, 16),
        BitField('second', 0, 16),
    ]



bind_layers(UDP, switchml)
bind_layers(switchml, data)
bind_layers(data, exponents)


def main():


#src addr
    dst_ip = args.dst_ip
    print(type(dst_ip))
    src_ip = args.src_ip
    print(type(src_ip))
    iface = args.i


    # pkt = Ether / IP(src=src_ip, dst=dst_ip) / UDP(dport=48864, sport=20) / switchml / data / data / exponents / sign
    pkt = Ether(src='00:00:00:00:00:00', dst='11:11:11:11:11:11') / IP(src=src_ip, dst=dst_ip) / UDP(dport=48864, sport=20) \
                / switchml() / data() / data() / exponents()
    pkt.show()
    hexdump(pkt)

    sendp(pkt, iface=iface, verbose=False)
    
    if args.c:
        for i in range(1, num_pkts+1):
            pkt_c = pkt
            sendp(pkt_c, iface=iface, verbose=False)
            print "sending %s th packets to interface %s " % (i, iface)


if __name__ == '__main__':
    main()
