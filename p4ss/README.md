Terminal 1
1. $sudo simple_switch --log-console -i 0@veth0 -i 1@veth2 --thrift-port 9090 sliding_sketch_v3.json


Terminal 2
2. $sudo python receive_test.py


Terminal 3
3. Send packets


4. python plot_graph_bf.py


5. See num_active_flow.png