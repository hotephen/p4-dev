#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct
import time
import os


sys.path.append("~/p4-dev/topk/packets/")

from scapy.all import sendp, send, get_if_list, get_if_hwaddr, hexdump
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP
from scapy.all import hexdump, ShortField, BitField, BitFieldLenField, ShortEnumField, X3BytesField, ByteField, XByteField, IntField

parser = argparse.ArgumentParser(description='send entry packet')
parser.add_argument('--sm', required=False, default='00:00:00:00:00:01', help='source MAC address')
parser.add_argument('--dm', required=False, default='00:00:00:00:00:02', help='destination MAC address')
parser.add_argument('--si', required=False, default='10.0.0.1', help='source IP address')
parser.add_argument('--di', required=False, default='10.0.0.16', help='destination IP address')
parser.add_argument('--dif', required=False, default='10.0.0.16', help='destination switch IP address for flush')
parser.add_argument('--dif2', required=False, default='10.0.0.16', help='destination switch IP address for flush')
parser.add_argument('--add', required=False, type=int, default=0, help='additional flush packet')
parser.add_argument('--sp', required=False, type=int, default=1234, help='source PORT number')
parser.add_argument('--dp', required=False, type=int, default=5678, help='destination PORT number')
parser.add_argument('--key', required=False, type=int, default=1111, help='key')
parser.add_argument('--i', required=False, type=str, default='veth0', help='i')
parser.add_argument('--num', required=False, type=int, default=0, help='number of packets')
parser.add_argument('--num_flush', required=False, type=int, default=0, help='number of flush packets')
parser.add_argument('--daiet', required=False, type=int, default=0, help='sending end packet for daiet (frame_type 1)')
parser.add_argument('--dist', required=False, type=str, default='', help='type of packets')
parser.add_argument('--parameter', required=False, type=str, default='1.1', help='parameter of zipf')
parser.add_argument('--entry', required=False, type=int, default=1000, help='select entries')
parser.add_argument('--host_num', required=False, type=int, default=1, help='host number')
parser.add_argument('--fat_tree', required=False, type=int, default=0, help='')
parser.add_argument('--sort', required=False, type=int, default=2, help='sort:1,2,3')
a = parser.parse_args()

class frame_type(Packet):
    """ Frame_type Header """
    name = "frame_type"
    fields_desc = [
        BitField("frame_type", 0, 8),
        IntField("number_of_entries", 10),
        IntField("tree_id", 1),
    ] 

class entry_hdr(Packet):
    """ Entry Header """
    name = "entry"
    fields_desc = [
        # BitField("frame_type", 0, 8),
        # IntField("number_of_entries", 10),
        # IntField("tree_id", 1),
        # BitField('flush', 0, 8),

        BitField('key0', 0, 128),
        BitField('value0', 1, 32),
        BitField('key1', 0, 128),
        BitField('value1', 1, 32),
        BitField('key2', 0, 128),
        BitField('value2', 1, 32),
        BitField('key3', 0, 128),
        BitField('value3', 1, 32),
        BitField('key4', 0, 128),
        BitField('value4', 1, 32),
        BitField('key5', 0, 128),
        BitField('value5', 1, 32),
        BitField('key6', 0, 128),
        BitField('value6', 1, 32),
        BitField('key7', 0, 128),
        BitField('value7', 1, 32),
        BitField('key8', 0, 128),
        BitField('value8', 1, 32),
        BitField('key9', 0, 128),
        BitField('value9', 1, 32),
    ]

class entry_hdr0(Packet):
    """ Entry Header0 """
    name = "entry0"
    fields_desc = [
        # BitField("frame_type", 0, 8),
        # IntField("number_of_entries", 10),
        # IntField("tree_id", 1),
        # BitField('flush', 0, 8),

        BitField('key0', 0, 128),
        BitField('value0', 0, 32),
        BitField('key1', 0, 128),
        BitField('value1', 0, 32),
        BitField('key2', 0, 128),
        BitField('value2', 0, 32),
        BitField('key3', 0, 128),
        BitField('value3', 0, 32),
        BitField('key4', 0, 128),
        BitField('value4', 0, 32),
        BitField('key5', 0, 128),
        BitField('value5', 0, 32),
        BitField('key6', 0, 128),
        BitField('value6', 0, 32),
        BitField('key7', 0, 128),
        BitField('value7', 0, 32),
        BitField('key8', 0, 128),
        BitField('value8', 0, 32),
        BitField('key9', 0, 128),
        BitField('value9', 0, 32),
    ]



