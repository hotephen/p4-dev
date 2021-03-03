#!/bin/bash

for i in 1 # `seq 1 1`
do
    for p in 1.1
    do
    for num in 2000
    do
    num_of_data=`expr $num \* 10`

        for entry in 1000
        do
        dist='z'
        python ~/p4-dev/topk/packets/dataset/make_dataset_hw.py --dist $dist --parameter $p --num_of_data $num_of_data --sort 1 &&
        python ~/p4-dev/topk/packets/dataset/make_dataset_hw.py --dist $dist --parameter $p --num_of_data $num_of_data &&

        for sort in 1 2 3
        do

        #topk
        nohup sudo simple_switch -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 --thrift-port 9090 --log-console ~/p4-dev/topk/topk_for_daiet.json & sleep 5
        simple_switch_CLI --thrift-port 9090 < ~/p4-dev/topk/rule/topk_rule &&
        nohup sudo python ~/p4-dev/topk/packets/receive.py --i veth4 --s 0 --save_index single-$num-$dist-$entry-$p-$sort-$i --type topk & sleep 3
        # python ~/p4-dev/topk/packets/dataset/make_dataset_hw.py --dist 'z' --parameter $p && sleep 1
        sudo python ~/p4-dev/topk/packets/send.py --i veth0 --di '10.0.0.16' --num $num --dif '10.0.1.1' --num_flush 1 --dist z --entry $entry --parameter $p --sort $sort &&
        sleep 10
        sudo kill -9 `ps -ef | grep receive.py  | grep single- | awk '{print $2}' ` && sleep 1
        sudo kill -9 `ps -ef | grep simple_switch  | grep '9090' | awk '{print $2}' ` && sleep 5

        #daiet
        nohup sudo simple_switch -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 --thrift-port 9090 --log-console ~/p4-dev/topk/daiet/daiet_bmv2.json & sleep 5        
        simple_switch_CLI --thrift-port 9090 < ~/p4-dev/topk/daiet/rule/commands.txt &&
        nohup sudo python ~/p4-dev/topk/packets/receive.py --i veth2 --s 0 --save_index single-$num-$dist-$entry-$p-$sort-$i --type daiet & sleep 3
        # python ~/p4-dev/topk/packets/dataset/make_dataset_hw.py --dist 'z' --parameter $p && sleep 1
        sudo python ~/p4-dev/topk/packets/send.py --i veth0 --di '10.0.0.16' --num $num --dif '10.0.1.1' --num_flush 1 --dist z --entry $entry --parameter $p --sort $sort --daiet 1 &&
        sleep 10
        sudo kill -9 `ps -ef | grep receive.py  | grep single- | awk '{print $2}' ` && sleep 1
        sudo kill -9 `ps -ef | grep simple_switch  | grep '9090' | awk '{print $2}' ` && sleep 3
        
        done
        done
    done
    done

    # for k in 1
    # do
    #     for num in 1000
    #     do
    #         for entry in 1000 3000 5000
    #         do

    #         dist='u'

    #         #topk
    #         nohup sudo simple_switch -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 --thrift-port 9090 --log-console ~/p4-dev/topk/topk_for_daiet.json &
    #         sleep 5
    #         simple_switch_CLI --thrift-port 9090 < ~/p4-dev/topk/rule/topk_rule &&
    #         nohup sudo python ~/p4-dev/topk/packets/receive.py --i veth4 --s 0 --save_index single-$num-$dist-$entry-$i --type topk &
    #         sleep 3
    #         python ~/p4-dev/topk/packets/dataset/make_dataset_hw.py --dist 'u' &&
    #         sleep 1
    #         sudo python ~/p4-dev/topk/packets/send.py --i veth0 --di '10.0.0.16' --num $num --dif '10.0.1.1' --num_flush 1 --dist $dist --entry $entry && 
    #         sleep 10
    #         sudo kill -9 `ps -ef | grep receive.py  | grep single- | awk '{print $2}' ` && sleep 1
    #         sudo kill -9 `ps -ef | grep simple_switch  | grep '9090' | awk '{print $2}' ` && sleep 3

    #         #daiet
    #         nohup sudo simple_switch -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 --thrift-port 9090 ~/p4-dev/topk/daiet/daiet_bmv2.json &
    #         sleep 5
    #         simple_switch_CLI --thrift-port 9090 < ~/p4-dev/topk/daiet/rule/commands.txt &&
    #         nohup sudo python ~/p4-dev/topk/packets/receive.py --i veth2 --s 0 --save_index single-$num-$dist-$entry-$i --type daiet &
    #         sleep 3
    #         python ~/p4-dev/topk/packets/dataset/make_dataset_hw.py --dist 'u' &&
    #         sleep 1
    #         sudo python ~/p4-dev/topk/packets/send.py --i veth0 --di '10.0.0.16' --num $num --dif '10.0.1.1' --num_flush 1 --dist $dist --daiet 1 --entry $entry &&
    #         sleep 10
    #         sudo kill -9 `ps -ef | grep receive.py  | grep single- | awk '{print $2}' ` && sleep 1
    #         sudo kill -9 `ps -ef | grep simple_switch  | grep '9090' | awk '{print $2}' ` && sleep 3

    #         done
        # done
    # done
done

### single switch test_command
# sudo simple_switch -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 --thrift-port 9090 --log-console ~/p4-dev/topk/topk_for_daiet.json
# simple_switch_CLI --thrift-port 9090 < ~/p4-dev/topk/rule/topk_rule 
# sudo python ~/p4-dev/topk/packets/receive.py --i veth4 --s 0 --type topk
# python ~/p4-dev/topk/packets/dataset/make_dataset_hw.py --dist 'z' --parameter 1.1 
# sudo python ~/p4-dev/topk/packets/send.py --i veth0 --di '10.0.0.16' --num 1000 --dif '10.0.1.1' --num_flush 1 --dist z --entry 3000 --parameter 1.1 --sort 3

# sudo simple_switch -i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 --thrift-port 9090 --log-console ~/p4-dev/topk/daiet/daiet_bmv2.json
# simple_switch_CLI --thrift-port 9090 < ~/p4-dev/topk/daiet/rule/commands.txt
# sudo python ~/p4-dev/topk/packets/receive.py --i veth2 --s 0 --type daiet
# sudo python ~/p4-dev/topk/packets/send.py --i veth0 --di '10.0.0.16' --num 1000 --dif '10.0.1.1' --num_flush 1 --dist z --entry 3000 --parameter 1.1 --sort 3 --daiet 1 
# python ~/p4-dev/topk/packets/dataset/make_dataset_hw.py --dist 'z' --parameter $p && sleep 1
