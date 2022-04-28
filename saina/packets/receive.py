from re import I
import numpy as np
from scapy.all import sendp, get_if_hwaddr, hexdump, sniff, bind_layers, sendpfast
from scapy.all import Packet
from scapy.all import Ether, IP, UDP
from scapy.all import hexdump, ShortField, BitField, BitFieldLenField, ShortEnumField, X3BytesField, ByteField, XByteField, IntField
from scapy.all import *
import os
import pickle
from time import sleep

global gradient_arr, cnt

gradient_arr = np.zeros(37148106)
cnt = 0

class SAINA_hdr(Packet):
    """ SAINA Header """
    name = "SAINA"
    fields_desc = [

        BitField('msg_type', 0, 4),
        BitField('round_end_flag', 1, 1),
        BitField('packet_size_t', 0, 3),
        ByteField('job_number', 0),
        BitField('packet_id', 0, 32),
        BitField('pool_index', 0, 16),
        BitField('packet_type', 0, 8),
        ByteField('k', 0),
        ByteField('round', 0),
        BitField('test1', 0, 32),
        BitField('test2', 0, 32),
        BitField('last_packet_flag', 0, 8),
    ]

class DATA(Packet):
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

def receive_from_switch():

    iface = 'veth32'
    bind_layers(Ether, IP)
    bind_layers(IP, UDP)
    bind_layers(UDP, SAINA_hdr)
    bind_layers(SAINA_hdr, DATA)
    print("sniffing on %s" % iface)
    sniff(iface = iface, prn = lambda x: handle_pkt(x))

def handle_pkt(pkt):

    # global gradient_arr, cnt
    # pkt.show()
    pkt_id = pkt[SAINA_hdr].packet_id
    print(pkt_id)


receive_from_switch()