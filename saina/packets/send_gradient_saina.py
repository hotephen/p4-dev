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
parser.add_argument('--round', required=False, type=int, default=0, help='')
parser.add_argument('--pkt_id', required=False, type=int, default=0, help='')
parser.add_argument('--round_end_flag', required=False, type=int, default=0, help='')
parser.add_argument('--ls_flag', required=False, type=int, default=0, help='')
parser.add_argument('--wid', required=False, type=int, default=0, help='')
parser.add_argument('--num_pkt', required=False, type=int, default=1, help='')


parser.add_argument('--dst_mac', required=False, type=str, default="0c:c4:7a:63:ff:ff", help='')
parser.add_argument('--src_ip', required=False, type=str, default="20.10.0.1", help='')
parser.add_argument('--dst_ip', required=False, type=str, default="20.10.0.254", help='')


worker_veth_map = {0:'veth0', 1:'veth2', 2:'veth4', 3:'veth6', 16:'veth8'}

args = parser.parse_args()

class switchml(Packet):
    """ Switchml Header. """
    
    name = "switchml"

    fields_desc = [
        BitField('msg_type', 0, 4), # default / bit
        BitField('round_end_flag', args.round_end_flag, 1), #####
        BitField('packet_size', 0, 3),
        ByteField('job_id', 0),
        BitField('tsi', args.pkt_id, 32),
	    BitField('pool_index', (args.pkt_id), 16),
        BitField('packet_type', 0, 8),        
        ByteField('k', 0), ##
        ByteField('round', args.round), ##
        BitField('test1', 0, 32),
        BitField('test2', 0, 32),
        BitField('last_packet_flag', 0, 8),
    ]

class data(Packet):
    """ data Header. """
    
    name = "data"

    fields_desc = [
        SignedIntField('d00', 1),
        SignedIntField('d01', 1),
        SignedIntField('d02', 1),
        SignedIntField('d03', 1),
        SignedIntField('d04', 1),
        SignedIntField('d05', 1),
        SignedIntField('d06', 1),
        SignedIntField('d07', 1),
        SignedIntField('d08', 1),
        SignedIntField('d09', 1),
        SignedIntField('d10', 1),
        SignedIntField('d11', 1),
        SignedIntField('d12', 1),
        SignedIntField('d13', 1),
        SignedIntField('d14', 1),
        SignedIntField('d15', 1),
        SignedIntField('d16', 1),
        SignedIntField('d17', 1),
        SignedIntField('d18', 1),
        SignedIntField('d19', 1),
        SignedIntField('d20', 1),
        SignedIntField('d21', 1),
        SignedIntField('d22', 1),
        SignedIntField('d23', 1),
        SignedIntField('d24', 1),
        SignedIntField('d25', 1),
        SignedIntField('d26', 1),
        SignedIntField('d27', 1),
        SignedIntField('d28', 1),
        SignedIntField('d29', 1),
        SignedIntField('d30', 1),
        SignedIntField('d31', 1)
    ]

class data_n(Packet):
    """ data Header. """
    
    name = "data"

    fields_desc = [
        SignedIntField('d00', -1),
        SignedIntField('d01', -1),
        SignedIntField('d02', -1),
        SignedIntField('d03', -1),
        SignedIntField('d04', -1),
        SignedIntField('d05', -1),
        SignedIntField('d06', -1),
        SignedIntField('d07', -1),
        SignedIntField('d08', -1),
        SignedIntField('d09', -1),
        SignedIntField('d10', -1),
        SignedIntField('d11', -1),
        SignedIntField('d12', -1),
        SignedIntField('d13', -1),
        SignedIntField('d14', -1),
        SignedIntField('d15', -1),
        SignedIntField('d16', -1),
        SignedIntField('d17', -1),
        SignedIntField('d18', -1),
        SignedIntField('d19', -1),
        SignedIntField('d20', -1),
        SignedIntField('d21', -1),
        SignedIntField('d22', -1),
        SignedIntField('d23', -1),
        SignedIntField('d24', -1),
        SignedIntField('d25', -1),
        SignedIntField('d26', -1),
        SignedIntField('d27', -1),
        SignedIntField('d28', -1),
        SignedIntField('d29', -1),
        SignedIntField('d30', -1),
        SignedIntField('d31', -1)
    ]



bind_layers(UDP, switchml)
bind_layers(switchml, data)
bind_layers(switchml, data_n)

def pkt_id_to_pool_index(pkt_id, pool_index_shift):
    
    pool_index = (pkt_id + pool_index_shift) % (2*pool_size)

    if (pool_index < pool_size):
        return pool_index
    else:
        return (pool_index-pool_size | 0x8000)

def main():
    dst_ip = args.dst_ip
    src_ip = args.src_ip
    iface = args.i
    if args.wid != 0:
        iface = worker_veth_map[args.wid]

    pkt_id = args.pkt_id

    global pool_size
    pool_size = 256
    pool_index_shift = 0
    pool_index = pkt_id_to_pool_index(pkt_id, pool_index_shift)
    

    if(args.c==0):
        # pkt = Ether / IP(src=src_ip, dst=dst_ip) / UDP(dport=48864, sport=20) / switchml / data / data / exponents / sign
        pkt = Ether(src='00:00:00:00:00:00', dst=args.dst_mac) / IP(src=src_ip, dst=dst_ip) / UDP(dport=48864, sport=20) \
                    / switchml(pool_index=pool_index) / data()
        pkt.show()
        # hexdump(pkt)

        sendp(pkt, iface=iface, verbose=False)
    
    
    else:
        for i in range(args.num_pkt):
            pkt_id = args.pkt_id + i 
                
            pool_index = pkt_id_to_pool_index(pkt_id, pool_index_shift)
            pkt = Ether(src='00:00:00:00:00:00', dst=args.dst_mac) / IP(src=src_ip, dst=dst_ip) / UDP(dport=48864, sport=20) / switchml(tsi=pkt_id, pool_index=pool_index)
            
            if i == args.num_pkt - 1:
                pkt = Ether(src='00:00:00:00:00:00', dst=args.dst_mac) / IP(src=src_ip, dst=dst_ip) / UDP(dport=48864, sport=20) / switchml(tsi=pkt_id, pool_index=pool_index, last_packet_flag=1)
                pool_index_shift = args.num_pkt % (2 * pool_size)
            
            pkt = pkt / data()
            pkt[switchml].round = 0
                
            sendp(pkt, iface=iface, verbose=False)
            pkt.show()
            
        for i in range(args.num_pkt):
            pkt_id = args.pkt_id + i 
                
            pool_index = pkt_id_to_pool_index(pkt_id, pool_index_shift)
            pkt = Ether(src='00:00:00:00:00:00', dst=args.dst_mac) / IP(src=src_ip, dst=dst_ip) / UDP(dport=48864, sport=20) / switchml(tsi=pkt_id, pool_index=pool_index)
            
            if i == args.num_pkt - 1:
                pkt = Ether(src='00:00:00:00:00:00', dst=args.dst_mac) / IP(src=src_ip, dst=dst_ip) / UDP(dport=48864, sport=20) / switchml(tsi=pkt_id, pool_index=pool_index, last_packet_flag=1)
                pool_index_shift = pool_index
            
            pkt = pkt / data_n()
            pkt[switchml].round = 1
                
            sendp(pkt, iface=iface, verbose=False)
            pkt.show()


if __name__ == '__main__':
    main()





# print ("sending %s th packets to interface %s " % (i, iface))
