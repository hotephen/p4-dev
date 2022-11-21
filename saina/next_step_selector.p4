#ifndef _NEXT_STEP_SELECTOR_
#define _NEXT_STEP_SELECTOR_

#include "configuration.p4"
#include "types.p4"
#include "headers.p4"

control NextStepSelector(
    inout header_t hdr,
    inout standard_metadata_t standard_metadata,
    inout metadata_t meta){

    action recirculate_for_consume(bit<4> packet_type, bit<9> recirc_port) {
        // Drop both data headers now that they've been consumed
        hdr.d0.setInvalid();
        // Send to recirculation port
        standard_metadata.egress_spec = recirc_port;
        meta.switchml_md.packet_type = packet_type;

    }

    action recirculate_for_harvest(bit<4> packet_type, bit<9> recirc_port) {
        // Recirculate for harvest
        // ig_tm_md.ucast_egress_port = recirc_port;
        standard_metadata.mcast_grp = 0x0001;

        meta.switchml_md.packet_type = packet_type;

        meta.switchml_md.recirculation_type = 1;
    }

    action recirculate_for_HARVEST7(bit<9> recirc_port) {
        // hdr.d0.setInvalid();
        recirculate_for_harvest(0xf, recirc_port);
    }

    action finish_consume() {
        mark_to_drop(standard_metadata);
        meta.drop_flag = 1;
    }

    action broadcast() {
        // Set the switch as the source MAC address
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        // Destination address will be filled in egress pipe

        // standard_metadata.mcast_grp = meta.switchml_md.mgid;
        standard_metadata.egress_spec = TEST_OUTPUT_PORT;
        meta.switchml_md.packet_type = 1;

    }

    action trigger_ABWD(){
        meta.switchml_md.recirculation_type = 1;
    }

    action retransmit() {
        // hdr.d1.setInvalid();

        // Send back out ingress port
        // standard_metadata.egress_spec = meta.switchml_md.ingress_port; // FIXME
        standard_metadata.egress_spec = TEST_OUTPUT_PORT; // :FIXME
        meta.switchml_md.packet_type = 2;
        hdr.switchml.packet_type = (bit<8>)meta.switchml_md.packet_type;
    }

    action drop() {
        // Mark for drop
        mark_to_drop(standard_metadata);
        meta.drop_flag = 1;
        meta.switchml_md.packet_type = 3;
    }

    table next_step {
        key = {
            meta.switchml_md.packet_size : ternary;
            meta.switchml_md.worker_id : ternary;
            meta.switchml_md.packet_type : ternary;
            meta.switchml_md.first_last_flag : ternary; // 1: last 0: first
            meta.switchml_md.map_result : ternary;
            meta.switchml_md.round_end_flag : ternary; // FIXME:
            meta.switchml_md.k : ternary;
            meta.switchml_md.round : ternary;


        }
        actions = {
            recirculate_for_HARVEST7;
            trigger_ABWD;
            finish_consume;
            broadcast;
            retransmit;
            drop;
        }

        const entries = {
            // 2. Normal last worker's gradient : last=1, map=None end_flag=0;
            (_, _, 4, 1, 0, _, _, _) : broadcast();

            // 1. Normal gradient : last=None, map=0, end_flag=None
            (_, _, 4, _, 0, _, 1, _) : broadcast();
            (_, _, 4, _, 0, _, _, _) : finish_consume();

            (_, _, 4, 0, _, _, _, _) : retransmit(); // global gradient completed and retransmission packet comes
            (_, _, 4, _, _, _, _, _) : drop(); // aggregation is not yet completed but retransmission packet comes
            
            // 3. round end packet : last=1, map=0, end_flag=1;
            // (0, _, 4, 1, 0, 1) : recirculate_for_HARVEST7(68); 
            // (0, _, 4, 1, 0, 1) : trigger_ABWD(); 

        }

        const default_action = drop();
    }

    apply {
        next_step.apply();
    }
}

#endif /* _NEXT_STEP_SELECTOR_ */
