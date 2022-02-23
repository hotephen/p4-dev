## Terminal 1
`$sudo simple_switch --log-console -i 0@veth0 -i 1@veth2 --thrift-port 9090 sliding_sketch_v3.json`


## Terminal 2
`$sudo python receive_test.py`


## Terminal 3
Send packets


`python plot_graph_bf.py`


See num_active_flow.png
