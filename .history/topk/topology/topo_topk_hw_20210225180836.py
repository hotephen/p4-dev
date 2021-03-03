#########    Compose k-ary fat tree using bmv2 switches    #########
# Default value of k is set to be 4, but you can change if you want.
# Switch requires bmv2 json file, so you can use your own bmv2
# by simply changing file path of switch in run_fat_tree.sh.

import sys
sys.path.append("~/p4/mininet/")
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

_Default_K = 4

_THIS_DIR = os.path.dirname(os.path.realpath(__file__))
_THRIFT_BASE_PORT = 9300

parser = argparse.ArgumentParser(description='Mininet demo')
parser.add_argument('--behavioral-exe', help='Path to behavioral executable',
                    type=str, action="store", required=True)
parser.add_argument('--switch', help='Path to bftswitch JSON config file',
                    type=str, action="store", required=True)
parser.add_argument('--cli', help='Path to BM CLI',
                    type=str, action="store", required=True)

args = parser.parse_args()

# k-ary fat tree
# k = _Default_K
k = 4

# There are 3 types of switches: Core, aggregate and edge switch according to k-ary fat tree topology.
class MyTopo(Topo):
    def __init__(self, sw_path, switch, **opts):
        # Initialize topology with creating switches
        Topo.__init__(self, **opts)
        count = 1
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
                                    thrift_port = _THRIFT_BASE_PORT + count,
                                    pcap_dump = False,
                                    device_id = count))
            count = count + 1

        for i in range (k/2+1, k+1):
            core_switches2.append(self.addSwitch('core%d' % (i),
                                    sw_path = sw_path,
                                    json_path = switch,
                                    thrift_port = _THRIFT_BASE_PORT + count,
                                    pcap_dump = False,
                                    device_id = count))
            count = count + 1

        for j in range (1,k+1):
            aggr_switches1.append(self.addSwitch('aggr%d' % (2*j-1),
                                    sw_path = sw_path,
                                    json_path = switch,
                                    thrift_port = _THRIFT_BASE_PORT + count,
                                    pcap_dump = False,
                                    device_id = count))
            count = count + 1

        for j in range (1,k+1):
            aggr_switches2.append(self.addSwitch('aggr%d' % (2*j),
                                    sw_path = sw_path,
                                    json_path = switch,
                                    thrift_port = _THRIFT_BASE_PORT + count,
                                    pcap_dump = False,
                                    device_id = count))
            count = count + 1

        for j in range (1,k+1):
            edge_switches1.append(self.addSwitch('edge%d' % (2*j-1),
                                    sw_path = sw_path,
                                    json_path = switch,
                                    thrift_port = _THRIFT_BASE_PORT + count,
                                    pcap_dump = False,
                                    device_id = count))
            count = count + 1

        for j in range (1,k+1):
            edge_switches2.append(self.addSwitch('edge%d' % (2*j),
                                    sw_path = sw_path,
                                    json_path = switch,
                                    thrift_port = _THRIFT_BASE_PORT + count,
                                    pcap_dump = False,
                                    device_id = count))
            count = count + 1

        aggr_switch.extend(aggr_switches1)
        aggr_switch.extend(aggr_switches2)
        edge_switch.extend(edge_switches1)
        edge_switch.extend(edge_switches2)

	# Core-aggregate links.
        for i, s in enumerate(core_switches1):

            for a, b in enumerate(aggr_switches1):
                    self.addLink(s, b,**linkopts)

        for i, s in enumerate(core_switches2):

            for a, b in enumerate(aggr_switches2):
                    self.addLink(s, b,**linkopts)
        # Aggregate-edge links.
        for m in range(0,k):
            for i in range (1,3):
                for j in range (1,3):
                    self.addLink(aggr_switch[k*(i-1)+m], edge_switch[k*(j-1)+m],**linkopts)

        # Create hosts and link to appropriate edge hosts.
        for i in range (1,4*k+1):
            hosts.append(self.addHost('host%d' % (i)))

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
    print("netstart end")
    sleep(2)
    print("Ready !")
    CLI( net )
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    # setLogLevel( 'debug' )
    main()