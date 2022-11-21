#ifndef _BITMAP_CHECKER_
#define _BITMAP_CHECKER_

control ReconstructWorkerBitmap(
    inout metadata_t meta) {

    action reconstruct_worker_bitmap_from_worker_id(worker_bitmap_t bitmap) {
        meta.worker_bitmap = bitmap;
    }

    table reconstruct_worker_bitmap {
        key = {
            meta.switchml_md.worker_id : ternary;
        }
        actions = {
            reconstruct_worker_bitmap_from_worker_id;
        }
        const entries = {
            0  &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 0);
            1  &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 1);
            2  &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 2);
            3  &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 3);
            4  &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 4);
            5  &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 5);
            6  &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 6);
            7  &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 7);
            8  &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 8);
            9  &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 9);
            10 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 10);
            11 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 11);
            12 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 12);
            13 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 13);
            14 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 14);
            15 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 15);
            16 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 16);
            17 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 17);
            18 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 18);
            19 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 19);
            20 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 20);
            21 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 21);
            22 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 22);
            23 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 23);
            24 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 24);
            25 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 25);
            26 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 26);
            27 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 27);
            28 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 28);
            29 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 29);
            30 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 30);
            31 &&& 0x1f : reconstruct_worker_bitmap_from_worker_id(1 << 31);
        }
    }

    apply {
        reconstruct_worker_bitmap.apply();
    }
}

control UpdateAndCheckWorkerBitmap(
    inout header_t hdr,
    inout metadata_t meta) {

    register<bit<32>>(num_slots) worker_bitmap;
    register<bit<32>>(num_slots) worker_bitmap1;
    
    action drop() {
        // mark_to_drop(standard_metadata);
        meta.drop_flag = 1;
    }


    action check_worker_bitmap_action() {
        // Set map result to nonzero if this packet is a retransmission
        meta.switchml_md.map_result = meta.switchml_md.worker_bitmap_before & meta.worker_bitmap;
    }

    action update_worker_bitmap_set0_action() {
        bit<32> read_value;
        worker_bitmap.read(read_value, (bit<32>)meta.switchml_md.pool_index[14:1]);
        meta.switchml_md.worker_bitmap_before = read_value;
        read_value = read_value | meta.worker_bitmap;
        worker_bitmap.write((bit<32>)meta.switchml_md.pool_index[14:1], read_value);

        bit<32> read_value1;
        worker_bitmap1.read(read_value1 , (bit<32>)meta.switchml_md.pool_index[14:1]);
        read_value1 = read_value1 & (~meta.worker_bitmap) ;
        worker_bitmap1.write((bit<32>)meta.switchml_md.pool_index[14:1], read_value1);

        check_worker_bitmap_action();
    }

    action update_worker_bitmap_set1_action() {
        bit<32> read_value1;
        worker_bitmap1.read(read_value1, (bit<32>)meta.switchml_md.pool_index[14:1]);
        meta.switchml_md.worker_bitmap_before = read_value1;
        read_value1 = read_value1 | meta.worker_bitmap;
        worker_bitmap1.write((bit<32>)meta.switchml_md.pool_index[14:1], read_value1);

        bit<32> read_value;
        worker_bitmap.read(read_value, (bit<32>)meta.switchml_md.pool_index[14:1]);
        read_value = read_value & (~meta.worker_bitmap) ;
        worker_bitmap.write((bit<32>)meta.switchml_md.pool_index[14:1], read_value);

        check_worker_bitmap_action();
    }

    table update_and_check_worker_bitmap {
        key = {
            meta.switchml_md.pool_index : ternary;
            meta.switchml_md.packet_type : ternary; // only act on packets of type CONSUME0
            // meta.port_metadata.ingress_drop_probability : ternary; // if nonzero, drop packet
        }
        actions = {
            update_worker_bitmap_set0_action;
            update_worker_bitmap_set1_action;
            drop;
            NoAction;
        }
        const entries = {
            // Direct updates to the correct set
            (15w0 &&& 15w1, 4) : update_worker_bitmap_set0_action();
            (15w1 &&& 15w1, 4) : update_worker_bitmap_set1_action();
        }

        const default_action = NoAction;
    }

    apply {
        update_and_check_worker_bitmap.apply();
    }
}

#endif /* _BITMAP_CHECKER_ */
