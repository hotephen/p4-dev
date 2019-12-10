#!/usr/bin/env python
import sys
import struct
import os

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Packet, IPOption
from scapy.all import ShortField, IntField, LongField, BitField, FieldListField, FieldLenField
from scapy.all import IP, TCP, UDP, Raw, Ether, Padding
from scapy.layers.inet import _IPOption_HDR

host = 0

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

def get_if():
    ifs=get_if_list()
    iface=None
    for i in get_if_list():
        if "p4p2" in i:
            iface=i
            break;
    if not iface:
        print "Cannot find p4p2 interface"
        exit(1)
    return iface

def handle_pkt(pkt):
    #hexdump(pkt)
    b = map(ord, str(pkt))
    vid = b[2] * 256 + b[3]    
    dstMAC="%02X:%02X:%02X:%02X:%02X:%02X" % (b[4], b[5], b[6], b[7], b[8], b[9])
    srcMAC="%02X:%02X:%02X:%02X:%02X:%02X" % (b[10], b[11], b[12], b[13], b[14], b[15])
    srcIP="%d.%d.%d.%d" %(b[30], b[31], b[32], b[33])
    dstIP="%d.%d.%d.%d" %(b[34], b[35], b[36], b[37])
    
       
    if vid == 4:
        if dstMAC == "FF:FF:FF:FF:FF:FF" :
            pass
        else :
            print('\n----- Host%d received packet with vdp_id %d' % (host, vid))
            sdrMAC="%02X:%02X:%02X:%02X:%02X:%02X" % (b[26], b[27], b[28], b[29], b[30], b[31])   
            sdrIP="%d.%d.%d.%d" %(b[32], b[33], b[34], b[35])
            tgtMAC="%02X:%02X:%02X:%02X:%02X:%02X" % (b[36], b[37], b[38], b[39], b[40], b[41])   
            tgtIP="%d.%d.%d.%d" %(b[42], b[43], b[44], b[45])
            print("srcMAC = " + srcMAC + "\tdstMAC = " + dstMAC)
            print("\t-- [ arp information ] --")
            print("sdrMAC = " + sdrMAC + "\ttgtMAC = " + tgtMAC)
            print("sdrIP = " + sdrIP + "\t\ttgtIP = " + tgtIP)
    else:
        print('\n----- Host%d received packet with vdp_id %d' % (host, vid))
        sport = b[38] * 256 + b[39]
        dport = b[40] * 256 + b[41]
        print("srcMAC = " + srcMAC + "\tdstMAC = " + dstMAC)
        print("srcIP = " + srcIP + "\t\tdstIP = " + dstIP)
        print("srcPORT = " + str(sport) + "\t\t\tdstPORT = " + str(dport))

def main():
    global host
    host = int(sys.argv[1])
    iface = sys.argv[2]
    print "sniffing on %s" % iface
    sys.stdout.flush()
    sniff(iface = iface,
          prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()
