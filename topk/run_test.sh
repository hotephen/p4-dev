#!/bin/bash

distribution=z
#distribution=g

for i in `seq 1 5`
do
    screen -S mininet$i -d -m -L sudo bash ~/p4-dev/topk/topology/run_topo_daiet.sh && sleep 15
    # screen -S host16-$i -d -m -L sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 > ~/p4-dev/topk/logs/mininet/host16-$i.log
    nohup sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 --save_index 10-$i --type daiet &
    sleep 2
    sudo bash ~/p4-dev/topk/daiet/insert_rule_daiet.sh && sleep 2
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 0 --num 10 --dif '10.0.1.1' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 0 --num 10 --dif '10.0.2.1' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 0 --num 10 --dif '10.0.1.2' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth4 --si '10.0.0.4'  --num_flush 0 --num 10 --dif '10.0.3.1' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 0 --num 10 --dif '10.0.1.3' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 0 --num 10 --dif '10.0.2.3' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 0 --num 10 --dif '10.0.1.4' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth4 --si '10.0.0.8'  --num_flush 0 --num 10 --dif '10.0.3.2' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 0 --num 10 --dif '10.0.1.5' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 0 --num 10 --dif '10.0.2.6' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 0 --num 10 --dif '10.0.1.6' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth4 --si '10.0.0.12' --num_flush 0 --num 10 --dif '10.0.3.4' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 1 --daiet 1 --dif '10.0.1.1' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 1 --daiet 1 --dif '10.0.1.2' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 1 --daiet 1 --dif '10.0.1.3' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 1 --daiet 1 --dif '10.0.1.4' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 1 --daiet 1 --dif '10.0.1.5' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 1 --daiet 1 --dif '10.0.1.6' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --daiet 1 --dif '10.0.2.1' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --daiet 1 --dif '10.0.2.3' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --daiet 1 --dif '10.0.2.6' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --daiet 1 --dif '10.0.3.1' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --daiet 1 --dif '10.0.3.2' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --daiet 1 --dif '10.0.3.4' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --daiet 1 --dif '10.0.2.7' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --daiet 1 --dif '10.0.2.8' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --daiet 1 --dif '10.0.1.8' && sleep 1
    sudo kill -9 `ps -ef | grep receive.py  |  grep save_index | awk '{print $2}' ` && sleep 2
    screen -X -S mininet$i quit && sleep 2
    sudo kill -9 `ps -ef | grep simple_switch  | awk '{print $2}' ` && sleep 2
    sudo mn -c && sleep 2
done

for i in `seq 1 5`
do

    screen -S mininet$i -d -m -L sudo bash ~/p4-dev/topk/topology/run_topo_topk.sh && sleep 15
    # screen -S host16-$i -d -m -L sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 > ~/p4-dev/topk/logs/mininet/host16-$i.log
    nohup sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 --save_index 10-$i --type topk &
    sleep 2
    sudo bash ~/p4-dev/topk/insert_rule.sh && sleep 2
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 0 --num 10 --dif '10.0.1.1' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 0 --num 10 --dif '10.0.2.1' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 0 --num 10 --dif '10.0.1.2' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth4 --si '10.0.0.4'  --num_flush 0 --num 10 --dif '10.0.3.1' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 0 --num 10 --dif '10.0.1.3' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 0 --num 10 --dif '10.0.2.3' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 0 --num 10 --dif '10.0.1.4' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth4 --si '10.0.0.8'  --num_flush 0 --num 10 --dif '10.0.3.2' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 0 --num 10 --dif '10.0.1.5' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 0 --num 10 --dif '10.0.2.6' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 0 --num 10 --dif '10.0.1.6' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth4 --si '10.0.0.12' --num_flush 0 --num 10 --dif '10.0.3.4' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 1 --dif '10.0.1.1' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 1 --dif '10.0.1.2' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 1 --dif '10.0.1.3' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 1 --dif '10.0.1.4' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 1 --dif '10.0.1.5' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 1 --dif '10.0.1.6' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --dif '10.0.2.1' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --dif '10.0.2.3' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --dif '10.0.2.6' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --dif '10.0.3.1' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --dif '10.0.3.2' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --dif '10.0.3.4' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --dif '10.0.2.7' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --dif '10.0.2.8' && sleep 1
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --dif '10.0.1.8' && sleep 1
    sudo kill -9 `ps -ef | grep receive.py  | awk '{print $2}' ` && sleep 2
    screen -X -S mininet$i quit && sleep 2
    sudo kill -9 `ps -ef | grep simple_switch  | awk '{print $2}' ` && sleep 2
    sudo mn -c && sleep 2
