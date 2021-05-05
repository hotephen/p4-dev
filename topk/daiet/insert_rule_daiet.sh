
# edge1~8

port_aggr[1]=9305
port_aggr[2]=9309
port_aggr[3]=9306
port_aggr[4]=9310
port_aggr[5]=9307
port_aggr[6]=9311
port_aggr[7]=9308
port_aggr[8]=9312

port_edge[1]=9313
port_edge[2]=9317
port_edge[3]=9314
port_edge[4]=9318
port_edge[5]=9315
port_edge[6]=9319
port_edge[7]=9316 
port_edge[8]=9320

port_core[1]=9301
port_core[2]=9302
port_core[3]=9303
port_core[4]=9304


for i in `seq 1 8`
do
    sudo simple_switch_CLI --thrift-port ${port_aggr[$i]} < ~/p4-dev/topk/daiet/rule/aggr/aggr$i
done

for i in `seq 1 8`
do
    sudo simple_switch_CLI --thrift-port ${port_edge[$i]} < ~/p4-dev/topk/daiet/rule/edge/edge$i
done

for i in `seq 1 4`
do
    sudo simple_switch_CLI --thrift-port ${port_core[$i]} < ~/p4-dev/topk/daiet/rule/core/core$i
done