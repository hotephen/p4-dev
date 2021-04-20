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
_THRIFT_BASE_PORT = 9090

parser = argparse.ArgumentParser(description='Mininet demo')
parser.add_argument('--behavioral-exe', help='Path to behavioral executable',
                    type=str, action="store", required=True)
parser.add_argument('--switch', help='Path to bftswitch JSON config file',
                    type=str, action="store", required=True)                    
parser.add_argument('--cli', help='Path to BM CLI',
                    type=str, action="store", required=True)

args = parser.parse_args()

class MyTopo(Topo):
    def __init__(self, sw_path, switch, **opts):
        # Initialize topology and default options
        Topo.__init__(self, **opts)

        hosts = []
        switches = []
        linkopts = dict(bw=1, delay='1ms', loss=0, use_htb=True)

        switches.append(self.addSwitch('sw0',
                                    sw_path = sw_path,
                                    json_path = switch,
                                    thrift_port = _THRIFT_BASE_PORT,
                                    pcap_dump = False,
                                    device_id = 1))
        
        for i in range(1,12):
            hosts.append(self.addHost('host%d' % (i), ip='10.0.1.%d' % (i), mac='00:00:00:00:00:0%d' % (i) ))
            self.addLink(hosts[i-1], switches[0], **linkopts)
        

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
    main()
