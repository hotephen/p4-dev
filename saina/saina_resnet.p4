#include <core.p4>
#include <v1model.p4>

#include "configuration.p4"
#include "types.p4"
#include "headers.p4"
#include "parsers.p4"
#include "arp_icmp_responder.p4"
#include "forwarder.p4"
// #include "drop_simulator.p4"
#include "udp_receiver.p4"
#include "udp_sender.p4"
// #include "rdma_receiver.p4"
// #include "rdma_sender.p4"
#include "bitmap_checker.p4" 
#include "workers_counter.p4"
// #include "exponents.p4"
#include "processor.p4"
#include "next_step_selector.p4"
// #include "process_sign.p4"
// #include "extraction.p4"
// #include "Popcount.p4"
// #include "k_counter.p4"
// #include "k_update.p4"

// hi

// #define HALF_NUM_PARAMETERS 400000
#define PARAMETERS 23608202 // 37148106 / 32 / 32
#define SIGN_REGISTER_SIZE 737757 // 37148106 / 32 = 1,160,879
#define S_THRESHOLD 354123 // 37148106*0.48/32= 557,221 (VGG-16)
#define K_THRESHOLD 5

// control Ingress(
//     inout header_t hdr,
//     inout ingress_metadata_t ig_md,
//     in ingress_intrinsic_metadata_t ig_intr_md,
//     in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
//     inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
//     inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

