#!/usr/bin/env python
import argparse
import sys
import struct
import os

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Packet, IPOption
from scapy.all import ShortField, IntField, LongField, BitField, FieldListField, FieldLenField
from scapy.all import IP, TCP, UDP, Raw, Ether, Padding
from scapy.layers.inet import _IPOption_HDR

parser = argparse.ArgumentParser(description='receive entry packet')
parser.add_argument('--i', required=False, type=str, default='veth0', help='interface')
parser.add_argument('--s', required=False, type=int, default=0, help='show')
parser.add_argument('--save_index', required=False, type=str, default='', help='show')
parser.add_argument('--type', required=False, type=str, default='', help='topk or daiet')
args = parser.parse_args()

class entry_hdr(Packet):
    """ Entry Header """
    name = "entry"
    fields_desc = [
        BitField("frame_type", 0, 8),
        IntField("number_of_entries", 10),
        IntField("tree_id", 1),

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

bind_layers(UDP, entry_hdr)

cnt0 = 0; empty = 0; empty1 = 0; empty2 = 0; cnt1 = 0; cnt2 = 0; empty_count=0; num_of_entries=0
value_count = 0
value_count1 = 0
value_count2 = 0
def handle_pkt(pkt):
    global cnt0, empty, empty1, empty2, cnt1, cnt2, value_count, value_count1, value_count2, empty_count, num_of_entries


    if args.s == 1:
        pkt.show()
        # hexdump(pkt)
        pass

    try:
        eh = pkt[entry_hdr]
        
        if pkt[IP].dst == '10.0.0.16':
            if args.s == 1:
                pkt.show()
                # pass

            if eh.frame_type == 0:
                cnt0 += 1
                if eh.key0 == 0:
                    empty_count += eh.value0
                if eh.key1 == 0:
                    empty_count += eh.value1
                if eh.key2 == 0:
                    empty_count += eh.value2
                if eh.key3 == 0:
                    empty_count += eh.value3
                if eh.key4 == 0:
                    empty_count += eh.value4
                if eh.key5 == 0:
                    empty_count += eh.value5
                if eh.key6 == 0:
                    empty_count += eh.value6
                if eh.key7 == 0:
                    empty_count += eh.value7
                if eh.key8 == 0:
                    empty_count += eh.value8
                if eh.key9 == 0:
                    empty_count += eh.value9

                value_count += eh.value0
                value_count += eh.value1
                value_count += eh.value2
                value_count += eh.value3
                value_count += eh.value4
                value_count += eh.value5
                value_count += eh.value6
                value_count += eh.value7
                value_count += eh.value8
                value_count += eh.value9

                num_of_entries += eh.number_of_entries

            elif eh.frame_type == 1:
                cnt1 += 1
                if eh.key0 == 0:
                    empty1 += 1
                if eh.key1 == 0:
                    empty1 += 1
                if eh.key2 == 0:
                    empty1 += 1
                if eh.key3 == 0:
                    empty1 += 1
                if eh.key4 == 0:
                    empty1 += 1
                if eh.key5 == 0:
                    empty1 += 1
                if eh.key6 == 0:
                    empty1 += 1
                if eh.key7 == 0:
                    empty1 += 1
                if eh.key8 == 0:
                    empty1 += 1
                if eh.key9 == 0:
                    empty1 += 1

                value_count1 += eh.value0
                value_count1 += eh.value1
                value_count1 += eh.value2
                value_count1 += eh.value3
                value_count1 += eh.value4
                value_count1 += eh.value5
                value_count1 += eh.value6
                value_count1 += eh.value7
                value_count1 += eh.value8
                value_count1 += eh.value9

                    
            else:
                cnt2 += 1
                if eh.key0 == 0:
                    empty2 += 1
                if eh.key1 == 0:
                    empty2 += 1
                if eh.key2 == 0:
                    empty2 += 1
                if eh.key3 == 0:
                    empty2 += 1
                if eh.key4 == 0:
                    empty2 += 1
                if eh.key5 == 0:
                    empty2 += 1
                if eh.key6 == 0:
                    empty2 += 1
                if eh.key7 == 0:
                    empty2 += 1
                if eh.key8 == 0:
                    empty2 += 1
                if eh.key9 == 0:
                    empty2 += 1

            print('===================================')
            print('frame_type 0 pkt cnt : ', cnt0) # not saved pkts (pushout)
            print('The value count of frame_type 0 : ', value_count)
            print('The number of entries in frame_type 0 : ', num_of_entries)
            print('-----------')
            print('frame_type 1 pkt cnt : ', cnt1)   
            print('The value count of frame_type 0 : ', value_count1)
            print('-----------')
            print('frame_type 2 pkt cnt : ', cnt2)   
            print('-----------------------------------')   
        
        # print('The number of empty_count : ', empty_count)
        # print('The number of empty1 entry : ', empty1)
        # print('The number of empty2 entry : ', empty2)
        
        if args.save_index != '':
            with open("/ssd2/hc/p4-dev/topk/logs/mininet/" + str(args.type) + '/' + str(args.type) + '-' +str(args.save_index) + '.csv', "a") as save_file:
                save_file.write('pkt0:' + ',' + str(cnt0) + ',' + 'pkt0_value:' + ',' + str(value_count) + ',' + 'pkt0_num_of_ent:' + ',' + str(num_of_entries)  + ',' \
                + 'pkt0_key=0_value:' + ',' + str(empty_count) + ',' + 'pkt1:' + ',' + str(cnt1) + ',' + 'pkt1_value:' + ',' +str(value_count1) + ',' + 'pkt2:' + ',' + str(cnt2) + '\n')

    
    except IndexError:
        # print('IndexError')
        pass

def main():
    ifaces = filter(lambda i: args.i in i, os.listdir('/sys/class/net/'))
    iface = args.i
    print("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(iface = iface,
        prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()
