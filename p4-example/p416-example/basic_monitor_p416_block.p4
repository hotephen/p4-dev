#include <v1model.p4>
#include <core.p4>




header pkt_id_t {
    bit<32> id;
    bit<32> next_id;
}



register<bit<32>> pkt_id_reg;

action read_id_from_reg() {
    // read id from register
    set_pkt_id_reg.read(pkt_id.id, 0);
    // plus the register value
    pkt_id.next_id = pkt_id.id + 1;
    set_pkt_id_reg.write(0, pkt_id_next_id);
}

action send_to_monitor(egressSpec_t port) {
    
    set_pkt_id_reg.write(0, 0); // initialize to 0
    standard_metadata.egress_spec = port;
}

table set_pkt_id {
    actions = {
        send_to_monitor;
    }
    default_action = 
}

table basic_monitor {
    key = {
        pkt_id.id : exact;
    }
    actions = {
        send_to_monitor;
    }

}

// control MyIngress
control process_basic_monitor(inout headers header,
                               inout metadata meta,
                               inout standard_metadata_t standard_metadata) {

	apply(set_pkt_id);
	apply(basic_monitor);
}