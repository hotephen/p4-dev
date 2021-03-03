# sudo bash ~/p4-dev/topk/topology/delete_interface.sh

for i in 1 2 3 4 5 6 7 8
do
    for j in 1 2 3 4
    do
        sudo ip link delete aggr$i-eth$j
    done
done

for i in 1 2 3 4
do
    for j in 1 2 3 4
    do
        sudo ip link delete edge$i-eth$j
    done
done

for i in 1 2 3 4
do
    for j in 3 4
    do
        sudo ip link delete core$i-eth$j
    done
done

# sudo ip link delete aggr1-eth1
# sudo ip link delete aggr1-eth2
# sudo ip link delete aggr1-eth3

# sudo ip link delete aggr2-eth1
# sudo ip link delete aggr2-eth2
# sudo ip link delete aggr2-eth3

# sudo ip link delete aggr3-eth1
# sudo ip link delete aggr3-eth2
# sudo ip link delete aggr3-eth3

# sudo ip link delete aggr4-eth1
# sudo ip link delete aggr4-eth2
# sudo ip link delete aggr4-eth3

# sudo ip link delete edge1-eth3
# sudo ip link delete edge1-eth4

# sudo ip link delete edge2-eth3
# sudo ip link delete edge2-eth4

# sudo ip link delete edge3-eth3
# sudo ip link delete edge3-eth4

# sudo ip link delete edge4-eth3
# sudo ip link delete edge4-eth4


# sudo ip link delete core1-eth3
# sudo ip link delete core1-eth4
# sudo ip link delete core2-eth3
# sudo ip link delete core2-eth4
# sudo ip link delete core3-eth3
# sudo ip link delete core3-eth4
# sudo ip link delete core4-eth3
# sudo ip link delete core4-eth4