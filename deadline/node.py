#!/usr/bin/env python
import time
import threading
import argparse
import sys
import numpy as np
import os
import multiprocessing.connection import Listener

# from headers import *
from scapy.all import *
from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr, bind_layers
from scapy.layers.l2 import Ether
from scapy.layers.inet import IP, UDP
from scapy.all import hexdump, ShortField, BitField, BitFieldLenField, ShortEnumField, X3BytesField, ByteField, XByteField, IntField

parser = argparse.ArgumentParser(description='parser')
parser.add_argument('--i', required=False, type=str, default='veth0', help='interface')
parser.add_argument('--id', required=False, type=int, default=1, help='node id')
args = parser.parse_args()

seg_num = 1

# Packet Header Definition

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

bind_layers(UDP, frame_type)
bind_layers(frame_type, preamble)
bind_layers(preamble, ENTRY)

data = Ether() / IP(dst="10.10.0.1") / UDP(sport=1234, dport=5678) / frame_type(frame_type=1) \ 
        / preamble(number_of_entries=10, seg_number=seg_num) / ENTRY(key=1,value=1) / \ 
        ENTRY(key="b",value=2) / ENTRY(key="c",value=3) / ENTRY(key="d",value=4)/ \
        ENTRY(key="d",value=5) / ENTRY(key="d",value=6) / ENTRY(key="d",value=7) / \
        ENTRY(key="d",value=8) / ENTRY(key="d", value=9) / ENTRY(key="d",value=10)



# ------------------ #

send_time = 0
receive_time = 0 
start_time = 0 
count = 0
seg_num = 1
seg_to_receive = 11
delay = 0
reservation = 0

def main():
    global send_time, seg_num

    ifaces = filter(lambda i: args.i in i, os.listdir('/sys/class/net/'))
    iface = args.i
    
    # Initial packet sending
    # threading.Timer(3,send_packet).start()
    # sendp(data, iface=iface, verbose=False)
    # send_time = time.time()
    # print("Send first packet to %s" % iface)


    print("Sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(iface = iface, prn = lambda x: handle_pkt(x))


def send_packet():
    global seg_num, send_time, reservation
    data = Ether() / IP(dst="10.10.0.1") / UDP(sport=1234, dport=5678) / frame_type(frame_type=1) / preamble(number_of_entries=10, \
        seg_number=seg_num) / ENTRY(key=1,value=1) / ENTRY(key="b",value=2) / ENTRY(key="c",value=3) / ENTRY(key="d",value=4)/ \
        ENTRY(key="d",value=5) / ENTRY(key="d",value=6) / ENTRY(key="d",value=7) / ENTRY(key="d",value=8) / ENTRY(key="d", \
        value=9) / ENTRY(key="d",value=10)
    
    sendp(data, iface=args.i, verbose=False)
    reservation = 0
    send_time = time.time()
    print("send_time: %f" %send_time)
    print("----------------")
    print("Sent (seg_num : %d) local packet to the switch" % seg_num)
    # print("Send time : %f " % send_time)
    print("=================")


def handle_pkt(pkt):
    global send_time, receive_time, count, seg_num, seg_to_receive, start_time, delay, reservation

    try:
        if (pkt[frame_type].frame_type == 2) and (seg_num == pkt[preamble].seg_number) :
            
            t_list = threading.enumerate()
            print(t_list)
            print(len(t_list))

            if len(t_list) > 1:
                reserved_thread = t_list[1]
                print(reserved_thread)
                reserved_thread.cancel()
                print("stop previous timer thread")

            if count == 1:
                start_time = time.time()

            # pkt.show()
            count = count + 1
            receive_time = time.time()
            print("================")
            print("Receive %d th global gradient packet (seg_num : %d) " % (count, pkt[preamble].seg_number))
            print("Receive time : %f" % receive_time)
            rtt = receive_time-send_time
            print("RTT : %f" % rtt)
            elpased_time = receive_time - start_time

            # Save elapsed time
            with open("/ssd2/hc/logs/deadline/host" + str(args.id) + ".csv", "a") as save_file:
                # rtt_file.write(str(count) + ',' + str(rtt) + ',' + str(pkt[preamble].seg_number) + '\n')
                save_file.write(str(delay) + ',' + str(count) + ',' + 'elapsed_time :' + str(elpased_time) + ',' + str(pkt[preamble].seg_number) + '\n')


            # time.sleep(delay)


            # Update seg_num
            data[preamble].seg_number = pkt[preamble].seg_number + 10
            seg_num = data[preamble].seg_number

            # Send packet
            seg_to_receive = seg_num
            delay = np.random.uniform(5,10) # ms
            print("Delay : %s"  % delay)
            
            timer = threading.Timer(delay, send_packet)
            timer.start()
            # threading.Timer(delay, send_packet).start()
            

    except IndexError:
        print('IndexError')
        # pass


def wait_local_gradient():
    # Server which waits for local gradient
    address = ('localhost', 6000)
    listener = Listener(address, authkey='password')
    conn = listener.accept()
    print('connection accepted from', listener.last_accepted)
    while True:
        msg = conn.recv()
        if msg == 'close':
            conn.close()
            break
    listener.close()
    




if __name__ == '__main__':
    main()