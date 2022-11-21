#ifndef _UDP_RECEIVER_
#define _UDP_RECEIVER_

#include "configuration.p4"
#include "types.p4"
#include "headers.p4"

control UDPReceiver(
    inout header_t hdr,
    inout standard_metadata_t standard_metadata,
    inout metadata_t meta){

    // Packet was received with errors; set drop bit in deparser metadata
    action drop() {
        mark_to_drop(standard_metadata);
        meta.drop_flag = 1;
    }

    // This is a regular packet; just forward
    action forward() {
        meta.switchml_md.packet_type = 3;
    }

    action set_bitmap(
        bit<16> mgid,
        bit<2> worker_type, // worker_type_t worker_type,
        bit<16> worker_id, // worker_id_t worker_id,
        bit<4> packet_type, 
        bit<8> num_workers, // num_workers_t num_workers,
        bit<32> worker_bitmap, // worker_bitmap_t worker_bitmap,
        bit<15> pool_base,
        bit<16> pool_size_minus_1) {

        // Bitmap representation for this worker
        meta.worker_bitmap           = worker_bitmap;
        meta.switchml_md.num_workers = num_workers;

        // Group ID for this job
        meta.switchml_md.mgid = mgid; // 0

        // Record packet size for use in recirculation
        meta.switchml_md.packet_size = hdr.switchml.size;
        
        meta.switchml_md.round_end_flag = hdr.switchml.round_end_flag; //FIXME:
        meta.switchml_md.round = hdr.switchml.round; //FIXME:

        meta.switchml_md.worker_type = worker_type;
        meta.switchml_md.worker_id = worker_id;
        meta.switchml_md.dst_port = hdr.udp.src_port;
        meta.switchml_md.src_port = hdr.udp.dst_port;
        meta.switchml_md.tsi = hdr.switchml.tsi;
        meta.switchml_md.job_number = hdr.switchml.job_number;
        // ig_md.fastest.packet_id = hdr.switchml.packet_id; //FIXME:

        // Get rid of headers we don't want to recirculate
        hdr.ethernet.setInvalid();
        hdr.ipv4.setInvalid();
        hdr.udp.setInvalid();
        // hdr.switchml.setInvalid();
        // hdr.sign_header.setInvalid(); //FIXME:
        meta.fastest.setValid(); //FIXME:

        // Move the SwitchML set bit in the MSB to the LSB. TODO move set bit to MSB
        meta.switchml_md.pool_index = hdr.switchml.pool_index[13:0] ++ hdr.switchml.pool_index[15:15];

        // Use the SwitchML set bit in the MSB to switch between sets
        meta.pool_set = hdr.switchml.pool_index[15:15];
    }

    table receive_udp {
        key = {
            // use ternary matches to support matching on:
            // * ingress port only like the original design
            // * source IP and UDP destination port for the SwitchML Eth protocol
            // * source IP and UDP destination port for the SwitchML UDP protocol
            // * source IP and destination QP number for the RoCE protocols
            // * also, parser error values so we can drop bad packets
            standard_metadata.ingress_port   : ternary;
            hdr.ethernet.src_addr     : ternary;
            hdr.ethernet.dst_addr     : ternary;
            hdr.ipv4.src_addr         : ternary;
            hdr.ipv4.dst_addr         : ternary;
            hdr.udp.dst_port          : ternary;
            // hdr.ib_bth.partition_key  : ternary;
            // hdr.ib_bth.dst_qp         : ternary;
        }

        actions = {
            drop;
            set_bitmap;
            @defaultonly forward;
        }

        const entries = {
            (0, _, _, _, _, 48864) : set_bitmap(1, 0, 0, 1, 16, 1,    0, 0);
            (1, _, _, _, _, 48864) : set_bitmap(1, 0, 1, 1, 16, 1<<1, 0, 0);
            (2, _, _, _, _, 48864) : set_bitmap(1, 0, 2, 1, 16, 1<<2, 0, 0);
            (3, _, _, _, _, 48864) : set_bitmap(1, 0, 3, 1, 16, 1<<3, 0, 0);
            (4, _, _, _, _, 48864) : set_bitmap(1, 0, 4, 1, 16, 1<<4, 0, 0);
            (5, _, _, _, _, 48864) : set_bitmap(1, 0, 4, 1, 16, 1<<5, 0, 0);
            (6, _, _, _, _, 48864) : set_bitmap(1, 0, 4, 1, 16, 1<<6, 0, 0);
            (7, _, _, _, _, 48864) : set_bitmap(1, 0, 4, 1, 16, 1<<7, 0, 0);
            (8, _, _, _, _, 48864) : set_bitmap(1, 0, 4, 1, 16, 1<<8, 0, 0);
            (9, _, _, _, _, 48864) : set_bitmap(1, 0, 4, 1, 16, 1<<9, 0, 0);
            (10, _, _, _, _, 48864) : set_bitmap(1, 0, 4, 1, 16, 1<<10, 0, 0);
            (11, _, _, _, _, 48864) : set_bitmap(1, 0, 4, 1, 16, 1<<11, 0, 0);
            (12, _, _, _, _, 48864) : set_bitmap(1, 0, 4, 1, 16, 1<<12, 0, 0);
            (13, _, _, _, _, 48864) : set_bitmap(1, 0, 4, 1, 16, 1<<13, 0, 0);
            (14, _, _, _, _, 48864) : set_bitmap(1, 0, 4, 1, 16, 1<<14, 0, 0);
            (15, _, _, _, _, 48864) : set_bitmap(1, 0, 4, 1, 16, 1<<15, 0, 0);
            // 1 mgid, 2 worker_type, 3 worker_id, 4 packet_type, 5 num_workers, 6 worker_bitmap, pool_base, pool_size_minus_1
        }


        const default_action = forward;

        // Create some extra table space to support parser error entries
        // size = max_num_workers + 16;

    }

    apply {
        receive_udp.apply();
    }
}

#endif /* _UDP_RECEIVER_ */
