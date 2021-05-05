#!/usr/bin/env python
import time
import threading
import argparse
import sys
import numpy as np
import os
from multiprocessing import Process, Semaphore, shared_memory

# from headers import *
from scapy.all import *
from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr, bind_layers
from scapy.layers.l2 import Ether
from scapy.layers.inet import IP, UDP
from scapy.all import hexdump, ShortField, BitField, BitFieldLenField, ShortEnumField, X3BytesField, ByteField, XByteField, IntField

parser = argparse.ArgumentParser(description='parser')
parser.add_argument('--i', required=False, type=str, default='veth0', help='interface')
# parser.add_argument('--id', required=False, type=int, default=1, help='node id')
args = parser.parse_args()

# lock = threading.Lock()
# seg_num = 1

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

        
bind_layers(UDP, frame_type)
bind_layers(frame_type, preamble)
bind_layers(preamble, ENTRY)


### Global variable definition

global pool1_used, pool2_used, seg_num_list, gradient_list
# pool_used[pool_version][pool_index] = 1 or 0 (used, idle)
pool1_used = {}
pool2_used = {}
seg_num_list = []
# gradient_list = []
gradient_list = np.zeros(320000)
for i in range(4096):
    pool1_used[i] = 0
    pool2_used[i] = 0

###


def receive_packet(iface):
    print("Sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(iface = iface, prn = lambda x: handle_pkt(x))

def handle_pkt(pkt):
    try:
        if (pkt[frame_type].frame_type == 2): # and (seg_num == pkt[preamble].seg_number) :

            recv_seg_num = pkt[preamble].seg_number
            recv_pool_index = pkt[preamble].pool_index
            recv_pool_version = pkt[preamble].pool_version

            # pkt.show()
            print("================")
            print("Receive (seg_num : %d, pool_index : %s, pool_version : %d)" \
                 % (recv_seg_num, recv_pool_index, recv_pool_version))

        # try:
            if recv_pool_version == 1:
                pool1_used[recv_pool_index] = 0 # slot idle
                print(pool1_used[recv_pool_index])
            else:
                pool2_used[recv_pool_index] = 0 # slot idle
                print(pool2_used[recv_pool_index])
            seg_num_list.append(recv_seg_num)
            gradient_list[recv_seg_num] = pkt[ENTRY].value  # ENTRY :  
            print("Saved parameters")

            # finally:
            #     lock.release()

            # except:
                

    except IndexError:
        print('IndexError')
        # pass

def send_packet(grad):
    pkt = Ether() / IP(dst="10.10.0.1") / UDP(sport=1234, dport=5678) / frame_type(frame_type=1)
    num_packets = 10000
    end = 0
    pool_index = 0
    pool_version = 1
    for i in range(num_packets):
        print(i)
        grad_to_send = grad[i*32:(i+1)*32]  # extract gradients to send
        if pool_index >= 4096:
            pool_index = 0
            pool_version = pool_version % 2 + 1
        print(pool_version)
        if i+1 == num_packets:
            end = 1
        
        pkt = Ether() / IP(dst="10.10.0.1") / UDP(sport=1234, dport=5678) /\
                frame_type(frame_type=1) / preamble(end=end, seg_number=i, \
                pool_index=pool_index, pool_version=pool_version)
        
        for z in range(32):
            pkt = pkt / ENTRY(value=grad_to_send[z])

        if pool_version == 1 and pool1_used[pool_index]==0 :
            sendp(pkt, iface = args.i)
            # pkt.show()
            pool1_used[pool_index] = 1
            print("Sent (seg_num : %d, pool_index : %s, pool_version : %d) local packet to the switch" % (i, pool_index, pool_version))

        elif pool_version == 2 and pool2_used[pool_index]==0 :
            sendp(pkt, iface = args.i)
            pool2_used[pool_index] = 1
            print("Sent (seg_num : %d, pool_index : %s, pool_version : %d) local packet to the switch" % (i, pool_index, pool_version))

        else:
            print("No available pool")

        pool_index = pool_index + 32

if __name__ == '__main__':
    run_thread()

def run_thread():

    # Create gradient list (To be deleted)
    grad = []
    for i in range (320000):
        grad.append(i)

    ifaces = filter(lambda i: args.i in i, os.listdir('/sys/class/net/'))
    iface = args.i

    # Collect gradients from TensorFlow
    serm = Semaphore(1)


    # Thread Creation
    send_thread = threading.Thread(target=send_packet, args=(grad,))
    receive_thread = threading.Thread(target=receive_packet, args=(args.i,))
    send_thread.daemon = True       # To enable ctrl+c (exit)
    receive_thread.daemon = True    # To enable ctrl+c (exit)
    
    send_thread.start()
    receive_thread.start()
    
    print(threading.enumerate())

    while True:         # Don't terminate main thread 
        time.sleep(1)


# Update seg_num
# data[preamble].seg_number = pkt[preamble].seg_number + 10
# seg_num = data[preamble].seg_number

# # Send packet
# seg_to_receive = seg_num
# delay = np.random.uniform(5,10) # ms
# print("Delay : %s"  % delay)

# timer = threading.Timer(delay, send_packet)
# timer.start()
# threading.Timer(delay, send_packet).start()    

# def wait_local_gradient():
#     # Server which waits for local gradient
#     address = ('localhost', 6000)
#     listener = Listener(address, authkey='password')
#     conn = listener.accept()
#     print('connection accepted from', listener.last_accepted)
#     while True:
#         msg = conn.recv()
#         if msg == 'close':
#             conn.close()
#             break
#     listener.close()