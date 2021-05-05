/* -*- P4_16 -*- */

#include <core.p4>
#include <v1model.p4>

#define VALUE_SIZE 32
#define NUM_OF_WORKERS 10 
#define CPU_PORT 10
#define BASE_BITMAP 32w0x80000000
// ----------------------------
// ---------- header ----------
// ----------------------------

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> len;
    bit<16> checksum;
}

header frame_type_t {
    bit<8>      frame_type;
    bit<8>      switch_id;
}

header preamble_t {
    bit<8>      k;
    bit<8>      end;        //epoch end
    bit<8>      worker_id;
    bit<16>     epoch;
    bit<32>     seg_number;
    bit<8>      pool_version;
    bit<32>     pool_index;            // pool index (1 or 2)
    // bit<32>     offset; 
}

header gradient_t {
    // bit<KEY_SIZE> key;  //  FIXME: to be deleted
    int<VALUE_SIZE> value0;
    int<VALUE_SIZE> value1;
    int<VALUE_SIZE> value2;
    int<VALUE_SIZE> value3;
    int<VALUE_SIZE> value4;
    int<VALUE_SIZE> value5;
    int<VALUE_SIZE> value6;
    int<VALUE_SIZE> value7;
    int<VALUE_SIZE> value8;
    int<VALUE_SIZE> value9;
    int<VALUE_SIZE> value10;
    int<VALUE_SIZE> value11;
    int<VALUE_SIZE> value12;
    int<VALUE_SIZE> value13;
    int<VALUE_SIZE> value14;
    int<VALUE_SIZE> value15;
    int<VALUE_SIZE> value16;
    int<VALUE_SIZE> value17;
    int<VALUE_SIZE> value18;
    int<VALUE_SIZE> value19;
    int<VALUE_SIZE> value20;
    int<VALUE_SIZE> value21;
    int<VALUE_SIZE> value22;
    int<VALUE_SIZE> value23;
    int<VALUE_SIZE> value24;
    int<VALUE_SIZE> value25;
    int<VALUE_SIZE> value26;
    int<VALUE_SIZE> value27;
    int<VALUE_SIZE> value28;
    int<VALUE_SIZE> value29;
    int<VALUE_SIZE> value30;
    int<VALUE_SIZE> value31;
}

struct metadata {
    bit<8>  frame_type;
    bit<8>  switch_id;
    bit<8>  end_flag;
    bit<32> seg_number;

    bit<8>  counter_value;  // worker counter
    int<32> gradient_value;

    bit<8>  broadcast_flag;
    bit<8>  recirculation_flag;
    bit<8>  stop_recirculation_flag;

    bit<48> elapsed_time;
    bit<8>  selected; 
    bit<8>  k; 
    bit<32> counter;    // 

    bit<16> epoch;
    bit<32> cur_global_grad_sign;
    bit<32> prev_global_grad_sign;
    bit<32> xor_result;
    bit<32> popcount_result;
    bit<32> sum_grad_sign;
    bit<8>  end;
    bit<32> pool_index;

    bit<32> worker_bitmap_mask;
    bit<8> worker_id;
    bit<32> seen_pool1_bitmap;
    bit<32> seen_pool2_bitmap;

}
 
struct headers {
    ethernet_t ethernet;
    ipv4_t ipv4;
    udp_t udp;
    frame_type_t frame_type;
    preamble_t preamble;
    gradient_t gradient;
}


// -------------------------------------------
// ---------- parser -------------------------
// -------------------------------------------


const bit<16> TYPE_IPV4 = 0x800;
const bit<8>  TYPE_UDP  = 17;

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4 : parse_ipv4;
            default : accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            TYPE_UDP : parse_udp;
            default : accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);
        transition parse_frame_type;  
    }

    state parse_frame_type {   
        packet.extract(hdr.frame_type);
        meta.frame_type = hdr.frame_type.frame_type;
        meta.switch_id = hdr.frame_type.switch_id;
        transition select(hdr.frame_type.frame_type){  
            // 0x01 : parse_preamble; 
            default : parse_preamble;
        }
    }

    state parse_preamble {
        packet.extract(hdr.preamble);
        // meta.tree_id = hdr.preamble.tree_id;
        // meta.end_flag = 0;
        meta.seg_number = hdr.preamble.seg_number;
        meta.end = hdr.preamble.end;
        meta.pool_index = hdr.preamble.pool_index;
        meta.worker_id = hdr.preamble.worker_id;
        transition parse_gradient;  
    }


    state parse_gradient {
        packet.extract(hdr.gradient);
        transition accept;
    }
}

// -------------------------------------------
// ---------- checksum verification ----------
// -------------------------------------------

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}