control MyIngress(
    inout header_t hdr,
    inout metadata_t meta,
    inout standard_metadata_t standard_metadata) {


    register<bit<32>>(SIGN_REGISTER_SIZE) sign1;
    register<bit<32>>(SIGN_REGISTER_SIZE) sign2;
    register<bit<32>>(SIGN_REGISTER_SIZE) idx_counter_register;
    register<bit<32>>(1) sum_grad_sign;
    register<bit<32>>(1) sum_grad_sign_backup;
    register<bit<32>>(1) k_counter;
    register<bit<8>>(1) k_register;

    // Instantiate controls

    register<bit<32>>(num_slots) worker_bitmap;
    register<bit<32>>(num_slots) worker_bitmap1;
    
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

    action drop() {
        mark_to_drop(standard_metadata);
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



    action save_sign_bit_action1_0(){
         //FIXME:
        meta.sign_vector1 = meta.sign_vector1 + 0x00000001;
    }
    action save_sign_bit_action1_1(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00000002;
    }
    action save_sign_bit_action1_2(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00000004;
    }
    action save_sign_bit_action1_3(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00000008;
    }
    action save_sign_bit_action1_4(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00000010;
    }
    action save_sign_bit_action1_5(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00000020;
    }
    action save_sign_bit_action1_6(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00000040;
    }
    action save_sign_bit_action1_7(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00000080;
    }
    action save_sign_bit_action1_8(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00000100;
    }
    action save_sign_bit_action1_9(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00000200;
    }
    action save_sign_bit_action1_10(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00000400;
    }
    action save_sign_bit_action1_11(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00000800;
    }
    action save_sign_bit_action1_12(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00001000;
    }
    action save_sign_bit_action1_13(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00002000;
    }
    action save_sign_bit_action1_14(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00004000;
    }
    action save_sign_bit_action1_15(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00008000;
    }
    action save_sign_bit_action1_16(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00010000;
    }
    action save_sign_bit_action1_17(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00020000;
    }
    action save_sign_bit_action1_18(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00040000;
    }
    action save_sign_bit_action1_19(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00080000;
    }
    action save_sign_bit_action1_20(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00100000;
    }
    action save_sign_bit_action1_21(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00200000;
    }
    action save_sign_bit_action1_22(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00400000;
    }
    action save_sign_bit_action1_23(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x00800000;
    }
    action save_sign_bit_action1_24(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x01000000;
    }
    action save_sign_bit_action1_25(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x02000000;
    }
    action save_sign_bit_action1_26(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x04000000;
    }
    action save_sign_bit_action1_27(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x08000000;
    }
    action save_sign_bit_action1_28(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x10000000;
    }
    action save_sign_bit_action1_29(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x20000000;
    }
    action save_sign_bit_action1_30(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x40000000;
    }
    action save_sign_bit_action1_31(){
        
        meta.sign_vector1 = meta.sign_vector1 + 0x80000000;
    }
    action save_sign_bit_action2_0(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00000001;
    }
    action save_sign_bit_action2_1(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00000002;
    }
    action save_sign_bit_action2_2(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00000004;
    }
    action save_sign_bit_action2_3(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00000008;
    }
    action save_sign_bit_action2_4(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00000010;
    }
    action save_sign_bit_action2_5(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00000020;
    }
    action save_sign_bit_action2_6(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00000040;
    }
    action save_sign_bit_action2_7(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00000080;
    }
    action save_sign_bit_action2_8(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00000100;
    }
    action save_sign_bit_action2_9(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00000200;
    }
    action save_sign_bit_action2_10(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00000400;
    }
    action save_sign_bit_action2_11(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00000800;
    }
    action save_sign_bit_action2_12(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00001000;
    }
    action save_sign_bit_action2_13(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00002000;
    }
    action save_sign_bit_action2_14(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00004000;
    }
    action save_sign_bit_action2_15(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00008000;
    }
    action save_sign_bit_action2_16(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00010000;
    }
    action save_sign_bit_action2_17(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00020000;
    }
    action save_sign_bit_action2_18(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00040000;
    }
    action save_sign_bit_action2_19(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00080000;
    }
    action save_sign_bit_action2_20(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00100000;
    }
    action save_sign_bit_action2_21(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00200000;
    }
    action save_sign_bit_action2_22(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00400000;
    }
    action save_sign_bit_action2_23(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x00800000;
    }
    action save_sign_bit_action2_24(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x01000000;
    }
    action save_sign_bit_action2_25(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x02000000;
    }
    action save_sign_bit_action2_26(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x04000000;
    }
    action save_sign_bit_action2_27(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x08000000;
    }
    action save_sign_bit_action2_28(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x10000000;
    }
    action save_sign_bit_action2_29(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x20000000;
    }
    action save_sign_bit_action2_30(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x40000000;
    }
    action save_sign_bit_action2_31(){
        
        meta.sign_vector2 = meta.sign_vector2 + 0x80000000;
    }

    table save_sign_bit1 {
        key = {
            meta.sign_bitmap_index : exact;
            hdr.d0.d00 : ternary;
        }
        actions = {
            save_sign_bit_action1_0();
            save_sign_bit_action1_1();
            save_sign_bit_action1_2();
            save_sign_bit_action1_3();
            save_sign_bit_action1_4();
            save_sign_bit_action1_5();
            save_sign_bit_action1_6();
            save_sign_bit_action1_7();
            save_sign_bit_action1_8();
            save_sign_bit_action1_9();
            save_sign_bit_action1_10();
            save_sign_bit_action1_11();
            save_sign_bit_action1_12();
            save_sign_bit_action1_13();
            save_sign_bit_action1_14();
            save_sign_bit_action1_15();
            save_sign_bit_action1_16();
            save_sign_bit_action1_17();
            save_sign_bit_action1_18();
            save_sign_bit_action1_19();
            save_sign_bit_action1_20();
            save_sign_bit_action1_21();
            save_sign_bit_action1_22();
            save_sign_bit_action1_23();
            save_sign_bit_action1_24();
            save_sign_bit_action1_25();
            save_sign_bit_action1_26();
            save_sign_bit_action1_27();
            save_sign_bit_action1_28();
            save_sign_bit_action1_29();
            save_sign_bit_action1_30();
            save_sign_bit_action1_31();
            NoAction;
        }
        const entries = {
            (0, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_0();
            (1, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_1();
            (2, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_2();
            (3, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_3();
            (4, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_4();
            (5, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_5();
            (6, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_6();
            (7, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_7();
            (8, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_8();
            (9, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_9();
            (10, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_10();
            (11, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_11();
            (12, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_12();
            (13, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_13();
            (14, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_14();
            (15, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_15();
            (16, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_16();
            (17, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_17();
            (18, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_18();
            (19, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_19();
            (20, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_20();
            (21, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_21();
            (22, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_22();
            (23, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_23();
            (24, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_24();
            (25, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_25();
            (26, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_26();
            (27, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_27();
            (28, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_28();
            (29, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_29();
            (30, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_30();
            (31, 0x80000000 &&& 0x80000000) : save_sign_bit_action1_31();
        }
    }

    table save_sign_bit2 {
        key = {
            meta.sign_bitmap_index : exact;
            hdr.d0.d00 : ternary;
        }
        actions = {
            save_sign_bit_action2_0();
            save_sign_bit_action2_1();
            save_sign_bit_action2_2();
            save_sign_bit_action2_3();
            save_sign_bit_action2_4();
            save_sign_bit_action2_5();
            save_sign_bit_action2_6();
            save_sign_bit_action2_7();
            save_sign_bit_action2_8();
            save_sign_bit_action2_9();
            save_sign_bit_action2_10();
            save_sign_bit_action2_11();
            save_sign_bit_action2_12();
            save_sign_bit_action2_13();
            save_sign_bit_action2_14();
            save_sign_bit_action2_15();
            save_sign_bit_action2_16();
            save_sign_bit_action2_17();
            save_sign_bit_action2_18();
            save_sign_bit_action2_19();
            save_sign_bit_action2_20();
            save_sign_bit_action2_21();
            save_sign_bit_action2_22();
            save_sign_bit_action2_23();
            save_sign_bit_action2_24();
            save_sign_bit_action2_25();
            save_sign_bit_action2_26();
            save_sign_bit_action2_27();
            save_sign_bit_action2_28();
            save_sign_bit_action2_29();
            save_sign_bit_action2_30();
            save_sign_bit_action2_31();
            NoAction;
        }
        const entries = {
            (0, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_0();
            (1, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_1();
            (2, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_2();
            (3, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_3();
            (4, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_4();
            (5, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_5();
            (6, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_6();
            (7, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_7();
            (8, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_8();
            (9, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_9();
            (10, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_10();
            (11, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_11();
            (12, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_12();
            (13, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_13();
            (14, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_14();
            (15, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_15();
            (16, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_16();
            (17, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_17();
            (18, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_18();
            (19, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_19();
            (20, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_20();
            (21, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_21();
            (22, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_22();
            (23, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_23();
            (24, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_24();
            (25, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_25();
            (26, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_26();
            (27, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_27();
            (28, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_28();
            (29, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_29();
            (30, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_30();
            (31, 0x80000000 &&& 0x80000000) : save_sign_bit_action2_31();
        }
    }













    ARPandICMPResponder() arp_icmp_responder;
    Forwarder() forwarder;

    UDPReceiver() udp_receiver;
    WorkersCounter() workers_counter;
    // ReconstructWorkerBitmap() reconstruct_worker_bitmap;
    // UpdateAndCheckWorkerBitmap() update_and_check_worker_bitmap;

    NextStepSelector() next_step_selector;

    Processor() value00;
    Processor() value01;
    Processor() value02;
    Processor() value03;
    Processor() value04;
    Processor() value05;
    Processor() value06;
    Processor() value07;
    Processor() value08;
    Processor() value09;
    Processor() value10;
    Processor() value11;
    Processor() value12;
    Processor() value13;
    Processor() value14;
    Processor() value15;
    Processor() value16;
    Processor() value17;
    Processor() value18;
    Processor() value19;
    Processor() value20;
    Processor() value21;
    Processor() value22;
    Processor() value23;
    Processor() value24;
    Processor() value25;
    Processor() value26;
    Processor() value27;
    Processor() value28;
    Processor() value29;
    Processor() value30;
    Processor() value31;

    apply { //FIXME:


        if (meta.switchml_md.packet_type == 4) {
            udp_receiver.apply(hdr, standard_metadata, meta);
            meta.switchml_md.ingress_port = standard_metadata.ingress_port;

        } else if (meta.switchml_md.packet_type == 5 ||
            meta.switchml_md.packet_type == 6 ||
            meta.switchml_md.packet_type == 7) {
            reconstruct_worker_bitmap.apply();
            // reconstruct_worker_bitmap.apply(meta);
        }

        // If the packet is valid, should be either forwarded or processed
        if (meta.drop_flag == 1w0) { //FIXME:
            if (meta.switchml_md.packet_type == 4 ||
                meta.switchml_md.packet_type == 5 ||
                meta.switchml_md.packet_type == 6 ||
                meta.switchml_md.packet_type == 7) {
                // For CONSUME packets, record packet reception and check if this packet is a retransmission
                update_and_check_worker_bitmap.apply();
                k_register.read(meta.switchml_md.k, 0);
                if(meta.switchml_md.k == 0 ){
                    // meta.switchml_md.k = 1; //FIXME:
                    meta.switchml_md.k = 1;
                    k_register.write(0, 1);
                }
                workers_counter.apply(hdr, standard_metadata, meta);
            }
            // If it's a SwitchML packet, process it
            if ((packet_type_underlying_t) meta.switchml_md.packet_type >=
                (packet_type_underlying_t) 4) { // all consume or harvest types

                // Aggregate values
                value00.apply(hdr.d0.d00, hdr.d0.d00, meta.switchml_md);
                value01.apply(hdr.d0.d01, hdr.d0.d01, meta.switchml_md);
                value02.apply(hdr.d0.d02, hdr.d0.d02, meta.switchml_md);
                value03.apply(hdr.d0.d03, hdr.d0.d03, meta.switchml_md);
                value04.apply(hdr.d0.d04, hdr.d0.d04, meta.switchml_md);
                value05.apply(hdr.d0.d05, hdr.d0.d05, meta.switchml_md);
                value06.apply(hdr.d0.d06, hdr.d0.d06, meta.switchml_md);
                value07.apply(hdr.d0.d07, hdr.d0.d07, meta.switchml_md);
                value08.apply(hdr.d0.d08, hdr.d0.d08, meta.switchml_md);
                value09.apply(hdr.d0.d09, hdr.d0.d09, meta.switchml_md);
                value10.apply(hdr.d0.d10, hdr.d0.d10, meta.switchml_md);
                value11.apply(hdr.d0.d11, hdr.d0.d11, meta.switchml_md);
                value12.apply(hdr.d0.d12, hdr.d0.d12, meta.switchml_md);
                value13.apply(hdr.d0.d13, hdr.d0.d13, meta.switchml_md);
                value14.apply(hdr.d0.d14, hdr.d0.d14, meta.switchml_md);
                value15.apply(hdr.d0.d15, hdr.d0.d15, meta.switchml_md);
                value16.apply(hdr.d0.d16, hdr.d0.d16, meta.switchml_md);
                value17.apply(hdr.d0.d17, hdr.d0.d17, meta.switchml_md);
                value18.apply(hdr.d0.d18, hdr.d0.d18, meta.switchml_md);
                value19.apply(hdr.d0.d19, hdr.d0.d19, meta.switchml_md);
                value20.apply(hdr.d0.d20, hdr.d0.d20, meta.switchml_md);
                value21.apply(hdr.d0.d21, hdr.d0.d21, meta.switchml_md);
                value22.apply(hdr.d0.d22, hdr.d0.d22, meta.switchml_md);
                value23.apply(hdr.d0.d23, hdr.d0.d23, meta.switchml_md);
                value24.apply(hdr.d0.d24, hdr.d0.d24, meta.switchml_md);
                value25.apply(hdr.d0.d25, hdr.d0.d25, meta.switchml_md);
                value26.apply(hdr.d0.d26, hdr.d0.d26, meta.switchml_md);
                value27.apply(hdr.d0.d27, hdr.d0.d27, meta.switchml_md);
                value28.apply(hdr.d0.d28, hdr.d0.d28, meta.switchml_md);
                value29.apply(hdr.d0.d29, hdr.d0.d29, meta.switchml_md);
                value30.apply(hdr.d0.d30, hdr.d0.d30, meta.switchml_md);
                value31.apply(hdr.d0.d31, hdr.d0.d31, meta.switchml_md);

                next_step_selector.apply(hdr, standard_metadata, meta);
            }
            else {
                
                arp_icmp_responder.apply(hdr, standard_metadata, meta);
                forwarder.apply(hdr, standard_metadata, meta);

            }
        }
        
        if (hdr.switchml.round_end_flag == 1 && meta.switchml_md.packet_type == 1){
            // Clear worker_bitmap
            // worker_bitmap.write((bit<32>)meta.switchml_md.pool_index[14:1], 0);
            
            // bit<32> sign_reg_idx;
            bit<32> sign_vector1;
            bit<32> sign_vector2;
            bit<32> xor_result;
            bit<32> idx_counter;
            bit<32> sum;
            bit<32> k_count;
            
            meta.sign_reg_idx = (bit<32>)hdr.switchml.tsi[31:5];
            meta.sign_bitmap_index = hdr.switchml.tsi % 32;
            // meta.round_mod = hdr.switchml.round % 2;
            

            if (hdr.switchml.round % 2 == 0){
                // sign2.read(sign_vector2, sign_reg_idx);
                // sign_vector2 = sign_vector2 << 1;
                // sign_vector2 = sign_vector2 + (bit<32>)hdr.d0.d00[31:31];
                sign2.read(meta.sign_vector2, meta.sign_reg_idx);
                save_sign_bit2.apply();
                sign2.write(meta.sign_reg_idx, meta.sign_vector2);
                idx_counter_register.read(idx_counter, meta.sign_reg_idx);
                
                // meta.test1 = meta.sign_vector2; // TEST
                meta.test1 = idx_counter; // TEST
                
                if(idx_counter == 31){
                    sign1.read(meta.sign_vector1, meta.sign_reg_idx);
                    xor_result = meta.sign_vector2 ^ meta.sign_vector1;
                    sign1.write(meta.sign_reg_idx, 0);
                    idx_counter_register.write(meta.sign_reg_idx, 0);
                    
                }
                else{
                    idx_counter_register.write(meta.sign_reg_idx, idx_counter + 1);
                }
            } 
            else{ // if(hdr.switchml.round % 2 == 1) {
                // sign1.read(sign_vector1 , sign_reg_idx);
                // sign_vector1 = sign_vector1 << 1;
                // sign_vector1 = sign_vector1 + (bit<32>)hdr.d0.d00[31:31];
                sign1.read(meta.sign_vector1, meta.sign_reg_idx);
                save_sign_bit1.apply();
                sign1.write(meta.sign_reg_idx, meta.sign_vector1);
                idx_counter_register.read(idx_counter, meta.sign_reg_idx);

                // meta.test1 = meta.sign_vector1; // TEST
                meta.test1 = idx_counter; // TEST
                
                if(idx_counter == 31){
                    sign2.read(meta.sign_vector2, meta.sign_reg_idx);
                    xor_result = meta.sign_vector1 ^ meta.sign_vector2;
                    sign2.write(meta.sign_reg_idx, 0);
                    idx_counter_register.write(meta.sign_reg_idx, 0);
                    
                }
                else{
                    idx_counter_register.write(meta.sign_reg_idx, idx_counter + 1);
                }
            }   

            sum_grad_sign.read(sum, 0);

            if(idx_counter == 31){
                bit<32> temp1;
                bit<32> temp2;
                bit<32> popcount_result;

                temp1 = xor_result & 0x55555555;
                temp2 = (xor_result >> 1) & 0x55555555;
                popcount_result = temp1 + temp2;
                temp1 = popcount_result & 0x33333333;
                temp2 = (popcount_result >> 2) & 0x33333333;
                popcount_result = temp1 + temp2;
                temp1 = popcount_result & 0x0f0f0f0f;
                temp2 = (popcount_result >> 4) & 0x0f0f0f0f; 
                popcount_result = temp1 + temp2;
                temp1 = popcount_result & 0x00ff00ff;
                temp2 = (popcount_result >> 8) & 0x00ff00ff;
                popcount_result = temp1 + temp2;
                temp1 = popcount_result & 0x0000ffff;
                temp2 = (popcount_result >> 16) & 0x0000ffff;
                popcount_result = temp1 + temp2;
                
                sum = sum + popcount_result;
                sum_grad_sign.write(0, sum);
                sum_grad_sign_backup.write(0, sum); //FIXME:TEST
            }

            // if(hdr.switchml.last_packet_flag==1){
            // if(meta.switchml_md.first_last_flag == 0 && hdr.switchml.last_packet_flag==1){
            if(hdr.switchml.last_packet_flag==1){
                if(hdr.switchml.round % 2 == 1){
                    sign2.write(meta.sign_reg_idx, 0);
                }
                else{
                    sign1.write(meta.sign_reg_idx, 0);
                }
                sum_grad_sign_backup.write(0, sum); //FIXME:TEST
                sum_grad_sign.write(0, 0);
                idx_counter_register.write(meta.sign_reg_idx, 0);

                k_counter.read(k_count, 0);
                if(sum >= S_THRESHOLD){
                    k_count = k_count + 1;
                    k_counter.write(0, k_count);
                }
                else{
                    if (k_count == 0){
                        // nothing
                    } 
                    else{
                        k_count = k_count - 1;
                    }
                    k_counter.write(0, k_count);
                }       

                if(k_count >= K_THRESHOLD){
                    k_register.read(meta.switchml_md.k, 0);
                    if(meta.switchml_md.k != 16){
                        meta.switchml_md.k = meta.switchml_md.k + 1;
                    }
                    k_register.write(0,meta.switchml_md.k);    
                    k_counter.write(0,0);
                }
            }
            meta.test2 = sum;
            // sum_grad_sign.read(meta.test2, 0); //FIXME:
            k_register.read(meta.switchml_md.k, 0); //FIXME:
        }
        else{
            sum_grad_sign_backup.read(meta.test2, 0); //FIXME: TEST
        }
        k_register.read(meta.switchml_md.k, 0); //FIXME:
    }
}

control MyEgress(
    inout header_t hdr,
    inout metadata_t meta,
    inout standard_metadata_t standard_metadata
    ){

    UDPSender() udp_sender;

    apply {
        udp_sender.apply(hdr, standard_metadata, meta);
    }
}

control MyDeparser(packet_out pkt, in header_t hdr) {

    apply {
        pkt.emit(hdr);
    }
}

control MyVerifyChecksum(inout header_t hdr, inout metadata_t meta
) {
    apply {  }
}


V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
