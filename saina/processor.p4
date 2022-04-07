#ifndef _PROCESSOR_
#define _PROCESSOR_

#include "types.p4"
#include "headers.p4"

// Sum calculator
// Each control handles two values
control Processor(
    in value_t value0,
    out value_t value0_out,
    inout switchml_md_h switchml_md) {

    register<bit<32>>(register_size) values;
    register<bit<32>>(register_size) values1;

    // action write_read1_action() {
    //     value1_out = write_read1_register_action.execute(switchml_md.pool_index);
    // }

    // action sum_read1_action() {
    //     value1_out = sum_read1_register_action.execute(switchml_md.pool_index);
    // }

    action read0_action() {
        // value0_out = read0_register_action.execute(switchml_md.pool_index);
        value0.read(value0_out, switchml_md.pool_index);

    }

    action write_read0_action() {
        value0.write(switchml_md.pool_index, value0);
        value_out = value0;
    }

    action sum_read0_action() {
        bit<32>read_value;
        value0.read(read_value, switchml_md.pool_index);
        value0_out = read_value + value0;
        value0.write(switchml_md.pool_index, value0_out);
    }



    // If bitmap_before is 0 and type is CONSUME0, write values and read second value
    // If bitmap_before is not zero and type is CONSUME0, add values and read second value
    // If map_result is not zero and type is CONSUME0, just read first value
    // If type is HARVEST, read second value
    table sum {
        key = {
            switchml_md.worker_bitmap_before : ternary;
            switchml_md.map_result : ternary;
            switchml_md.packet_type: ternary;
        }
        actions = {
            write_read0_action;
            sum_read0_action;
            read0_action;
            NoAction;
        }
        
        const entries = {
            (32w0,    _, packet_type_t.CONSUME0) : write_read0_action(); // first packet

            (   _, 32w0, packet_type_t.CONSUME0) : sum_read0_action(); // sum

            (   _,    _, packet_type_t.CONSUME0) : read0_action(); // retransmission

            (   _,    _, packet_type_t.HARVEST7) : read0_action(); // last pass; extract data0 slice in pipe 0
        }
        // if none of the above are true, do nothing.
        const default_action = NoAction;
    }

    apply {
        sum.apply();
    }
}

#endif /* _PROCESSOR_ */
