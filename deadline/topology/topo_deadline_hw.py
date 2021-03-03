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

args = parser.parse_args()

k = 2

class MyTopo(Topo):
    def __init__(self, sw_path, switch, **opts):
        # Initialize topology and default options
        Topo.__init__(self, **opts)

        core_switches1 = []
        core_switches2 = []
        aggr_switches1 = []
        aggr_switches2 = []
        edge_switches1 = []
        edge_switches2 = []

        aggr_switch = []
        edge_switch = []	

        hosts = []

        linkopts = dict(bw=1, delay='1ms', loss=0, use_htb=True)

        for i in range (1,k/2+1):
            core_switches1.append(self.addSwitch('core%d' % (i),
                                    sw_path = sw_path,
                                    json_path = switch,
                                    thrift_port = _THRIFT_BASE_PORT + i,
                                    pcap_dump = False,
                                    device_id = i))


        for i in range (k/2+1, k+1):
            core_switches2.append(self.addSwitch('core%d' % (i),
                                    sw_path = sw_path,
                                    json_path = switch,
                                    thrift_port = _THRIFT_BASE_PORT + i,
                                    pcap_dump = False,
                                    device_id = i))

        for j in range (1,k+1):
            aggr_switches1.append(self.addSwitch('aggr%d' % (2*j-1),
                                    sw_path = sw_path,
                                    json_path = switch,
                                    thrift_port = _THRIFT_BASE_PORT + j,
                                    pcap_dump = False,
                                    device_id = j))

        for j in range (1,k+1):
            aggr_switches2.append(self.addSwitch('aggr%d' % (2*j),
                                    sw_path = sw_path,
                                    json_path = switch,
                                    thrift_port = _THRIFT_BASE_PORT + j,
                                    pcap_dump = False,
                                    device_id = j))

        for j in range (1,k+1):
            edge_switches1.append(self.addSwitch('edge%d' % (2*j-1),
                                    sw_path = sw_path,
                                    json_path = switch,
                                    thrift_port = _THRIFT_BASE_PORT + j,
                                    pcap_dump = False,
                                    device_id = j))

        for j in range (1,k+1):
            edge_switches2.append(self.addSwitch('edge%d' % (2*j),
                                    sw_path = sw_path,
                                    json_path = switch,
                                    thrift_port = _THRIFT_BASE_PORT + j,
                                    pcap_dump = False,
                                    device_id = j))

        aggr_switch.extend(aggr_switches1)
        aggr_switch.extend(aggr_switches2)
        edge_switch.extend(edge_switches1)
        edge_switch.extend(edge_switches2)        

        for i, s in enumerate(core_switches1):

            for a, b in enumerate(aggr_switches1):
                    self.addLink(s, b,**linkopts)

        for i, s in enumerate(core_switches2):

            for a, b in enumerate(aggr_switches2):
                    self.addLink(s, b,**linkopts)

        for m in range(0,k):
            for i in range (1,3):
                for j in range (1,3):
                    self.addLink(aggr_switch[k*(i-1)+m], edge_switch[k*(j-1)+m],**linkopts)

        for i in range(1,4*k+1):
            hosts.append(self.addHost('host%d' % (i), ip='10.0.1.%d' % (i), mac='00:00:00:00:00:0%d' % (i) ))

        for m in range(0,k):
            self.addLink(hosts[4*m], edge_switch[m],**linkopts)
            self.addLink(hosts[4*m+1], edge_switch[m],**linkopts)


        for m in range(k,2*k):
            self.addLink(hosts[4*(m-k+1)-2], edge_switch[m],**linkopts)
            self.addLink(hosts[4*(m-k+1)-1], edge_switch[m],**linkopts)

def main():
    topo = MyTopo(args.behavioral_exe, args.switch)

    net = Mininet(topo = topo,
                  host = P4Host,
                  switch = P4Switch,
                  link=TCLink,
                  controller = None )

    net.start()
    print "netstart end"
    sleep(2)
    print "Ready !"
    CLI( net )
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    main()