// ----------------------------------------
// ---------- ingress processing ----------
// ----------------------------------------

control MyIngress(inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata) {

    // Define parameters
    bit<32> m1 = 0x55555555;
    bit<32> m2 = 0x33333333;
    bit<32> m4 = 0x0f0f0f0f;
    bit<32> m8 = 0x00ff00ff;
    bit<32> m16= 0x0000ffff;
    
    



    /* Deadline registers */
    register<bit<48>>(1)    start_time_register;
    register<bit<48>>(1)    elapsed_time_register;
    register<bit<48>>(1)    time1;
    register<bit<48>>(1)    time2;
    register<bit<48>>(1)    time3;
    register<bit<8>>(1)     stop_recirculation_flag_register;

    action elapsed_time_calculation(){
        bit<48> start_time;
        bit<48> receive_time;
        start_time_register.read(start_time,0);
        receive_time = standard_metadata.ingress_global_timestamp;
        meta.elapsed_time = receive_time - start_time;
        time1.write(0,standard_metadata.ingress_global_timestamp);
        time2.write(0,start_time);
        elapsed_time_register.write(0,meta.elapsed_time);
    }

    action save_start_time(){
        start_time_register.write(0, standard_metadata.ingress_global_timestamp);
        standard_metadata.egress_spec = CPU_PORT;

    }

    action start_recirculation(){
        // recirculate(standard_metadata.egress_spec);
        // resubmit(standard_metadata);
    }



    /* ------------ Register Definition ------------ */
    /* ------------ Register Definition ------------ */
    /* ------------ Register Definition ------------ */
    //TODO:

    #define PARAMETER_SIZE 900000
    #define REGISTER_SIZE 409600 // 128(pool size) x 32(the number of gradients in packet) = 4096
    register<int<VALUE_SIZE>>(REGISTER_SIZE) parameter_pool1;
    register<int<VALUE_SIZE>>(REGISTER_SIZE) parameter_pool2;
    register<bit<8>>(REGISTER_SIZE) counter_num_workers_pool1;
    register<bit<8>>(REGISTER_SIZE) counter_num_workers_pool2;
    register<bit<1>>(REGISTER_SIZE) sent_seg_num_pool1;
    register<bit<1>>(REGISTER_SIZE) sent_seg_num_pool2;
    
    register<bit<32>>(REGISTER_SIZE) seen_pool1;
    register<bit<32>>(REGISTER_SIZE) seen_pool2;


    //
    register<bit<VALUE_SIZE>>(30000) global_grad_sign;
    register<bit<VALUE_SIZE>>(30000) global_grad_sign1;
    register<bit<VALUE_SIZE>>(30000) global_grad_sign2;
    register<bit<32>>(1) sum_grad_sign;

    register<bit<32>>(1) k_counter;
    register<bit<8>>(1) k;


    

    action drop() {
        mark_to_drop(standard_metadata);
    }
    
    // action forward(bit<9> port) {
    action forward(bit<9> port) {
        standard_metadata.egress_spec = port;
    }
    
    action forward_to_2() {
        standard_metadata.egress_spec = 2;
    }

    action broadcast() {
        standard_metadata.mcast_grp = 1;
        hdr.frame_type.frame_type = 2;
        // stop_recirculation_flag_register.write(0, 1);
        // counter_num_workers_pool1.write(meta.seg_number, 0);
        
        // clone3(CloneType.I2E, (bit<32>)32w100, meta);
    }

    action set_processing() {
        meta.frame_type = 1;
    }

    table ipv4_forward {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            NoAction();
            forward;
            forward_to_2;
            drop;
        }
        default_action = drop();
        const entries = {
            0x0A0A0001 : forward(2); // 10.10.0.1
        }
    }

    table set_processing_table {
        key = {
            hdr.frame_type.switch_id: exact;
        }
        actions = {
            set_processing();
        }
        const entries = {
            1 : set_processing();
        }
    }    
    
    action receive_timer_broadcast(){
        meta.broadcast_flag = 1;
    }

    table check_timer_packet {
        key = {
            hdr.frame_type.frame_type : exact;
        }   
        actions = {
            receive_timer_broadcast();
        } 
        const entries = {
            3 : receive_timer_broadcast();
        }
    }

    action set_k( bit<8> k){
        meta.k = k;
    }

    table select_k {
        key = { 
            // meta.selected : exact;
        }
        actions = {
            set_k();
        }

        // const entries = {
        //     5 : set_k(5);
        // }
        default_action = set_k(5);
    }

    action forward_to_cpu(){
        standard_metadata.egress_spec = CPU_PORT;
        hdr.frame_type.frame_type = 3;
    }

    action xor_grad_sign(){  
        meta.xor_result = meta.prev_global_grad_sign ^ meta.cur_global_grad_sign;
    }

    action popcount(bit<32> xor_result){
        bit<32> x;
        x = xor_result;
        x = (x & m1 ) + ((x >>  1) & m1 ); 
        x = (x & m2 ) + ((x >>  2) & m2 );
        x = (x & m4 ) + ((x >>  4) & m4 );
        x = (x & m8 ) + ((x >>  8) & m8 );
        x = (x & m16) + ((x >> 16) & m16);   
        meta.popcount_result = x;
    }

    action accumulate_sign(bit<32> popcount_result){
        sum_grad_sign.read(meta.sum_grad_sign,0);
        meta.sum_grad_sign = meta.sum_grad_sign + popcount_result;
        sum_grad_sign.write(0,meta.sum_grad_sign);
    }

    


    /* Aggregation logic */
    /* Aggregation logic */
    /* Aggregation logic */ 

    /* Load current aggregated gradient values */
    /* Add new gradient to current gradients */
    /* Save aggregated gradient values */
    /* Load aggregated gradient values to gradient header */
    #define AGGREGATION_POOL1(i) \
    parameter_pool1.read(meta.gradient_value, hdr.preamble.pool_index + ##i); \
    meta.gradient_value = meta.gradient_value + hdr.gradient.value##i; \
    parameter_pool1.write(hdr.preamble.pool_index + ##i,meta.gradient_value); \
    hdr.gradient.value##i = meta.gradient_value; \
    parameter_pool2.write(hdr.preamble.pool_index + ##i,0); \

    #define AGGREGATION_POOL2(i) \
    parameter_pool2.read(meta.gradient_value, hdr.preamble.pool_index + ##i); \
    meta.gradient_value = meta.gradient_value + hdr.gradient.value##i; \
    parameter_pool2.write(hdr.preamble.pool_index + ##i,meta.gradient_value); \
    hdr.gradient.value##i = meta.gradient_value; \
    parameter_pool1.write(hdr.preamble.pool_index + ##i,0); \

    #define READ_FOR_BROADCAST_POOL1(i)  \
    parameter_pool1.read(meta.gradient_value, hdr.preamble.pool_index + ##i); \
    hdr.gradient.value##i = meta.gradient_value; \
    // parameter_pool1.write(hdr.preamble.pool_index + ##i,0); \

    #define READ_FOR_BROADCAST_POOL2(i)  \
    parameter_pool2.read(meta.gradient_value, hdr.preamble.pool_index + ##i); \
    hdr.gradient.value##i = meta.gradient_value; \
    // parameter_pool2.write(hdr.preamble.pool_index + ##i,0); \

    #define SAVE_GRADIENT_SIGN(i) \
    meta.cur_global_grad_sign[##i:##i] = hdr.gradient.value##i[31:31]; \

    #define ACCUMULATE_SIGN() \
    /* meta.cur_global_grad_sign = meta.gradient_value; */ \
    /* Load previous global_grad_sign */ \
    global_grad_sign.read(meta.prev_global_grad_sign, hdr.preamble.seg_number); \ 
    /* Save current global_grad_sign */ \
    global_grad_sign.write(hdr.preamble.seg_number, meta.cur_global_grad_sign); \
    /* Execute XOR action between prev_grad_sign and cur_grad_sign */ \
    xor_grad_sign(); \
    /* Popcount of xor_result */ \
    popcount(meta.xor_result); \
    /* Accumulate the sum of grad_sign (popcount_result) */ \
    accumulate_sign(meta.popcount_result); \
    /* If last gradient packet is received in current epoch,  */ \
    /* Check that the sum of the signs is greater than threshold */ \
    if(meta.end == 1){ \
        if (meta.sum_grad_sign >= 420000){ \
            /* Increase count */ \
            k_counter.read(meta.counter, 0); \
            meta.counter = meta.counter + 1; \
            k_counter.write(0, meta.counter); \
            if (meta.counter >= 10){ \
                /* Increase k  */ \
                /* k.read(meta.k, 0);*/ \
                if(meta.k < 10){\
                    meta.k = meta.k + 1; \
                    k.write(0,meta.k); \
                } \
            } \
        } \
        else{ \
            /* Nothing to do (No incraese) */ \
        } \
        /* reset sum_grad_sign (accumulate_sign) */ \
        sum_grad_sign.write(0,0); \
    } \

    action forward_to_worker_pool1(){
        READ_FOR_BROADCAST_POOL1(0)
        READ_FOR_BROADCAST_POOL1(1)
        READ_FOR_BROADCAST_POOL1(2)
        READ_FOR_BROADCAST_POOL1(3)
        READ_FOR_BROADCAST_POOL1(4)
        READ_FOR_BROADCAST_POOL1(5)
        READ_FOR_BROADCAST_POOL1(6)
        READ_FOR_BROADCAST_POOL1(7)
        READ_FOR_BROADCAST_POOL1(8)
        READ_FOR_BROADCAST_POOL1(9)
        READ_FOR_BROADCAST_POOL1(10)
        READ_FOR_BROADCAST_POOL1(11)
        READ_FOR_BROADCAST_POOL1(12)
        READ_FOR_BROADCAST_POOL1(13)
        READ_FOR_BROADCAST_POOL1(14)
        READ_FOR_BROADCAST_POOL1(15)
        READ_FOR_BROADCAST_POOL1(16)
        READ_FOR_BROADCAST_POOL1(17)
        READ_FOR_BROADCAST_POOL1(18)
        READ_FOR_BROADCAST_POOL1(19)
        READ_FOR_BROADCAST_POOL1(20)
        READ_FOR_BROADCAST_POOL1(21)
        READ_FOR_BROADCAST_POOL1(22)
        READ_FOR_BROADCAST_POOL1(23)
        READ_FOR_BROADCAST_POOL1(24)
        READ_FOR_BROADCAST_POOL1(25)
        READ_FOR_BROADCAST_POOL1(26)
        READ_FOR_BROADCAST_POOL1(27)
        READ_FOR_BROADCAST_POOL1(28)
        READ_FOR_BROADCAST_POOL1(29)
        READ_FOR_BROADCAST_POOL1(30)
        READ_FOR_BROADCAST_POOL1(31)
        hdr.frame_type.frame_type = 2;
        standard_metadata.egress_spec = standard_metadata.ingress_port;
    }

    action forward_to_worker_pool2(){
        READ_FOR_BROADCAST_POOL2(0)
        READ_FOR_BROADCAST_POOL2(1)
        READ_FOR_BROADCAST_POOL2(2)
        READ_FOR_BROADCAST_POOL2(3)
        READ_FOR_BROADCAST_POOL2(4)
        READ_FOR_BROADCAST_POOL2(5)
        READ_FOR_BROADCAST_POOL2(6)
        READ_FOR_BROADCAST_POOL2(7)
        READ_FOR_BROADCAST_POOL2(8)
        READ_FOR_BROADCAST_POOL2(9)
        READ_FOR_BROADCAST_POOL2(10)
        READ_FOR_BROADCAST_POOL2(11)
        READ_FOR_BROADCAST_POOL2(12)
        READ_FOR_BROADCAST_POOL2(13)
        READ_FOR_BROADCAST_POOL2(14)
        READ_FOR_BROADCAST_POOL2(15)
        READ_FOR_BROADCAST_POOL2(16)
        READ_FOR_BROADCAST_POOL2(17)
        READ_FOR_BROADCAST_POOL2(18)
        READ_FOR_BROADCAST_POOL2(19)
        READ_FOR_BROADCAST_POOL2(20)
        READ_FOR_BROADCAST_POOL2(21)
        READ_FOR_BROADCAST_POOL2(22)
        READ_FOR_BROADCAST_POOL2(23)
        READ_FOR_BROADCAST_POOL2(24)
        READ_FOR_BROADCAST_POOL2(25)
        READ_FOR_BROADCAST_POOL2(26)
        READ_FOR_BROADCAST_POOL2(27)
        READ_FOR_BROADCAST_POOL2(28)
        READ_FOR_BROADCAST_POOL2(29)
        READ_FOR_BROADCAST_POOL2(30)
        READ_FOR_BROADCAST_POOL2(31)
        hdr.frame_type.frame_type = 2;
        standard_metadata.egress_spec = standard_metadata.ingress_port;
    }


    /* Start ingress */
    /* Start ingress */
    /* Start ingress */

        
    apply{
        // check_timer_packet.apply();
        // if(meta.broadcast_flag == 0){ // When packet is entered first
        
        set_processing_table.apply();

        if(meta.frame_type == 1){ // When packet is local gradient
                
            // Load k
            k.read(meta.k,0);
            if(meta.k == 0){      // If no specific k, set k as default value
                select_k.apply(); 
            }


            // Aggregation logic //
            // Aggregation logic //

            /* ---------------------pool1--------------------- */
            // bit<32> seg_num_temp;
            // seg_num_temp = meta.pool_index - 1;
            // TODO:

            meta.worker_bitmap_mask = BASE_BITMAP >> (hdr.preamble.worker_id-1);

            if(hdr.preamble.pool_version == 1){ // When version (pool) is 1 
                
                counter_num_workers_pool1.read(meta.counter_value, hdr.preamble.pool_index); // Load gradient counter of pool_index

                bit<1> sent_seg_num;
                sent_seg_num_pool1.read(sent_seg_num, meta.pool_index);
                seen_pool1.read(meta.seen_pool1_bitmap, meta.pool_index);

                // if(sent_seg_num == 1){
                if(meta.worker_bitmap_mask & meta.seen_pool1_bitmap != 0){
                    if(meta.counter_value == 0){
                        forward_to_worker_pool1(); // In case of SW -> Worker loss, thus retransmit
                    }
                    else{
                        // No Actions, because packet is duplicate retransmission
                        drop();
                    }
                }
                else{ // before K
                    meta.seen_pool1_bitmap = meta.seen_pool1_bitmap | meta.worker_bitmap_mask;
                    seen_pool1.write(meta.pool_index, meta.seen_pool1_bitmap);

                    AGGREGATION_POOL1(0)
                    AGGREGATION_POOL1(1)
                    AGGREGATION_POOL1(2)
                    AGGREGATION_POOL1(3)
                    AGGREGATION_POOL1(4)
                    AGGREGATION_POOL1(5)
                    AGGREGATION_POOL1(6)
                    AGGREGATION_POOL1(7)
                    AGGREGATION_POOL1(8)
                    AGGREGATION_POOL1(9)
                    AGGREGATION_POOL1(10)
                    AGGREGATION_POOL1(11)
                    AGGREGATION_POOL1(12)
                    AGGREGATION_POOL1(13)
                    AGGREGATION_POOL1(14)
                    AGGREGATION_POOL1(15)
                    AGGREGATION_POOL1(16)
                    AGGREGATION_POOL1(17)
                    AGGREGATION_POOL1(18)
                    AGGREGATION_POOL1(19)
                    AGGREGATION_POOL1(20)
                    AGGREGATION_POOL1(21)
                    AGGREGATION_POOL1(22)
                    AGGREGATION_POOL1(23)
                    AGGREGATION_POOL1(24)
                    AGGREGATION_POOL1(25)
                    AGGREGATION_POOL1(26)
                    AGGREGATION_POOL1(27)
                    AGGREGATION_POOL1(28)
                    AGGREGATION_POOL1(29)
                    AGGREGATION_POOL1(30)
                    AGGREGATION_POOL1(31)

                    drop();

                    meta.counter_value = meta.counter_value + 1;
                    counter_num_workers_pool1.write(meta.pool_index, meta.counter_value);

                    if(meta.counter_value >= meta.k){    // When all gradients are received
                        
                        
                        broadcast();
                        seen_pool2.write(meta.pool_index, 0);

                        READ_FOR_BROADCAST_POOL1(0)
                        READ_FOR_BROADCAST_POOL1(1)
                        READ_FOR_BROADCAST_POOL1(2)
                        READ_FOR_BROADCAST_POOL1(3)
                        READ_FOR_BROADCAST_POOL1(4)
                        READ_FOR_BROADCAST_POOL1(5)
                        READ_FOR_BROADCAST_POOL1(6)
                        READ_FOR_BROADCAST_POOL1(7)
                        READ_FOR_BROADCAST_POOL1(8)
                        READ_FOR_BROADCAST_POOL1(9)
                        READ_FOR_BROADCAST_POOL1(10)
                        READ_FOR_BROADCAST_POOL1(11)
                        READ_FOR_BROADCAST_POOL1(12)
                        READ_FOR_BROADCAST_POOL1(13)
                        READ_FOR_BROADCAST_POOL1(14)
                        READ_FOR_BROADCAST_POOL1(15)
                        READ_FOR_BROADCAST_POOL1(16)
                        READ_FOR_BROADCAST_POOL1(17)
                        READ_FOR_BROADCAST_POOL1(18)
                        READ_FOR_BROADCAST_POOL1(19)
                        READ_FOR_BROADCAST_POOL1(20)
                        READ_FOR_BROADCAST_POOL1(21)
                        READ_FOR_BROADCAST_POOL1(22)
                        READ_FOR_BROADCAST_POOL1(23)
                        READ_FOR_BROADCAST_POOL1(24)
                        READ_FOR_BROADCAST_POOL1(25)
                        READ_FOR_BROADCAST_POOL1(26)
                        READ_FOR_BROADCAST_POOL1(27)
                        READ_FOR_BROADCAST_POOL1(28)
                        READ_FOR_BROADCAST_POOL1(29)
                        READ_FOR_BROADCAST_POOL1(30)
                        READ_FOR_BROADCAST_POOL1(31)

                        counter_num_workers_pool1.write(meta.pool_index,0);

                        // sent_seg_num_pool1.write(meta.pool_index, 1);
                        // sent_seg_num_pool2.write(meta.pool_index, 0);

                        // parameter_pool1.write(hdr.preamble.pool_index + 0,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 1,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 2,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 3,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 4,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 5,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 6,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 7,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 8,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 9,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 10,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 11,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 12,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 13,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 14,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 15,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 16,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 17,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 18,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 19,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 20,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 21,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 22,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 23,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 24,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 25,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 26,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 27,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 28,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 29,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 30,0);
                        // parameter_pool1.write(hdr.preamble.pool_index + 31,0);
                        // reset counter_num_workers

                        // Save current sign of global gradients
                        // meta.cur_global_grad_sign[0:0] = hdr.gradient.value0[31:31];
                        // meta.cur_global_grad_sign[1:1] = hdr.gradient.value1[31:31];
                        SAVE_GRADIENT_SIGN(0)
                        SAVE_GRADIENT_SIGN(1)
                        SAVE_GRADIENT_SIGN(2)
                        SAVE_GRADIENT_SIGN(3)
                        SAVE_GRADIENT_SIGN(4)
                        SAVE_GRADIENT_SIGN(5)
                        SAVE_GRADIENT_SIGN(6)
                        SAVE_GRADIENT_SIGN(7)
                        SAVE_GRADIENT_SIGN(8)
                        SAVE_GRADIENT_SIGN(9)
                        SAVE_GRADIENT_SIGN(10)
                        SAVE_GRADIENT_SIGN(11)
                        SAVE_GRADIENT_SIGN(12)
                        SAVE_GRADIENT_SIGN(13)
                        SAVE_GRADIENT_SIGN(14)
                        SAVE_GRADIENT_SIGN(15)
                        SAVE_GRADIENT_SIGN(16)
                        SAVE_GRADIENT_SIGN(17)
                        SAVE_GRADIENT_SIGN(18)
                        SAVE_GRADIENT_SIGN(19)
                        SAVE_GRADIENT_SIGN(20)
                        SAVE_GRADIENT_SIGN(21)
                        SAVE_GRADIENT_SIGN(22)
                        SAVE_GRADIENT_SIGN(23)
                        SAVE_GRADIENT_SIGN(24)
                        SAVE_GRADIENT_SIGN(25)
                        SAVE_GRADIENT_SIGN(26)
                        SAVE_GRADIENT_SIGN(27)
                        SAVE_GRADIENT_SIGN(28)
                        SAVE_GRADIENT_SIGN(29)
                        SAVE_GRADIENT_SIGN(30)
                        SAVE_GRADIENT_SIGN(31)

                        ACCUMULATE_SIGN()

                    }   
                }
            }

            /* ---------------------pool2--------------------- */

            else{ 
                counter_num_workers_pool2.read(meta.counter_value, hdr.preamble.pool_index); // Load gradient counter of seg_number

                bit<1> sent_seg_num;
                sent_seg_num_pool2.read(sent_seg_num,meta.pool_index);
                seen_pool2.read(meta.seen_pool2_bitmap, meta.pool_index);

                // if(sent_seg_num == 1){
                if(meta.worker_bitmap_mask & meta.seen_pool2_bitmap != 0){
                    if(meta.counter_value == 0){
                        forward_to_worker_pool2(); // In case of SW -> Worker loss, thus retransmit
                    }
                    else{
                        // No Actions, because packet is duplicate retransmission
                        drop();
                    }
                }
                else {
                    meta.seen_pool2_bitmap = meta.seen_pool2_bitmap | meta.worker_bitmap_mask;
                    seen_pool2.write(meta.pool_index, meta.seen_pool2_bitmap);

                    AGGREGATION_POOL2(0)
                    AGGREGATION_POOL2(1)
                    AGGREGATION_POOL2(2)
                    AGGREGATION_POOL2(3)
                    AGGREGATION_POOL2(4)
                    AGGREGATION_POOL2(5)
                    AGGREGATION_POOL2(6)
                    AGGREGATION_POOL2(7)
                    AGGREGATION_POOL2(8)
                    AGGREGATION_POOL2(9)
                    AGGREGATION_POOL2(10)
                    AGGREGATION_POOL2(11)
                    AGGREGATION_POOL2(12)
                    AGGREGATION_POOL2(13)
                    AGGREGATION_POOL2(14)
                    AGGREGATION_POOL2(15)
                    AGGREGATION_POOL2(16)
                    AGGREGATION_POOL2(17)
                    AGGREGATION_POOL2(18)
                    AGGREGATION_POOL2(19)
                    AGGREGATION_POOL2(20)
                    AGGREGATION_POOL2(21)
                    AGGREGATION_POOL2(22)
                    AGGREGATION_POOL2(23)
                    AGGREGATION_POOL2(24)
                    AGGREGATION_POOL2(25)
                    AGGREGATION_POOL2(26)
                    AGGREGATION_POOL2(27)
                    AGGREGATION_POOL2(28)
                    AGGREGATION_POOL2(29)
                    AGGREGATION_POOL2(30)
                    AGGREGATION_POOL2(31)
                    
                    drop();

                    meta.counter_value = meta.counter_value + 1;
                    counter_num_workers_pool2.write(meta.pool_index, meta.counter_value);

                    if(meta.counter_value >= meta.k){    // When all gradients are received : broadcast
                      
                        broadcast();
                        seen_pool1.write(meta.pool_index, 0);

                        READ_FOR_BROADCAST_POOL2(0)
                        READ_FOR_BROADCAST_POOL2(1)
                        READ_FOR_BROADCAST_POOL2(2)
                        READ_FOR_BROADCAST_POOL2(3)
                        READ_FOR_BROADCAST_POOL2(4)
                        READ_FOR_BROADCAST_POOL2(5)
                        READ_FOR_BROADCAST_POOL2(6)
                        READ_FOR_BROADCAST_POOL2(7)
                        READ_FOR_BROADCAST_POOL2(8)
                        READ_FOR_BROADCAST_POOL2(9)
                        READ_FOR_BROADCAST_POOL2(10)
                        READ_FOR_BROADCAST_POOL2(11)
                        READ_FOR_BROADCAST_POOL2(12)
                        READ_FOR_BROADCAST_POOL2(13)
                        READ_FOR_BROADCAST_POOL2(14)
                        READ_FOR_BROADCAST_POOL2(15)
                        READ_FOR_BROADCAST_POOL2(16)
                        READ_FOR_BROADCAST_POOL2(17)
                        READ_FOR_BROADCAST_POOL2(18)
                        READ_FOR_BROADCAST_POOL2(19)
                        READ_FOR_BROADCAST_POOL2(20)
                        READ_FOR_BROADCAST_POOL2(21)
                        READ_FOR_BROADCAST_POOL2(22)
                        READ_FOR_BROADCAST_POOL2(23)
                        READ_FOR_BROADCAST_POOL2(24)
                        READ_FOR_BROADCAST_POOL2(25)
                        READ_FOR_BROADCAST_POOL2(26)
                        READ_FOR_BROADCAST_POOL2(27)
                        READ_FOR_BROADCAST_POOL2(28)
                        READ_FOR_BROADCAST_POOL2(29)
                        READ_FOR_BROADCAST_POOL2(30)
                        READ_FOR_BROADCAST_POOL2(31)

                        counter_num_workers_pool2.write(meta.pool_index,0);

                        // sent_seg_num_pool2.write(meta.pool_index, 1);
                        // sent_seg_num_pool1.write(meta.pool_index, 0);

                        // parameter_pool2.write(hdr.preamble.pool_index + 0,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 1,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 2,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 3,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 4,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 5,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 6,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 7,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 8,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 9,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 10,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 11,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 12,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 13,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 14,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 15,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 16,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 17,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 18,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 19,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 20,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 21,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 22,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 23,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 24,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 25,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 26,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 27,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 28,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 29,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 30,0);
                        // parameter_pool2.write(hdr.preamble.pool_index + 31,0);
                        // reset counter_num_workers

                        // Save current sign of global gradients

                        SAVE_GRADIENT_SIGN(0)
                        SAVE_GRADIENT_SIGN(1)
                        SAVE_GRADIENT_SIGN(2)
                        SAVE_GRADIENT_SIGN(3)
                        SAVE_GRADIENT_SIGN(4)
                        SAVE_GRADIENT_SIGN(5)
                        SAVE_GRADIENT_SIGN(6)
                        SAVE_GRADIENT_SIGN(7)
                        SAVE_GRADIENT_SIGN(8)
                        SAVE_GRADIENT_SIGN(9)
                        SAVE_GRADIENT_SIGN(10)
                        SAVE_GRADIENT_SIGN(11)
                        SAVE_GRADIENT_SIGN(12)
                        SAVE_GRADIENT_SIGN(13)
                        SAVE_GRADIENT_SIGN(14)
                        SAVE_GRADIENT_SIGN(15)
                        SAVE_GRADIENT_SIGN(16)
                        SAVE_GRADIENT_SIGN(17)
                        SAVE_GRADIENT_SIGN(18)
                        SAVE_GRADIENT_SIGN(19)
                        SAVE_GRADIENT_SIGN(20)
                        SAVE_GRADIENT_SIGN(21)
                        SAVE_GRADIENT_SIGN(22)
                        SAVE_GRADIENT_SIGN(23)
                        SAVE_GRADIENT_SIGN(24)
                        SAVE_GRADIENT_SIGN(25)
                        SAVE_GRADIENT_SIGN(26)
                        SAVE_GRADIENT_SIGN(27)
                        SAVE_GRADIENT_SIGN(28)
                        SAVE_GRADIENT_SIGN(29)
                        SAVE_GRADIENT_SIGN(30)
                        SAVE_GRADIENT_SIGN(31)

                        ACCUMULATE_SIGN()

                            
                    }   
                }
            }
            hdr.preamble.k = meta.k;   
        }
    
        else if(meta.frame_type == 2){ // When packet is global gradient packet
                // TODO: routing to nodes
        }

        // else if(meta.frame_type == 3){ // frame_type : 3
            
        //     broadcast();

        //         if(meta.seg_number % 2 == 0){
        //             READ_FOR_BROADCAST_POOL1(0)
        //             READ_FOR_BROADCAST_POOL1(1)
        //             READ_FOR_BROADCAST_POOL1(2)
        //             READ_FOR_BROADCAST_POOL1(3)
        //             READ_FOR_BROADCAST_POOL1(4)
        //             READ_FOR_BROADCAST_POOL1(5)
        //             READ_FOR_BROADCAST_POOL1(6)
        //             READ_FOR_BROADCAST_POOL1(7)
        //             READ_FOR_BROADCAST_POOL1(8)
        //             READ_FOR_BROADCAST_POOL1(9)
        //         }

        //         else{
        //             READ_FOR_BROADCAST_POOL2(0)
        //             READ_FOR_BROADCAST_POOL2(1)
        //             READ_FOR_BROADCAST_POOL2(2)
        //             READ_FOR_BROADCAST_POOL2(3)
        //             READ_FOR_BROADCAST_POOL2(4)
        //             READ_FOR_BROADCAST_POOL2(5)
        //             READ_FOR_BROADCAST_POOL2(6)
        //             READ_FOR_BROADCAST_POOL2(7)
        //             READ_FOR_BROADCAST_POOL2(8)
        //             READ_FOR_BROADCAST_POOL2(9)

        //         }

        // }
        else{ // Other packets
            ipv4_forward.apply();
        }
    }
}



control MyEgress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    
    // register<bit<48>>(1)    start_time_register_egress;
    // register<bit<48>>(1)    time1_egress;
    // register<bit<48>>(1)    time2_egress;
    // register<bit<48>>(1)    elapsed_time_register_egress;
    
    

    // action start_recirculation(){
    //     recirculate(meta);
    //     meta.recirculation_flag = 1;
    // }

    // action save_start_time_egress(){
    //     start_time_register_egress.write(0, standard_metadata.egress_global_timestamp);
    // }

    // action elapsed_time_calculation(){
    //     bit<48> start_time;
    //     bit<48> receive_time;
    //     start_time_register_egress.read(start_time,0);
    //     receive_time = standard_metadata.egress_global_timestamp;
    //     meta.elapsed_time = receive_time - start_time;
    //     time1_egress.write(0,receive_time); //
    //     time2_egress.write(0,start_time); //
    //     elapsed_time_register_egress.write(0,meta.elapsed_time);
    // }




    apply {
        // if(meta.stop_recirculation_flag == 0){}
        //     if(meta.counter_value == 1 && meta.recirculation_flag == 0){
        //         save_start_time_egress();
        //         // start_recirculation();
        //     }
            
        //     if(meta.recirculation_flag == 1 && meta.broadcast_flag == 0){ // When packet is timer packet
        //         elapsed_time_calculation();
                
        //         if(meta.elapsed_time > 15000000){ // 1,500,000 ns = 1.5s
        //             // mark_to_drop(standard_metadata);
        //             meta.recirculation_flag = 0;
        //             meta.broadcast_flag = 1;
        //             recirculate(meta);
        //         }
        //         else{
        //             start_recirculation();
        //         }
        //     }
        // else{
        //     meta.recirculation_flag = 0;
        // }
    }
}

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply {}
}

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.frame_type);
        packet.emit(hdr.preamble);
        packet.emit(hdr.gradient);
    }
}

V1Switch(
    MyParser(),
    MyVerifyChecksum(),
    MyIngress(),
    MyEgress(),
    MyComputeChecksum(),
    MyDeparser()
) main;