cnt = 0
def main():
    global cnt, empty
    a = parser.parse_args()
    p = a.parameter
    host_num = a.host_num
    

    iface = a.i
    # iface = 'veth0'

    range_bottom = 1
    range_top = 100000

    ether = Ether(src=a.sm, dst=a.dm)
    ip = IP(src=a.si, dst=a.di, proto=17) 
    udp = UDP(sport=a.sp, dport=a.dp)
    lines = []
    n = []

    if a.dist == 'z':
        if a.fat_tree == 1: #TODO
            f = open('/ssd2/hc/p4-dev/topk/packets/dataset/z_dist_%s_%s_%s_%s' %(p, str(a.entry),a.num*10, a.host_num), 'r')
            # f = open('/ssd2/hc/p4-dev/topk/packets/dataset/z_dist_%s_%s_%s' %(p, str(a.entry),a.num*12*10), 'r')
            for i in range(a.num*12*10):  
                lines.append(f.readline())
        else:
            if a.sort == 1 or a.sort== 3 :
                f = open('/ssd2/hc/p4-dev/topk/packets/dataset/z_dist_%s_%s_%s_sorted' %(p, str(a.entry), str(a.num*10)), 'r')
            else: # sort == 2
                f = open('/ssd2/hc/p4-dev/topk/packets/dataset/z_dist_%s_%s_%s' %(p, str(a.entry), str(a.num*10)), 'r')
            
            for i in range(a.num):  
                lines.append(f.readline())


        # for i in range((host_num-1)*a.num, (host_num)*a.num):
        for i in range(a.num):
            if a.sort == 3: # reverse (worst cast)
                line = lines[a.num-1-i]
            else:
                line = lines[i]
            
            n = line.split()
            # print(line)

            pkt = ether / ip / udp / frame_type(frame_type=0,number_of_entries=10) / entry_hdr(key0=int(n[0]), key1=int(n[1]), key2=int(n[2]), key3=int(n[3]), key4=int(n[4]), key5=int(n[5]), key6=int(n[6]), key7=int(n[7]), key8=int(n[8]), key9=int(n[9]))
            sendp(pkt, iface=iface, verbose=False)
            cnt += 1
            print('send pkt cnt : ', cnt)

        f.close()

    elif a.dist == 'u':
        
        if a.fat_tree == 1:
            f = open('/ssd2/hc/p4-dev/topk/packets/dataset/z_dist_%s_%s_%s' %(str(a.entry),a.num*10, a.host_num), 'r')
            # f = open('/ssd2/hc/p4-dev/topk/packets/dataset/u_dist_%s_120000' %(str(a.entry)), 'r')
            for i in range(120000):  
                lines.append(f.readline())

        else:
            f = open('/ssd2/hc/p4-dev/topk/packets/dataset/u_dist_%s_%s' %(str(a.entry), str(a.num*10)), 'r')   
            for i in range(a.num):  
                lines.append(f.readline())
            
        # for i in range((host_num-1)*a.num, (host_num)*a.num):
        for i in range(a.num):
            line = lines[i]
            n = line.split()
            # print(line)

            pkt = ether / ip / udp / frame_type(frame_type=0,number_of_entries=10) / entry_hdr(key0=int(n[0]), key1=int(n[1]), key2=int(n[2]), key3=int(n[3]), key4=int(n[4]), key5=int(n[5]), key6=int(n[6]), key7=int(n[7]), key8=int(n[8]), key9=int(n[9]))
            sendp(pkt, iface=iface, verbose=False)
            cnt += 1
            print('send pkt cnt : ', cnt)

        f.close()
    #             line = lines[random_number]
    #             n = line.split()


    elif a.dist == 'g':
        with open('/ssd2/hc/p4-dev/topk/packets/dataset/g_dist', 'r') as f:
            for i in range(a.num*10):
                lines.append(f.readline())            
                lines[i].strip()

            for i in range(a.num):
                n = []
                for j in range(10):
                    random_number = random.randrange(0,a.num*10)
                    n.append(lines[random_number])
                
                pkt = ether / ip / udp / frame_type(frame_type=0,number_of_entries=10) / entry_hdr(key0=int(n[0]), key1=int(n[1]), key2=int(n[2]), key3=int(n[3]), key4=int(n[4]), key5=int(n[5]), key6=int(n[6]), key7=int(n[7]), key8=int(n[8]), key9=int(n[9]))
                sendp(pkt, iface=iface, verbose=False)
                cnt += 1
                print('send pkt cnt : ', cnt)

    else:
        for i in range(a.num):
            pkt = ether / ip / udp / frame_type(frame_type=0,number_of_entries=10) / entry_hdr(key0=1, key1=2, key2=3)
            sendp(pkt, iface=iface, verbose=False)
            cnt += 1
            print('send pkt cnt : ', cnt)    # f.close()

    # elif a.g == 1 or a.dist == 'g':
    #     with open('/ssd2/hc/p4-dev/topk/packets/dataset/g_dist', 'r') as f:
            
    #         for i in range(1000):
    #             lines.append(f.readline())            
            
    #         for i in range(a.num):
    #             random_number = random.randrange(0,1000)
    #             line = lines[random_number]
    #             n = line.split()
    #             # print(n)

    #             pkt = ether / ip / udp / frame_type(frame_type=0,number_of_entries=10) / entry_hdr(key0=int(n[0]), key1=int(n[1]), key2=int(n[2]), key3=int(n[3]), key4=int(n[4]), key5=int(n[5]), key6=int(n[6]), key7=int(n[7]), key8=int(n[8]), key9=int(n[9]))
    #             sendp(pkt, iface=iface, verbose=False)
    #             cnt += 1
    #             print('send pkt cnt : ', cnt)   

    # elif a.dist == 'u':
    #     with open('/ssd2/hc/p4-dev/topk/packets/dataset/u_dist', 'r') as f:
            
    #         for i in range(100000): #TODO : fix to 10000 (which is dataset lines)
    #             lines.append(f.readline())            
    #             lines[i].strip()

    #         for i in range(a.num):
    #             n = []
    #             for j in range(10):
    #                 random_number = random.randrange(0,100000)
    #                 n.append(lines[random_number])

    #             pkt = ether / ip / udp / frame_type(frame_type=0,number_of_entries=10) / entry_hdr(key0=int(n[0]), key1=int(n[1]), key2=int(n[2]), key3=int(n[3]), key4=int(n[4]), key5=int(n[5]), key6=int(n[6]), key7=int(n[7]), key8=int(n[8]), key9=int(n[9]))
    #             sendp(pkt, iface=iface, verbose=False)
    #             cnt += 1
    #             print('send pkt cnt : ', cnt)   

    for i in range(a.num_flush):
        if a.daiet == 1:
            pkt1 = ether / IP(dst=a.di, proto=17) / udp / frame_type(frame_type=1, number_of_entries=0) / entry_hdr0(key0=0) # for daiet
        else:
            pkt1 = ether / IP(dst=a.dif, proto=17) / udp / frame_type(frame_type=2, number_of_entries=0) / entry_hdr0(key0=0) # for topk
        # pkt1.show()
        sendp(pkt1, iface=iface, verbose=False)
        print('flush packet cnt : ', i)

    if a.add == 1:
        for i in range(a.num_flush):
            pkt2 = ether / IP(dst=a.dif2, proto=17) / udp / frame_type(frame_type=2, number_of_entries=0) / entry_hdr0(key0=0)
            sendp(pkt2, iface=iface, verbose=False)
            print('flush packet for 2nd sw cnt : ', i)

if __name__ == '__main__':
    main()