done




for i in `seq 1 5`
do
    screen -S mininet$i -d -m -L sudo bash ~/p4-dev/topk/topology/run_topo_daiet.sh && sleep 15
    # screen -S host16-$i -d -m -L sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 > ~/p4-dev/topk/logs/mininet/host16-$i.log
    nohup sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 --save_index 100-$i --type daiet &
    sleep 2
    sudo bash ~/p4-dev/topk/daiet/insert_rule_daiet.sh && sleep 2
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 0 --num 100 --dif '10.0.1.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 0 --num 100 --dif '10.0.2.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 0 --num 100 --dif '10.0.1.2' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth4 --si '10.0.0.4'  --num_flush 0 --num 100 --dif '10.0.3.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 0 --num 100 --dif '10.0.1.3' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 0 --num 100 --dif '10.0.2.3' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 0 --num 100 --dif '10.0.1.4' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth4 --si '10.0.0.8'  --num_flush 0 --num 100 --dif '10.0.3.2' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 0 --num 100 --dif '10.0.1.5' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 0 --num 100 --dif '10.0.2.6' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 0 --num 100 --dif '10.0.1.6' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth4 --si '10.0.0.12' --num_flush 0 --num 100 --dif '10.0.3.4' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 1 --daiet 1 --dif '10.0.1.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 1 --daiet 1 --dif '10.0.1.2' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 1 --daiet 1 --dif '10.0.1.3' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 1 --daiet 1 --dif '10.0.1.4' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 1 --daiet 1 --dif '10.0.1.5' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 1 --daiet 1 --dif '10.0.1.6' && sleep 20
    # sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --daiet 1 --dif '10.0.2.1' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --daiet 1 --dif '10.0.2.3' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --daiet 1 --dif '10.0.2.6' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --daiet 1 --dif '10.0.3.1' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --daiet 1 --dif '10.0.3.2' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --daiet 1 --dif '10.0.3.4' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --daiet 1 --dif '10.0.2.7' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --daiet 1 --dif '10.0.2.8' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --daiet 1 --dif '10.0.1.8' && sleep 1
    sudo kill -9 `ps -ef | grep receive.py  | awk '{print $2}' ` && sleep 2
    screen -X -S mininet$i quit && sleep 2
    sudo kill -9 `ps -ef | grep simple_switch  | awk '{print $2}' ` && sleep 2
    sudo mn -c && sleep 2
done

for i in `seq 1 5`
do
    screen -S mininet$i -d -m -L sudo bash ~/p4-dev/topk/topology/run_topo_topk.sh && sleep 15
    # screen -S host16-100-$i -d -m -L sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 > ~/p4-dev/topk/logs/mininet/host16-100-$i.log
    nohup sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 --save_index 100-$i --type topk &
    sleep 2
    sudo bash ~/p4-dev/topk/insert_rule.sh && sleep 2
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 0 --num 100 --dif '10.0.1.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 0 --num 100 --dif '10.0.2.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 0 --num 100 --dif '10.0.1.2' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth4 --si '10.0.0.4'  --num_flush 0 --num 100 --dif '10.0.3.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 0 --num 100 --dif '10.0.1.3' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 0 --num 100 --dif '10.0.2.3' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 0 --num 100 --dif '10.0.1.4' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth4 --si '10.0.0.8'  --num_flush 0 --num 100 --dif '10.0.3.2' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 0 --num 100 --dif '10.0.1.5' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 0 --num 100 --dif '10.0.2.6' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 0 --num 100 --dif '10.0.1.6' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth4 --si '10.0.0.12' --num_flush 0 --num 100 --dif '10.0.3.4' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 1 --dif '10.0.1.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 1 --dif '10.0.1.2' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 1 --dif '10.0.1.3' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 1 --dif '10.0.1.4' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 1 --dif '10.0.1.5' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 1 --dif '10.0.1.6' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --dif '10.0.2.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --dif '10.0.2.3' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --dif '10.0.2.6' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --dif '10.0.3.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --dif '10.0.3.2' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --dif '10.0.3.4' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --dif '10.0.2.7' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --dif '10.0.2.8' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --dif '10.0.1.8' && sleep 20
    sudo kill -9 `ps -ef | grep receive.py  | awk '{print $2}' ` && sleep 2
    screen -X -S mininet$i quit && sleep 2
    sudo kill -9 `ps -ef | grep simple_switch  | awk '{print $2}' ` && sleep 2
    sudo mn -c && sleep 2
done



