#!/bin/bash

num=$1
sleep='10'

screen -S mininet -d -m -L sudo bash ~/p4-dev/topk/topology/run_topo_daiet.sh && sleep 8
nohup sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 --save_index $num-test --type daiet &
sleep 2
sudo bash ~/p4-dev/topk/daiet/insert_rule_daiet.sh && sleep 2
sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 0 --num $num --dif '10.0.1.1' && sleep 5
sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 0 --num $num --dif '10.0.2.1' && sleep 5
sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 0 --num $num --dif '10.0.1.2' && sleep 5
sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth4 --si '10.0.0.4'  --num_flush 0 --num $num --dif '10.0.3.1' && sleep 5
sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 0 --num $num --dif '10.0.1.3' && sleep 5
sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 0 --num $num --dif '10.0.2.3' && sleep 5
sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 0 --num $num --dif '10.0.1.4' && sleep 5
sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth4 --si '10.0.0.8'  --num_flush 0 --num $num --dif '10.0.3.2' && sleep 5
sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 0 --num $num --dif '10.0.1.5' && sleep 5
sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 0 --num $num --dif '10.0.2.6' && sleep 5
sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 0 --num $num --dif '10.0.1.6' && sleep 5
sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth4 --si '10.0.0.12' --num_flush 0 --num $num --dif '10.0.3.4' && sleep 5

sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 1 --daiet 1 --dif '10.0.1.1' && sleep $sleep
sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 1 --daiet 1 --dif '10.0.1.2' && sleep $sleep
sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 1 --daiet 1 --dif '10.0.1.3' && sleep $sleep
sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 1 --daiet 1 --dif '10.0.1.4' && sleep $sleep
sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 1 --daiet 1 --dif '10.0.1.5' && sleep $sleep
sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 1 --daiet 1 --dif '10.0.1.6' && sleep $sleep
sudo kill -9 `ps -ef | grep receive.py | grep save_index |  awk '{print $2}' ` && sleep 2
screen -X -S mininet$i quit && sleep 2
sudo mn -c && sleep 2
