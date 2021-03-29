##########################
BMV2_PATH=~/behavioral-model
# P4C_BM_PATH=~/p4c-bm
##########################

# P4C_BM_SCRIPT=$P4C_BM_PATH/p4c_bm/__main__.py
# $P4C_BM_SCRIPT deadline.p4 --json deadline.json
# $P4C_BM_SCRIPT bft_server.p4 --json bft_server.json
# $P4C_BM_SCRIPT bft_client.p4 --json bft_client.json
# $P4C_BM_SCRIPT l2switch.p4 --json switch.json

THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
SWITCH_PATH=$BMV2_PATH/targets/simple_switch/simple_switch
CLI_PATH=$BMV2_PATH/targets/simple_switch/sswitch_CLI


sudo PYTHONPATH=$PYTHONPATH:$BMV2_PATH/mininet/ python ~/p4-dev/deadline/topology/topo_deadline_topk.py \
    --behavioral-exe $BMV2_PATH/targets/simple_switch/simple_switch \
    --switch ~/p4-dev/deadline/deadline.json \
    --cli $CLI_PATH 