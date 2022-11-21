#ifndef _WORKERS_COUNTER_
#define _WORKERS_COUNTER_

control WorkersCounter(
    in header_t hdr,
    inout standard_metadata_t standard_metadata,
    inout metadata_t meta){

    register<bit<8>>(register_size) workers_count;




    // action single_worker_count_action() {
    //     workers_count.read(meta.switchml_md.first_last_flag, (bit<32>)meta.switchml_md.pool_index);
    //     meta.switchml_md.first_last_flag = 1; //because it is last in k=1

    // }

    // action single_worker_read_action() {
    //     meta.switchml_md.first_last_flag = 0;
    // }

    action count_workers_action() {
        // flag 0 -> first / flag 1 -> last / flag 2~k -> nothing /
        workers_count.read(meta.switchml_md.first_last_flag, (bit<32>)meta.switchml_md.pool_index);
        meta.action_flag = 1;
    }

    action read_count_workers_action() {
        workers_count.read(meta.switchml_md.first_last_flag, (bit<32>)meta.switchml_md.pool_index);
    }

    // If no bits are set in the map result, this was the first time we
    // saw this packet, so decrement worker count. Otherwise, it's a
    // retransmission, so just read the worker count.
    // Only act if packet type is CONSUME0
    table count_workers {
        key = {
            meta.switchml_md.num_workers: ternary;
            meta.switchml_md.map_result : ternary;
            meta.switchml_md.packet_type: ternary;
        }
        actions = {
            // single_worker_count_action;
            // single_worker_read_action;
            count_workers_action;
            read_count_workers_action;
            @defaultonly NoAction;
        }
        const entries = {
            // Special case for single-worker jobs
            // if map_result is all 0's and type is CONSUME0, this is the first time we've seen this packet
            // (1, 0, 4) : single_worker_count_action();
            // if we've seen this packet before, don't count, just read
            // (1, _, 4) : single_worker_read_action();

            // Multi-worker jobs
            // if map_result is all 0's and type is CONSUME0, this is the first time we've seen this packet
            (_, 0, 4) : count_workers_action();
            // if map_result is not all 0's and type is CONSUME0, don't count, just read
            (_, _, 4) : read_count_workers_action();
        }
        const default_action = NoAction;
    }

    apply {
        count_workers.apply();
        if(meta.action_flag==1){
            if(meta.switchml_md.first_last_flag == 0 ){ // first packet
                workers_count.write((bit<32>)meta.switchml_md.pool_index, meta.switchml_md.k - 1);
            }
            else{ // not first packet
                workers_count.write((bit<32>)meta.switchml_md.pool_index, meta.switchml_md.first_last_flag - 1);
            }
        }
    }
}

#endif /* _WORKERS_COUNTER_ */
