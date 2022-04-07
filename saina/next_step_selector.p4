#ifndef _NEXT_STEP_SELECTOR_
#define _NEXT_STEP_SELECTOR_

#include "configuration.p4"
#include "types.p4"
#include "headers.p4"

control NextStepSelector(
    inout header_t hdr,
    inout metadata_t meta){

    action recirculate_for_consume(packet_type_t packet_type, PortId_t recirc_port) {
        // Drop both data headers now that they've been consumed
        hdr.d0.setInvalid();
        // Send to recirculation port
        standard_metadata.egress_spec = recirc_port;
        meta.switchml_md.packet_type = packet_type;

    }

    action recirculate_for_harvest(packet_type_t packet_type, PortId_t recirc_port) {
        // Recirculate for harvest
        // ig_tm_md.ucast_egress_port = recirc_port;
        standard_metadata.mcast_grp = 0x0001;

        meta.switchml_md.packet_type = packet_type;

        meta.switchml_md.recirculation_type = 1;
    }

    action recirculate_for_CONSUME1(PortId_t recirc_port) {
        recirculate_for_consume(packet_type_t.CONSUME1, recirc_port);
    }

    action recirculate_for_CONSUME2_same_port_next_pipe() {
        recirculate_for_consume(packet_type_t.CONSUME2, 2w2 ++ ig_intr_md.ingress_port[6:0]);
    }

    action recirculate_for_CONSUME3_same_port_next_pipe() {
        recirculate_for_consume(packet_type_t.CONSUME3, 2w3 ++ ig_intr_md.ingress_port[6:0]);
    }

    action recirculate_for_HARVEST1(PortId_t recirc_port) {
        // hdr.d0.setInvalid();
        recirculate_for_harvest(packet_type_t.HARVEST1, recirc_port);
    }

    action recirculate_for_HARVEST2(PortId_t recirc_port) {
        // hdr.d1.setInvalid();
        recirculate_for_harvest(packet_type_t.HARVEST2, recirc_port);
    }

    action recirculate_for_HARVEST3(PortId_t recirc_port) {
        // hdr.d0.setInvalid();
        recirculate_for_harvest(packet_type_t.HARVEST3, recirc_port);
    }

    action recirculate_for_HARVEST4(PortId_t recirc_port) {
        // hdr.d1.setInvalid();
        recirculate_for_harvest(packet_type_t.HARVEST4, recirc_port);
    }

    action recirculate_for_HARVEST5(PortId_t recirc_port) {
        // hdr.d0.setInvalid();
        recirculate_for_harvest(packet_type_t.HARVEST5, recirc_port);
    }

    action recirculate_for_HARVEST6(PortId_t recirc_port) {
        // hdr.d1.setInvalid();
        recirculate_for_harvest(packet_type_t.HARVEST6, recirc_port);
    }

    action recirculate_for_HARVEST7(PortId_t recirc_port) {
        // hdr.d0.setInvalid();
        recirculate_for_harvest(packet_type_t.HARVEST7, recirc_port);
    }

    action finish_consume() {
        mark_to_drop(standard_metadata);
    }

    action broadcast() {
        // Set the switch as the source MAC address
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        // Destination address will be filled in egress pipe

        // Send to multicast group; egress will fill in destination IP and MAC address
        standard_metadata.mcast_grp = meta.switchml_md.mgid;
        meta.switchml_md.packet_type = packet_type_t.BROADCAST;

    }

    action retransmit() {
        // hdr.d1.setInvalid();

        // Send back out ingress port
        meta.egerss_spec = meta.switchml_md.ingress_port;
        meta.switchml_md.packet_type = packet_type_t.RETRANSMIT;
    }

    action drop() {
        // Mark for drop
        mark_to_drop();
        meta.switchml_md.packet_type = packet_type_t.IGNORE;
    }

    table next_step {
        key = {
            meta.switchml_md.packet_size : ternary;
            meta.switchml_md.worker_id : ternary;
            meta.switchml_md.packet_type : ternary;
            meta.switchml_md.first_last_flag : ternary; // 1: last 0: first
            meta.switchml_md.map_result : ternary;
            meta.switchml_md.round_end_flag : ternary; // FIXME:

        }
        actions = {
            recirculate_for_CONSUME1;
            recirculate_for_CONSUME2_same_port_next_pipe;
            recirculate_for_CONSUME3_same_port_next_pipe;
            recirculate_for_HARVEST1;
            recirculate_for_HARVEST2;
            recirculate_for_HARVEST3;
            recirculate_for_HARVEST4;
            recirculate_for_HARVEST5;
            recirculate_for_HARVEST6;
            recirculate_for_HARVEST7;
            finish_consume;
            broadcast;
            retransmit;
            drop;
        }

        const entries = {
            // 2. Normal last worker's gradient : last=1, map=None end_flag=0;
            (packet_size_t.IBV_MTU_256, _, packet_type_t.CONSUME0, 1, _, 0) : broadcast();

            // 1. Normal gradient : last=None, map=0, end_flag=None
            (packet_size_t.IBV_MTU_256, _, packet_type_t.CONSUME0, _, 0, _) : finish_consume();
            
            // 3. round end packet : last=1, map=0, end_flag=1;
            (packet_size_t.IBV_MTU_256, _, packet_type_t.CONSUME0, 1, 0, 1) : recirculate_for_HARVEST7(68); 

        }

        const default_action = drop();
    }

    apply {
        next_step.apply();
    }
}

#endif /* _NEXT_STEP_SELECTOR_ */
