#!/bin/bash
# make_dataset : --sort no (2)
# send_py : --dist (--parameter) (--fat_tree) (--host_number) --entry 
# receive.py : --save_index --type

# for i in `seq 1 5`
for i in 1 #`seq 1`
do

dic='fat_tree'

    for p in 1.1        #####
    do
    
        for entry in 1000 2000 3000 4000 5000 6000 7000 8000 9000 10000 #12500 20000 25000 30000        ##### check : make_dataset.py->d_max
        do
            # num=$j
            # sleep=`expr $j / 20`
            echo $entry
            
            sleep=20
            num=20000
            num_of_data=`expr $num \* 10`
            echo $num_of_data
            dist='z'


            for j in `seq 1 12`
            do
            python ~/p4-dev/topk/packets/dataset/make_dataset_hw.py --dist $dist --parameter $p --num_of_data $num_of_data --entry $entry --index $j && sleep 2
            done


            #topk
            type='topk'

            screen -S mininet$i -d -m -L sudo bash ~/p4-dev/topk/topology/run_topo_topk.sh && sleep 20
            nohup sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 --save_index fat_tree-$dist-$p-$num-$entry-$i --type topk &
            sleep 5
            sudo bash ~/p4-dev/topk/insert_rule.sh && sleep 5

            nohup sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 1  &  sleep 1 
            nohup sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 2  &  sleep 1 
            nohup sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 3  &  sleep 1 
            nohup sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth4 --si '10.0.0.4'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 4  &  sleep 1 
            nohup sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 5  &  sleep 1 
            nohup sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 6  &  sleep 1 
            nohup sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 7  &  sleep 1 
            nohup sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth4 --si '10.0.0.8'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 8  &  sleep 1 
            nohup sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 9  &  sleep 1 
            nohup sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 10 &  sleep 1 
            nohup sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 11 &  sleep 1 
            sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth4 --si '10.0.0.12'       --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 12 && sleep 30
            sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --num_flush 1 --dif '10.0.1.1' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --num_flush 1 --dif '10.0.1.2' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --num_flush 1 --dif '10.0.1.3' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --num_flush 1 --dif '10.0.1.4' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --num_flush 1 --dif '10.0.1.5' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --num_flush 1 --dif '10.0.1.6' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --dif '10.0.2.1' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --dif '10.0.2.3' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --dif '10.0.2.6' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --dif '10.0.3.1' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --dif '10.0.3.2' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --dif '10.0.3.4' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --num_flush 1 --dif '10.0.2.7' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --num_flush 1 --dif '10.0.2.8' && sleep 5 &&
            sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --num_flush 1 --dif '10.0.1.8' && sleep 40 &&
            sudo kill -9 `ps -ef | grep receive.py | grep save_index | grep -Ev 'single' | awk '{print $2}' ` && sleep 5 # kill 명령어들
            sudo kill -9 `ps -ef | grep send.py | grep nohup | grep 'device-id'  | awk '{print $2}' ` && sleep 5
            screen -X -S mininet$i quit && sleep 10
            sudo mn -c
            sleep 5

            #daiet
            # type='daiet'
            # screen -S mininet$i -d -m -L sudo bash ~/p4-dev/topk/topology/run_topo_daiet.sh && sleep 8
            # nohup sudo python ~/p4-dev/topk/packets/receive.py --i edge8-eth4 --s 0 --save_index fat_tree-$dist-$p-$num-$entry-$i --type daiet &
            # sudo bash ~/p4-dev/topk/daiet/insert_rule_daiet.sh && sleep 5

            # # # python ~/p4-dev/topk/packets/dataset/make_dataset_hw.py --dist $dist --parameter $p --num_of_data $num_of_data && sleep 5


            # nohup sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --di '10.0.0.16'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 1  &  sleep 1 
            # nohup sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth4 --si '10.0.0.2'  --di '10.0.0.16'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 2  &  sleep 1 
            # nohup sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --di '10.0.0.16'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 3  &  sleep 1 
            # nohup sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth4 --si '10.0.0.4'  --di '10.0.0.16'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 4  &  sleep 1 
            # nohup sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --di '10.0.0.16'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 5  &  sleep 1 
            # nohup sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth4 --si '10.0.0.6'  --di '10.0.0.16'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 6  &  sleep 1 
            # nohup sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --di '10.0.0.16'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 7  &  sleep 1 
            # nohup sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth4 --si '10.0.0.8'  --di '10.0.0.16'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 8  &  sleep 1 
            # nohup sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --di '10.0.0.16'  --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 9  &  sleep 1 
            # nohup sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth4 --si '10.0.0.10' --di '10.0.0.16' --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 10 & sleep 1 
            # nohup sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --di '10.0.0.16' --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 11 & sleep 1 
            # sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth4 --si '10.0.0.12'       --di '10.0.0.16' --dist $dist --parameter $p --num $num --entry $entry --fat_tree 1 --host_num 12 && sleep 30

            # sudo python ~/p4-dev/topk/packets/send.py --i edge1-eth3 --si '10.0.0.1'  --di '10.0.0.16' --num_flush 1 --daiet 1 --dif '10.0.1.1' && sleep 5  &&
            # sudo python ~/p4-dev/topk/packets/send.py --i edge2-eth3 --si '10.0.0.3'  --di '10.0.0.16' --num_flush 1 --daiet 1 --dif '10.0.1.2' && sleep 5  && 
            # sudo python ~/p4-dev/topk/packets/send.py --i edge3-eth3 --si '10.0.0.5'  --di '10.0.0.16' --num_flush 1 --daiet 1 --dif '10.0.1.3' && sleep 5  && 
            # sudo python ~/p4-dev/topk/packets/send.py --i edge4-eth3 --si '10.0.0.7'  --di '10.0.0.16' --num_flush 1 --daiet 1 --dif '10.0.1.4' && sleep 5  && 
            # sudo python ~/p4-dev/topk/packets/send.py --i edge5-eth3 --si '10.0.0.9'  --di '10.0.0.16' --num_flush 1 --daiet 1 --dif '10.0.1.5' && sleep 5  && 
            # sudo python ~/p4-dev/topk/packets/send.py --i edge6-eth3 --si '10.0.0.11' --di '10.0.0.16' --num_flush 1 --daiet 1 --dif '10.0.1.6' && sleep 40 &&
            # sudo kill -9 `ps -ef | grep send.py | grep nohup | grep 'device-id'  | awk '{print $2}' ` && sleep 3
            # screen -X -S mininet$i quit && sleep 10
            # sudo kill -9 `ps -ef | grep receive.py | grep save_index | grep -Ev 'single' | awk '{print $2}' ` && sleep 3
            # sudo mn -c 
            # sleep 5

            

        done
    done
done




#sudo simple_switch -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 --thrift-port 9090 --log-console ~/p4-dev/topk/topk_for_daiet.json
#simple_switch_CLI --thrift-port 9090 < ~/p4-dev/topk/rule/topk_rule
#sudo python ~/p4-dev/topk/packets/receive.py --i veth4 --s 0 --type topk
##python ~/p4-dev/topk/packets/dataset/make_dataset_hw.py --dist 'z' --parameter 1.1
#sudo python ~/p4-dev/topk/packets/send.py --i veth0 --di '10.0.0.16' --num 1000 --dif '10.0.1.1' --num_flush 1 --dist z --entry 3000 --parameter 1.1 --sort 3
