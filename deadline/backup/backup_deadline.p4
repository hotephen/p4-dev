/* -*- P4_16 -*- */

#include <core.p4>
#include <v1model.p4>

#define KEY_SIZE 32
#define VALUE_SIZE 32
#define NUM_OF_ENTRIES 10 // switchML's size
#define NUM_OF_WORKERS 5 

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
}

header preamble_t {
    bit<32>     number_of_entries;
    bit<32>     seg_number;
}


header entry_t {
    bit<KEY_SIZE> key;  //  FIXME:
    bit<VALUE_SIZE> value;
}

struct metadata {
    bit<32>  number_of_entries;
    bit<8>  end_flag;
    bit<32> seg_number;
    bit<8>  counter_value;
    bit<32> gradient_value;
    bit<8>  broadcast_flag;
    bit<48> elapsed_time;
    bit<8> recirculation_flag;
}
 
struct headers {
    ethernet_t ethernet;
    ipv4_t ipv4;
    udp_t udp;
    frame_type_t frame_type;
    preamble_t preamble;
    entry_t[NUM_OF_ENTRIES] entry;
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
        transition select(hdr.frame_type.frame_type){  
            0x00 : parse_preamble;
            default : accept;
        }
    }

    state parse_preamble {
        packet.extract(hdr.preamble);
        // meta.tree_id = hdr.preamble.tree_id;
        // meta.end_flag = 0;
        meta.number_of_entries = hdr.preamble.number_of_entries;
        meta.seg_number = hdr.preamble.seg_number;
        transition parse_entry;  
    }


    state parse_entry {
        packet.extract(hdr.entry[0]);
        packet.extract(hdr.entry[1]);
        packet.extract(hdr.entry[2]);
        packet.extract(hdr.entry[3]);
        packet.extract(hdr.entry[4]);
        packet.extract(hdr.entry[5]);
        packet.extract(hdr.entry[6]);
        packet.extract(hdr.entry[7]);
        packet.extract(hdr.entry[8]);
        packet.extract(hdr.entry[9]);
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

    /* Deadline registers */
    register<bit<48>>(1)    start_time_register;
    register<bit<48>>(1)    elapsed_time_register;
    register<bit<48>>(1)    time1;
    register<bit<48>>(1)    time2;
    register<bit<48>>(1)    time3;

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

    }

    action start_recirculation(){
        // recirculate(standard_metadata.egress_spec);
        // resubmit(standard_metadata);
    }



    /* ------------ Register Definition ------------ */
    /* ------------ Register Definition ------------ */


    #define POOL_SIZE 1024
    register<bit<VALUE_SIZE>>(POOL_SIZE) parameter_pool1;
    register<bit<VALUE_SIZE>>(POOL_SIZE) parameter_pool2;
    register<bit<8>>(10) counter_num_workers;



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
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
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
        size = 2048;
        default_action = forward_to_2();
    }

    /* Start ingress */
    /* Start ingress */
        
    apply{
        
        counter_num_workers.read(meta.counter_value, meta.seg_number);
        // meta.receive_time = standard_metadata.ingress_global_timestamp;


        // Deadline logic
        // if(meta.counter_value == 0){
        //     save_start_time();
        //     start_recirculation();
        // }

        if(standard_metadata.instance_type != 0){
        //     elapsed_time_calculation();
        //     if(meta.elapsed_time > 100000){
        //         mark_to_drop(standard_metadata);
        //     }
        //     else{
        //         start_recirculation();
        //     }
            
        }
        
        else{

            // Aggregation logic
            if(meta.seg_number % 2 == 0){ // When seg_number is even
                
                #define AGGREGATION_POOL1(i) \
                parameter_pool1.read(meta.gradient_value, meta.seg_number+##i); \
                meta.gradient_value = meta.gradient_value + hdr.entry[##i].value; \
                parameter_pool1.write(meta.seg_number+##i,meta.gradient_value); \
                hdr.entry[##i].value = meta.gradient_value; \

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

                // counter_num_workers.read(meta.counter_value, meta.seg_number);
                meta.counter_value = meta.counter_value + 1;
                counter_num_workers.write(meta.seg_number, meta.counter_value);

                if(meta.counter_value == NUM_OF_WORKERS || meta.elapsed_time > 10){    // When all gradients are received
                    broadcast();
                    parameter_pool1.write(meta.seg_number,0); 
                    parameter_pool1.write(meta.seg_number+1,0); 
                    parameter_pool1.write(meta.seg_number+2,0); 
                    parameter_pool1.write(meta.seg_number+3,0); 
                    parameter_pool1.write(meta.seg_number+4,0); 
                    parameter_pool1.write(meta.seg_number+5,0); 
                    parameter_pool1.write(meta.seg_number+6,0); 
                    parameter_pool1.write(meta.seg_number+7,0); 
                    parameter_pool1.write(meta.seg_number+8,0); 
                    parameter_pool1.write(meta.seg_number+9,0); 
                    counter_num_workers.write(meta.seg_number, 0);
                }   
            }

            else{ // When seg_number is odd
                
                #define AGGREGATION_POOL2(i) \
                parameter_pool2.read(meta.gradient_value, meta.seg_number+##i); \
                meta.gradient_value = meta.gradient_value + hdr.entry[##i].value; \
                parameter_pool2.write(meta.seg_number+##i,meta.gradient_value); \
                hdr.entry[##i].value = meta.gradient_value; \

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

                // counter_num_workers.read(meta.counter_value, meta.seg_number);
                meta.counter_value = meta.counter_value + 1;
                counter_num_workers.write(meta.seg_number, meta.counter_value);

                if(meta.counter_value == NUM_OF_WORKERS || meta.elapsed_time > 10 ){    // When all gradients are received
                    broadcast();
                    parameter_pool2.write(meta.seg_number,0); 
                    parameter_pool2.write(meta.seg_number+1,0); 
                    parameter_pool2.write(meta.seg_number+2,0); 
                    parameter_pool2.write(meta.seg_number+3,0); 
                    parameter_pool2.write(meta.seg_number+4,0); 
                    parameter_pool2.write(meta.seg_number+5,0); 
                    parameter_pool2.write(meta.seg_number+6,0); 
                    parameter_pool2.write(meta.seg_number+7,0); 
                    parameter_pool2.write(meta.seg_number+8,0); 
                    parameter_pool2.write(meta.seg_number+9,0); 
                    counter_num_workers.write(meta.seg_number, 0);
                }   
            }
        }
        ipv4_forward.apply();
    }
}





control MyEgress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    
    register<bit<48>>(1)    start_time_register_egress;
    register<bit<48>>(1)    time1_egress;
    register<bit<48>>(1)    time2_egress;
    register<bit<48>>(1)    elapsed_time_register_egress;
    
    

    action start_recirculation(){
        recirculate(meta);
        meta.recirculation_flag = 1;
    }

    action save_start_time_egress(){
        start_time_register_egress.write(0, standard_metadata.egress_global_timestamp);
    }

    action elapsed_time_calculation(){
        bit<48> start_time;
        bit<48> receive_time;
        start_time_register_egress.read(start_time,0);
        receive_time = standard_metadata.egress_global_timestamp;
        meta.elapsed_time = receive_time - start_time;
        time1_egress.write(0,receive_time); //
        time2_egress.write(0,start_time); //
        elapsed_time_register_egress.write(0,meta.elapsed_time);
    }




    apply {

        if(meta.counter_value == 1 && meta.recirculation_flag == 0){
            save_start_time_egress();
            start_recirculation();
        }
        
        if(meta.recirculation_flag == 1 && meta.broadcast_flag == 0){
            elapsed_time_calculation();
            
            if(meta.elapsed_time > 1500000){ // 1,500,000 ns = 1.5s
                // mark_to_drop(standard_metadata);
                meta.recirculation_flag = 0;
                meta.broadcast_flag = 1;
                recirculate(meta);
            }
            else{
                start_recirculation();
            }
        }
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
        packet.emit(hdr.entry[0]);
        packet.emit(hdr.entry[1]);
        packet.emit(hdr.entry[2]);
        packet.emit(hdr.entry[3]);
        packet.emit(hdr.entry[4]);
        packet.emit(hdr.entry[5]);
        packet.emit(hdr.entry[6]);
        packet.emit(hdr.entry[7]);
        packet.emit(hdr.entry[8]);
        packet.emit(hdr.entry[9]);
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

    

    
    
    
    
    
