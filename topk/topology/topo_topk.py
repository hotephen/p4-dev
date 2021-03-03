#!/usr/bin/python

# Copyright 2013-present Barefoot Networks, Inc. 
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
import sys

sys.path.append("~/p4/mininet")
from mininet.net import Mininet
from mininet.topo import Topo
from mininet.log import setLogLevel, info
from mininet.cli import CLI
from mininet.link import TCLink

from p4_mininet import P4Switch, P4Host

import argparse
from time import sleep
import os
import subprocess
from subprocess import PIPE

_THIS_DIR = os.path.dirname(os.path.realpath(__file__))
_THRIFT_BASE_PORT = 9290

parser = argparse.ArgumentParser(description='Mininet demo')
parser.add_argument('--behavioral-exe', help='Path to behavioral executable',
                    type=str, action="store", required=True)
parser.add_argument('--switch', help='Path to bftswitch JSON config file',
                    type=str, action="store", required=True)                    
parser.add_argument('--cli', help='Path to BM CLI',
                    type=str, action="store", required=True)
# parser.add_argument('--server', help='Path to server JSON config file',
#                     type=str, action="store", required=True)
# parser.add_argument('--bftswitch', help='Path to bftswitch JSON config file',
#                     type=str, action="store", required=True)
# parser.add_argument('--client', help='Path to client JSON config file',
#                     type=str, action="store", required=True)                 

args = parser.parse_args()

class MyTopo(Topo):
    def __init__(self, sw_path, switch, **opts):
        # Initialize topology and default options
        Topo.__init__(self, **opts)
        k = 2
        core_switches = []
        agg_switches = []
        for i in range(k):
            j = i+1
            core_switches.append(self.addSwitch('s'+ str(j),
                      sw_path = args.behavioral_exe,
                      json_path = switch,
                      thrift_port = _THRIFT_BASE_PORT + j,
                      pcap_dump = False,
                      device_id = j))

        for i in range(k):
            agg_switches.append([])

        for i in range(k):
            for j in range(4):
                j = j+1
                agg_switches[i].append(self.addSwitch('s'+ str(i+1) + str(j),
                      sw_path = args.behavioral_exe,
                      json_path = switch,
                      thrift_port = _THRIFT_BASE_PORT + (i+1)*10 + j,
                      pcap_dump = False,
                      device_id = (i+1)*10+j))
            

        linkopts = dict(bw=1, delay='1ms', loss=0, use_htb=True)
        
        s1 = core_switches[0]
        s2 = core_switches[1]

        s11 = agg_switches[0][0]
        s12 = agg_switches[0][1]
        s13 = agg_switches[0][2]
        s14 = agg_switches[0][3]

        s21 = agg_switches[1][0]
        s22 = agg_switches[1][1]
        s23 = agg_switches[1][2]
        s24 = agg_switches[1][3]

        self.addLink(s1, s11)
        self.addLink(s1, s21)
        self.addLink(s2, s12)
        self.addLink(s2, s22)

        self.addLink(s11, s13)
        self.addLink(s11, s14)
        self.addLink(s12, s13)
        self.addLink(s12, s14)

        self.addLink(s21, s23)
        self.addLink(s21, s24)
        self.addLink(s22, s23)
        self.addLink(s22, s24)



def main():
    topo = MyTopo(args.behavioral_exe, args.switch)

    net = Mininet(topo = topo,
                  host = P4Host,
                  switch = P4Switch,
                  link=TCLink,
                  controller = None )

    net.start()
    print ("netstart end")
    sleep(2)
    print ("Ready !")
    CLI( net )
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    main()



        # for i, s in enumerate(aswitches):
        #     print "switch----------"
        #     self.addLink(s, s1, **linkopts)
            
        #     for a, b in enumerate(bswitches):
        #             self.addLink(s, b,**linkopts)

        # self.addLink(s1, s9, **linkopts)