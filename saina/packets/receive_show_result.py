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
parser.add_argument('--s', required=False, type=int, default=0, help='show packet')
parser.add_argument('--job_id', required=False, type=int, default=0, help='job id')
parser.add_argument('--src_ip', required=False, type=str, default="10.10.0.1", help='')
parser.add_argument('--dst_ip', required=False, type=str, default="10.10.0.12", help='')

args = parser.parse_args()
global xor_sum
xor_sum = 0

class switchml(Packet):
    """ Switchml Header. """
    
    name = "switchml"

    fields_desc = [
        BitField('msg_type', 0, 4), # default / bit
        BitField('round_end_flag', 0, 1), #####
        BitField('packet_size', 0, 3),
        ByteField('job_id', 0),
        BitField('tsi', 0, 32),
	    BitField('pool_index', 0, 16),
        BitField('packet_type', 0, 8),        
        ByteField('k', 0), ##
        ByteField('round', 0), ##
        BitField('test1', 0, 32),
        BitField('test2', 0, 32),
        BitField('last_packet_flag', 0, 8)
    ]

class data(Packet):
    """ data Header. """
    
    name = "data"

    fields_desc = [
        SignedIntField('d00', 0),
        SignedIntField('d01', 0),
        SignedIntField('d02', 0),
        SignedIntField('d03', 0),
        SignedIntField('d04', 0),
        SignedIntField('d05', 0),
        SignedIntField('d06', 0),
        SignedIntField('d07', 0),
        SignedIntField('d08', 0),
        SignedIntField('d09', 0),
        SignedIntField('d10', 0),
        SignedIntField('d11', 0),
        SignedIntField('d12', 0),
        SignedIntField('d13', 0),
        SignedIntField('d14', 0),
        SignedIntField('d15', 0),
        SignedIntField('d16', 0),
        SignedIntField('d17', 0),
        SignedIntField('d18', 0),
        SignedIntField('d19', 0),
        SignedIntField('d20', 0),
        SignedIntField('d21', 0),
        SignedIntField('d22', 0),
        SignedIntField('d23', 0),
        SignedIntField('d24', 0),
        SignedIntField('d25', 0),
        SignedIntField('d26', 0),
        SignedIntField('d27', 0),
        SignedIntField('d28', 0),
        SignedIntField('d29', 0),
        SignedIntField('d30', 0),
        SignedIntField('d31', 0)
    ]




bind_layers(UDP, switchml)
bind_layers(switchml, data)



def handle_pkt(pkt):
    global xor_sum
    # count = count + 1
    # pkt.show()
    # hexdump(pkt)
    if (pkt[Ether].dst =='00:00:00:00:00:00'):
        if args.s == 1:
            pkt.show()
        print("tsi: ", pkt[switchml].tsi , "sign_vector: ", bin(pkt[switchml].test1).zfill(32), 
                "sum: ", pkt[switchml].test2, "k: ", pkt[switchml].k, "round: ", pkt[switchml].round)
        xor = pkt[switchml].test1
        binary = format(xor, 'b')
        count = binary.count('1')
        xor_sum += count
        print("xor_sum: ", xor_sum)
        print("=========================================================")

def main():
    
    iface = args.i
    print ("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(iface = iface,
          prn = lambda x: handle_pkt(x))


if __name__ == '__main__':
    main()