for i in `seq 1 5`
do
    screen -S mininet$i -d -m -L sudo bash ~/p4-dev/topk/topology/run_topo_daiet.sh && sleep 15
    # screen -S host16-$i -d -m -L sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 > ~/p4-dev/topk/logs/mininet/host16-$i.log
    nohup sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 --save_index 500-$i --type daiet &
    sleep 2
    sudo bash ~/p4-dev/topk/daiet/insert_rule_daiet.sh && sleep 2
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 0 --num 500 --dif '10.0.1.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 0 --num 500 --dif '10.0.2.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 0 --num 500 --dif '10.0.1.2' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth4 --si '10.0.0.4'  --num_flush 0 --num 500 --dif '10.0.3.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 0 --num 500 --dif '10.0.1.3' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 0 --num 500 --dif '10.0.2.3' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 0 --num 500 --dif '10.0.1.4' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth4 --si '10.0.0.8'  --num_flush 0 --num 500 --dif '10.0.3.2' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 0 --num 500 --dif '10.0.1.5' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 0 --num 500 --dif '10.0.2.6' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 0 --num 500 --dif '10.0.1.6' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth4 --si '10.0.0.12' --num_flush 0 --num 500 --dif '10.0.3.4' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 1 --daiet 1 --dif '10.0.1.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 1 --daiet 1 --dif '10.0.1.2' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 1 --daiet 1 --dif '10.0.1.3' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 1 --daiet 1 --dif '10.0.1.4' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 1 --daiet 1 --dif '10.0.1.5' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 1 --daiet 1 --dif '10.0.1.6' && sleep 20
    # sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --daiet 1 --dif '10.0.2.1' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --daiet 1 --dif '10.0.2.3' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --daiet 1 --dif '10.0.2.6' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --daiet 1 --dif '10.0.3.1' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --daiet 1 --dif '10.0.3.2' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --daiet 1 --dif '10.0.3.4' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --daiet 1 --dif '10.0.2.7' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --daiet 1 --dif '10.0.2.8' && sleep 1
    # sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --daiet 1 --dif '10.0.1.8' && sleep 1
    sudo kill -9 `ps -ef | grep receive.py  | awk '{print $2}' ` && sleep 2
    screen -X -S mininet$i quit && sleep 2
    sudo kill -9 `ps -ef | grep simple_switch  | awk '{print $2}' ` && sleep 2
    sudo mn -c && sleep 2
done

for i in `seq 1 5`
do
    screen -S mininet$i -d -m -L sudo bash ~/p4-dev/topk/topology/run_topo_topk.sh && sleep 15
    # screen -S host16-500-$i -d -m -L sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 > ~/p4-dev/topk/logs/mininet/host16-500-$i.log
    nohup sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 --save_index 500-$i --type topk &
    sleep 2
    sudo bash ~/p4-dev/topk/insert_rule.sh && sleep 2
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 0 --num 500 --dif '10.0.1.1' &&  sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 0 --num 500 --dif '10.0.2.1' &&  sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 0 --num 500 --dif '10.0.1.2' &&  sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth4 --si '10.0.0.4'  --num_flush 0 --num 500 --dif '10.0.3.1' &&  sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 0 --num 500 --dif '10.0.1.3' &&  sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 0 --num 500 --dif '10.0.2.3' &&  sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 0 --num 500 --dif '10.0.1.4' &&  sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth4 --si '10.0.0.8'  --num_flush 0 --num 500 --dif '10.0.3.2' &&  sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 0 --num 500 --dif '10.0.1.5' &&  sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 0 --num 500 --dif '10.0.2.6' &&  sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 0 --num 500 --dif '10.0.1.6' &&  sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth4 --si '10.0.0.12' --num_flush 0 --num 500 --dif '10.0.3.4' &&  sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 1 --dif '10.0.1.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 1 --dif '10.0.1.2' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 1 --dif '10.0.1.3' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 1 --dif '10.0.1.4' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 1 --dif '10.0.1.5' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 1 --dif '10.0.1.6' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --dif '10.0.2.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --dif '10.0.2.3' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --dif '10.0.2.6' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --dif '10.0.3.1' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --dif '10.0.3.2' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --dif '10.0.3.4' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --dif '10.0.2.7' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --dif '10.0.2.8' && sleep 10
    sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --dif '10.0.1.8' && sleep 20
    sudo kill -9 `ps -ef | grep receive.py  | awk '{print $2}' ` && sleep 2
    screen -X -S mininet$i quit && sleep 2
    sudo kill -9 `ps -ef | grep simple_switch  | awk '{print $2}' ` && sleep 2
    sudo mn -c && sleep 2

done