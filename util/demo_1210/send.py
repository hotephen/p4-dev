#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct

from scapy.all import sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP
from scapy.all import hexdump, BitField, BitFieldLenField, ShortEnumField, X3BytesField, ByteField, XByteField

parser = argparse.ArgumentParser(description='send dh packet')
parser.add_argument('vid', type=int, help='VDP ID')
parser.add_argument('--sm', required=False, default='00:00:00:00:00:01', help='source MAC address')
parser.add_argument('--dm', required=False, default='00:00:00:00:00:02', help='destination MAC address')
parser.add_argument('--si', required=False, default='10.0.0.1', help='source IP address')
parser.add_argument('--di', required=False, default='10.0.0.2', help='destination IP address')
parser.add_argument('--sp', required=False, type=int, default=1234, help='source PORT number')
parser.add_argument('--dp', required=False, type=int, default=5678, help='destination PORT number')

class desc_hdr(Packet):
    """Description Header"""
    name = "desc_hdr"
    fields_desc = [
        BitField('flag', 0, 8),
        BitField('len', 0, 8),
        BitField('vdp_id', 0, 16)
    ]
class arp(Packet):
    """ARP Header"""
    name = "arp"
    fields_desc = [
        BitField('hw_type', 0, 16),
        BitField('prot_type', 0, 16),
        BitField('hw_size', 0, 8),
        BitField('prot_size', 0, 8),
        BitField('opcode', 0, 16),
        BitField('sender_MAC', 0, 48),
        BitField('sender_IP', 0, 32),
        BitField('target_MAC', 0, 48),
        BitField('target_IP', 0, 32)
    ]

def macToN(addr):
    v = addr.split(':')
    return long(v[0],16) * 1099511627776 + long(v[1],16) * 4294967296 + long(v[2],16) * 16777216 + long(v[3],16) * 65536 + long(v[4],16) * 256 + long(v[5],16)
def ipToN(addr):
    v = addr.split('.')
    return long(v[0]) * 16777216 + long(v[1]) * 65536 + long(v[2]) * 256 + long(v[3])

def main():
    a = parser.parse_args()

    iface = "veth1"
    global pkt1, pkt2, pkt3_1, pkt3_2, pkt4
    global pkt
  
    print('\n---------- Send pakcet with vdp_id : %d ----------' % a.vid)
    if a.vid == 1:
        pkt = desc_hdr(vdp_id=a.vid) / Ether(src=a.sm, dst=a.dm) / arp(opcode=1, sender_MAC=macToN(a.sm), sender_IP=ipToN(a.si), target_MAC=macToN(a.dm), target_IP=ipToN(a.di))
        print("srcMAC = " + a.sm + "\tdstMAC = " + a.dm)
        print("\t-- [ arp information ] --")
        print("\tsdrMAC = " + a.sm + "\ttgtMAC = " + a.dm)
        print("\tsdrIP = " + a.si + "\t\ttgtIP = " + a.di)
    else:
        pkt = desc_hdr(vdp_id=a.vid) / Ether(src=a.sm, dst=a.dm) / IP(src=a.si, dst=a.di) / TCP(sport=a.sp, dport=a.dp)
        print("srcMAC = " + a.sm + "\tdstMAC = " + a.dm)
        print("srcIP = " + a.si + "\t\tdstIP = " + a.di)
        print("srcPORT = " + str(a.sp) + "\t\t\tdstPORT = " + str(a.dp))

    print
    sendp(pkt, iface=iface, verbose=False)

if __name__ == '__main__':
    main()
