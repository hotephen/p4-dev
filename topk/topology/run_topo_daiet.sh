##########################
BMV2_PATH=~/p4/behavioral-model
P4C_BM_PATH=~/p4/p4c-bm
##########################

THIS_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

P4C_BM_SCRIPT=$P4C_BM_PATH/p4c_bm/__main__.py
SWITCH_PATH=$BMV2_PATH/targets/simple_switch/simple_switch
CLI_PATH=$BMV2_PATH/targets/simple_switch/sswitch_CLI

sudo PYTHONPATH=$PYTHONPATH:$BMV2_PATH/mininet/ python ~/p4-dev/topk/topology/topo_topk_hw.py \
    --behavioral-exe $BMV2_PATH/targets/simple_switch/simple_switch \
    --switch ~/p4-dev/topk/daiet/daiet_bmv2.json \
    --cli $CLI_PATH 