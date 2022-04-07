#ifndef _WORKERS_COUNTER_
#define _WORKERS_COUNTER_

control WorkersCounter(
    in header_t hdr,
    inout metadata_t ig_md){

    register<bit<8>>(register_size) workers_count;

    action count_workers_action() {
        // flag 0 -> first / flag 1 -> last / flag 2~k -> nothing /
        workers_count.read(meta.switchml_md.first_last_flag, meta.switchml_md.pool_index);
        if(meta.switchml_md.first_last_flag == 0 ){
            workers_count.write(meta.switchml_md.pool_index, meta.switchml_md.k - 1);
        }
        else{
            workers_count.write(meta.switchml_md.pool_index, meta.switchml_md.first_last_flag - 1);
        }
    }

    action single_worker_count_action() {
        workers_count.read(meta.switchml_md.first_last_flag, meta.switchml_md.pool_index);
        if(meta.switchml_md.first_last_flag == 0 ){
            workers_count.write(meta.switchml_md.pool_index, meta.switchml_md.k - 1);
        }
        else{
            workers_count.write(meta.switchml_md.pool_index, meta.switchml_md.first_last_flag - 1);
        }
        meta.switchml_md.first_last_flag = 1; //because it is last in k=1

    }

    action single_worker_read_action() {
        meta.switchml_md.first_last_flag = 0;
    }

    action read_count_workers_action() {
        workers_count.read(meta.switchml_md.first_last_flag, meta.switchml_md.pool_index);
    }

    // If no bits are set in the map result, this was the first time we
    // saw this packet, so decrement worker count. Otherwise, it's a
    // retransmission, so just read the worker count.
    // Only act if packet type is CONSUME0
    table count_workers {
        key = {
            ig_md.switchml_md.num_workers: ternary;
            ig_md.switchml_md.map_result : ternary;
            ig_md.switchml_md.packet_type: ternary;
        }
        actions = {
            single_worker_count_action;
            single_worker_read_action;
            count_workers_action;
            read_count_workers_action;
            @defaultonly NoAction;
        }
        const entries = {
            // Special case for single-worker jobs
            // if map_result is all 0's and type is CONSUME0, this is the first time we've seen this packet
            (1, 0, packet_type_t.CONSUME0) : single_worker_count_action();
            (1, 0, packet_type_t.CONSUME1) : single_worker_count_action();
            (1, 0, packet_type_t.CONSUME2) : single_worker_count_action();
            (1, 0, packet_type_t.CONSUME3) : single_worker_count_action();

            // if we've seen this packet before, don't count, just read
            (1, _, packet_type_t.CONSUME0) : single_worker_read_action();
            (1, _, packet_type_t.CONSUME1) : single_worker_read_action();
            (1, _, packet_type_t.CONSUME2) : single_worker_read_action();
            (1, _, packet_type_t.CONSUME3) : single_worker_read_action();

            // Multi-worker jobs
            // if map_result is all 0's and type is CONSUME0, this is the first time we've seen this packet
            (_, 0, packet_type_t.CONSUME0) : count_workers_action();
            (_, 0, packet_type_t.CONSUME1) : count_workers_action();
            (_, 0, packet_type_t.CONSUME2) : count_workers_action();
            (_, 0, packet_type_t.CONSUME3) : count_workers_action();
            // if map_result is not all 0's and type is CONSUME0, don't count, just read
            (_, _, packet_type_t.CONSUME0) : read_count_workers_action();
            (_, _, packet_type_t.CONSUME1) : read_count_workers_action();
            (_, _, packet_type_t.CONSUME2) : read_count_workers_action();
            (_, _, packet_type_t.CONSUME3) : read_count_workers_action();
        }
        const default_action = NoAction;
    }

    apply {
        count_workers.apply();
    }
}

#endif /* _WORKERS_COUNTER_ */
