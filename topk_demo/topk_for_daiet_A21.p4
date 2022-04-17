/* -*- P4_16 -*- */

#include <core.p4>
#include <v1model.p4>

#define KEY_SIZE 128
#define VALUE_SIZE 32
#define NUM_OF_ENTRIES_IN_REGISTER 10
#define NUM_OF_ENTRIES 10

#define REGISTER_SIZE 100000
#define NUMBER_OF_TREES 4
#define NUMBER_OF_CELLS 16w400 // to be modifed for adjusting register size
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

// header flag_t {
//     bit<8> flush;
// }

// header end_t {
//     bit<32>     tree_id;
// }

header frame_type_t {
    bit<8>      frame_type;
}


header preamble_t {
    bit<32>     remaining_number_of_entries;
    bit<32>     tree_id;
}


header entry_t {
    bit<KEY_SIZE> key;
    bit<VALUE_SIZE> value;
}

struct metadata {
    bit<32> number_of_entries;
    bit<5> num_of_pushout_entries;
    bit<32> tree_id;
    bit<32> tree_id_for_hash2;
    bit<32> tree_id_for_hash3;
    bit<32> remaining_number_of_entries;
    bit<8>  flush;
    bit<32> valid_entries_index;
    bit<32> valid_entries_stack;
    bit<32> temp;

}
 
struct headers {
    ethernet_t ethernet;
    ipv4_t ipv4;
    udp_t udp;
    frame_type_t frame_type;
    preamble_t preamble;
    // end_t end;
    entry_t[NUM_OF_ENTRIES] entry;
}


// ----------------------------
// ---------- parser ----------
// ----------------------------

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
            // 0x00 : parse_preamble;
            // 0x01 : parse_end;    
            default : parse_preamble;
        }
    }

    state parse_preamble {
        packet.extract(hdr.preamble);
        meta.tree_id = hdr.preamble.tree_id;
        meta.remaining_number_of_entries = hdr.preamble.remaining_number_of_entries;
        // meta.flush = 0;
        transition parse_entry;  
    }

    // state parse_end {
    //     packet.extract(hdr.end);
    //     meta.tree_id = hdr.end.tree_id;
    //     meta.flush = 1;
    //     transition accept;
    // }

    state parse_entry {
        // packet.extract(hdr.flag);
        #define PARSE_ENTRY(i) \
        packet.extract(hdr.entry[##i]); \
        if (meta.remaining_number_of_entries > 0){ \
            meta.remaining_number_of_entries = meta.remaining_number_of_entries - 1; \
        } \

        PARSE_ENTRY(0)
        PARSE_ENTRY(1)
        PARSE_ENTRY(2)
        PARSE_ENTRY(3)
        PARSE_ENTRY(4)
        PARSE_ENTRY(5)
        PARSE_ENTRY(6)
        PARSE_ENTRY(7)
        PARSE_ENTRY(8)
        PARSE_ENTRY(9)
        
        // packet.extract(hdr.entry[1]);
        // packet.extract(hdr.entry[2]);
        // packet.extract(hdr.entry[3]);
        // packet.extract(hdr.entry[4]);
        // packet.extract(hdr.entry[5]);
        // packet.extract(hdr.entry[6]);
        // packet.extract(hdr.entry[7]);
        // packet.extract(hdr.entry[8]);
        // packet.extract(hdr.entry[9]);
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

    action drop() {
        mark_to_drop(standard_metadata);
        // mark_to_drop();
    }

    action set_egress(bit<9> port) {
        standard_metadata.egress_spec = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    action set_flush(bit<9> port) {
        standard_metadata.egress_spec = port;
        hdr.frame_type.frame_type = 1;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        hdr.ipv4.dstAddr = 0x0A000010;
    }

    action no(){
        hdr.frame_type.frame_type = 5;
        drop();

    }
    table ipv4_forward {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            no();
            set_egress();
            set_flush();
            drop();
        }
        default_action = no;
    }



    // #define HASH_BASE_1 16w1
    // #define HASH_MAX_1 16w5000
    // #define HASH_BASE_2 16w5001
    // #define HASH_MAX_2 16w10000
    // #define HASH_BASE_3 16w10001
    // #define HASH_MAX_3 16w15000

    // register<T>(bit<32> instance_count) register_name
    // hash(register_position, HashAlgorithm, HASH_BASE, values, HASH_MAX)
    // register_name.write(register_position, values)
    // register_name.read(readvalue, register_position)
    
    register<bit<KEY_SIZE>>(REGISTER_SIZE) topk_key_table_1;
    register<bit<VALUE_SIZE>>(REGISTER_SIZE) topk_value_table_1;
    register<bit<VALUE_SIZE>>(REGISTER_SIZE) topk_counter_table_1;
    register<bit<KEY_SIZE>>(NUM_OF_ENTRIES + NUM_OF_ENTRIES+1) pushout_key_table;
    register<bit<VALUE_SIZE>>(NUM_OF_ENTRIES + NUM_OF_ENTRIES+1) pushout_value_table;
    register<bit<32>>(NUMBER_OF_TREES) valid_entries_index; // num_of_entries_cnt
    register<bit<32>>(REGISTER_SIZE) valid_entries_stack;
    register<bit<5>>(1) pushout_cnt;
    register<bit<32>>(1) num_of_entries_cnt;
    
    action flush_entry0(bit<5> pushout_table_cnt) {
        hdr.entry[0].setValid();
        pushout_key_table.read(hdr.entry[0].key, (bit<32>)(pushout_table_cnt));
        pushout_value_table.read(hdr.entry[0].value, (bit<32>)(pushout_table_cnt));
        hdr.preamble.remaining_number_of_entries = hdr.preamble.remaining_number_of_entries + 1;
    }

    #define ACTION_FLUSH(i,j) \
    action flush_entry##i(bit<5> pushout_table_cnt) { \
        hdr.entry[##i].setValid(); \
        pushout_key_table.read(hdr.entry[##i].key, (bit<32>)(pushout_table_cnt)); \
        pushout_value_table.read(hdr.entry[##i].value, (bit<32>)(pushout_table_cnt)); \
        hdr.preamble.remaining_number_of_entries = hdr.preamble.remaining_number_of_entries + 1; \
        flush_entry##j(pushout_table_cnt - 1); \
    } \

    ACTION_FLUSH(1,0) // flush_entry1
    ACTION_FLUSH(2,1)
    ACTION_FLUSH(3,2)
    ACTION_FLUSH(4,3)
    ACTION_FLUSH(5,4)
    ACTION_FLUSH(6,5)
    ACTION_FLUSH(7,6)
    ACTION_FLUSH(8,7)
    ACTION_FLUSH(9,8)

    table flush_pushout_table {
        key = {
            meta.num_of_pushout_entries: exact;
        }
        actions = {
            drop;
            flush_entry0;
            flush_entry1;
            flush_entry2;
            flush_entry3;
            flush_entry4;
            flush_entry5;
            flush_entry6;
            flush_entry7;
            flush_entry8;
            flush_entry9;
        }
        size = 2048;
        default_action = drop;
    }

    apply {
        ipv4_forward.apply();

        bit<32> register_idx;
        bit<KEY_SIZE> stored_key;
        bit<VALUE_SIZE> stored_value;
        bit<VALUE_SIZE> counter_value;
        bit<KEY_SIZE> pushout_key;
        bit<VALUE_SIZE> pushout_value;
        bit<5> pushout_table_cnt;
        bit<2> is_saved;
        bit<2> is_popped;


        if ( hdr.frame_type.frame_type == 0 ) {
            // num_of_entries_cnt.write(0, REGISTER_SIZE - 1);
            valid_entries_index.read(meta.valid_entries_index, meta.tree_id);
            // meta.remaining_number_of_entries = hdr.preamble.remaining_number_of_entries;

            #define TOPK_LOGIC(i) \
            { \ 
                if(hdr.preamble.remaining_number_of_entries != 0){ \
                    stored_key = 0; \
                    counter_value = 0; \
                    is_saved = 0; \
                    is_popped = 0; \
                    pushout_key=0; \
                    pushout_value=0; \
                    hash(register_idx, HashAlgorithm.crc32, ((bit<16>)meta.tree_id-1)*NUMBER_OF_CELLS+1, { hdr.entry[##i].key }, NUMBER_OF_CELLS); \
                    topk_key_table_1.read(stored_key, register_idx); \
                    topk_value_table_1.read(stored_value, register_idx); \
                    topk_counter_table_1.read(counter_value, register_idx); \
                    if (stored_key == 0 || stored_key == hdr.entry[##i].key) { \ 
                        topk_key_table_1.write(register_idx, hdr.entry[##i].key); \
                        stored_value = stored_value + hdr.entry[##i].value; \
                        topk_value_table_1.write(register_idx, stored_value); \
                        counter_value = counter_value + 1; \
                        topk_counter_table_1.write(register_idx, counter_value); \
                        is_saved = 1; \
                        if(stored_key == 0){ \
                            meta.valid_entries_index = meta.valid_entries_index + 1; \
                            valid_entries_stack.write(meta.valid_entries_index, register_idx); \
                            topk_counter_table_1.write(register_idx, 1); \
                        } \
                    } else { \
                        if (counter_value >= 1) { \
                            pushout_key = hdr.entry[##i].key; \
                            pushout_value = hdr.entry[##i].value; \
                            is_saved = 0; \
                        } else { \
                            pushout_key = stored_key; \
                            pushout_value = stored_value; \
                            topk_key_table_1.write(register_idx, hdr.entry[##i].key); \
                            topk_value_table_1.write(register_idx, hdr.entry[##i].value); \
                            topk_counter_table_1.write(register_idx, 1); \
                            is_saved = 2; \
                        } \
                    } \
                    if (is_saved != 1) { \
                        meta.tree_id_for_hash2 = meta.tree_id + NUMBER_OF_TREES; \
                        hash(register_idx, HashAlgorithm.crc32_custom, ((bit<16>)meta.tree_id)*NUMBER_OF_CELLS+1, { pushout_key }, NUMBER_OF_CELLS); \
                        topk_key_table_1.read(stored_key, register_idx); \
                        topk_value_table_1.read(stored_value, register_idx); \
                        topk_counter_table_1.read(counter_value, register_idx); \
                        if (stored_key == 0 || stored_key == pushout_key) {  \
                            topk_key_table_1.write(register_idx, pushout_key); \
                            stored_value = stored_value + pushout_value; \
                            topk_value_table_1.write(register_idx, stored_value); \
                            counter_value = counter_value + 1; \
                            topk_counter_table_1.write(register_idx, counter_value); \
                            is_saved = 1; \
                            if(stored_key == 0){ \
                                meta.valid_entries_index = meta.valid_entries_index + 1; \
                                valid_entries_stack.write(meta.valid_entries_index, register_idx); \
                                topk_counter_table_1.write(register_idx, 1); \
                            } \
                        } else {   \
                            if (counter_value >= 1) { \
                                is_saved = 0; \ 
                            } else { \
                                topk_key_table_1.write(register_idx, pushout_key); \
                                topk_value_table_1.write(register_idx, pushout_value); \ 
                                pushout_key = stored_key; \
                                pushout_value = stored_value; \
                                topk_counter_table_1.write(register_idx, 1); \
                                is_saved = 2; \
                            } \
                        } \
                    } \
                    if (is_saved != 1) { \
                        meta.tree_id_for_hash3 = meta.tree_id_for_hash2 + NUMBER_OF_TREES; \
                        hash(register_idx, HashAlgorithm.crc16, ((bit<16>)meta.tree_id+1)*NUMBER_OF_CELLS+1, { pushout_key }, NUMBER_OF_CELLS); \
                        topk_key_table_1.read(stored_key, register_idx); \
                        topk_value_table_1.read(stored_value, register_idx); \
                        topk_counter_table_1.read(counter_value, register_idx); \
                        if (stored_key == 0 || stored_key == pushout_key) {  \
                            topk_key_table_1.write(register_idx, pushout_key); \
                            stored_value = stored_value + pushout_value; \
                            topk_value_table_1.write(register_idx, stored_value); \
                            counter_value = counter_value + 1; \
                            topk_counter_table_1.write(register_idx, counter_value); \
                            is_saved = 1; \
                            if(stored_key == 0){ \
                                meta.valid_entries_index = meta.valid_entries_index + 1; \
                                valid_entries_stack.write(meta.valid_entries_index, register_idx); \
                                topk_counter_table_1.write(register_idx, 1); \
                            } \
                        } else { \
                            if (counter_value >= 1) {  \
                                is_saved = 0; \
                            } else { \
                                topk_key_table_1.write(register_idx, pushout_key); \
                                topk_value_table_1.write(register_idx, pushout_value); \
                                pushout_key = stored_key; \
                                pushout_value = stored_value; \
                                topk_counter_table_1.write(register_idx, 1); \
                                is_saved = 2; \
                            } \
                        } \
                    } \
                    if (is_saved != 1) { \
                        pushout_cnt.read(pushout_table_cnt, 0); \
                        pushout_table_cnt = pushout_table_cnt + 1; \
                        pushout_key_table.write((bit<32>)pushout_table_cnt, pushout_key); \
                        pushout_value_table.write((bit<32>)pushout_table_cnt, pushout_value); \
                        pushout_cnt.write(0, pushout_table_cnt); \
                    } \
                    meta.remaining_number_of_entries = meta.remaining_number_of_entries - 1; \
                    hdr.preamble.remaining_number_of_entries = hdr.preamble.remaining_number_of_entries - 1; \
                } \
            }   \
            
            /* processing each entry */
            TOPK_LOGIC(0)
            TOPK_LOGIC(1)
            TOPK_LOGIC(2)
            TOPK_LOGIC(3)
            TOPK_LOGIC(4)
            TOPK_LOGIC(5)
            TOPK_LOGIC(6)
            TOPK_LOGIC(7)
            TOPK_LOGIC(8)
            TOPK_LOGIC(9)

            /* */
            pushout_cnt.read(meta.num_of_pushout_entries, 0);
            
            // valid_entries_index.read(meta.temp, meta.tree_id);
            // meta.temp = meta.temp + meta.valid_entries_index;
            valid_entries_index.write(meta.tree_id, meta.valid_entries_index);
            
            if (meta.num_of_pushout_entries < NUM_OF_ENTRIES) { // Do not forward yet.
                drop();
            } else { // flush entries ... LIFO
           	
            hdr.entry[0].setValid();
            hdr.entry[1].setValid();
            hdr.entry[2].setValid();
            hdr.entry[3].setValid();
            hdr.entry[4].setValid();
            hdr.entry[5].setValid();
            hdr.entry[6].setValid();
            hdr.entry[7].setValid();
            hdr.entry[8].setValid();
            hdr.entry[9].setValid();
               
            pushout_key_table.read(hdr.entry[0].key, (bit<32>)(meta.num_of_pushout_entries));
            pushout_value_table.read(hdr.entry[0].value, (bit<32>)(meta.num_of_pushout_entries));
           	pushout_key_table.read(hdr.entry[1].key, (bit<32>)(meta.num_of_pushout_entries - 1));
   	        pushout_value_table.read(hdr.entry[1].value, (bit<32>)(meta.num_of_pushout_entries - 1));
  	        pushout_key_table.read(hdr.entry[2].key, (bit<32>)(meta.num_of_pushout_entries - 2));
   	        pushout_value_table.read(hdr.entry[2].value, (bit<32>)(meta.num_of_pushout_entries - 2));
            pushout_key_table.read(hdr.entry[3].key, (bit<32>)(meta.num_of_pushout_entries - 3));
            pushout_value_table.read(hdr.entry[3].value, (bit<32>)(meta.num_of_pushout_entries - 3));
            pushout_key_table.read(hdr.entry[4].key, (bit<32>)(meta.num_of_pushout_entries - 4));
            pushout_value_table.read(hdr.entry[4].value, (bit<32>)(meta.num_of_pushout_entries - 4));
            pushout_key_table.read(hdr.entry[5].key, (bit<32>)(meta.num_of_pushout_entries - 5));
            pushout_value_table.read(hdr.entry[5].value, (bit<32>)(meta.num_of_pushout_entries - 5));
            pushout_key_table.read(hdr.entry[6].key, (bit<32>)(meta.num_of_pushout_entries - 6));
            pushout_value_table.read(hdr.entry[6].value, (bit<32>)(meta.num_of_pushout_entries - 6));
            pushout_key_table.read(hdr.entry[7].key, (bit<32>)(meta.num_of_pushout_entries - 7));
            pushout_value_table.read(hdr.entry[7].value, (bit<32>)(meta.num_of_pushout_entries - 7));
            pushout_key_table.read(hdr.entry[8].key, (bit<32>)(meta.num_of_pushout_entries - 8));
            pushout_value_table.read(hdr.entry[8].value, (bit<32>)(meta.num_of_pushout_entries - 8));
            pushout_key_table.read(hdr.entry[9].key, (bit<32>)(meta.num_of_pushout_entries - 9));
            pushout_value_table.read(hdr.entry[9].value, (bit<32>)(meta.num_of_pushout_entries - 9));

            hdr.preamble.remaining_number_of_entries = 10;
            meta.num_of_pushout_entries = meta.num_of_pushout_entries - 10;
            pushout_cnt.write(0, meta.num_of_pushout_entries);

            }
        } else if(hdr.frame_type.frame_type == 1) { // flush the all of entries stored in register
            // num_of_entries_cnt.read(meta.number_of_entries, 0);
            valid_entries_index.read(meta.number_of_entries, meta.tree_id);
            hdr.preamble.remaining_number_of_entries = 0;

            if ( meta.number_of_entries > 0 ) {
                
                meta.temp = 10;

                #define FLUSH_TOPK(i) \
                if(meta.number_of_entries > 0){ \
                valid_entries_stack.read(register_idx, meta.number_of_entries); \
                topk_key_table_1.read(hdr.entry[##i].key, register_idx); \
                topk_value_table_1.read(hdr.entry[##i].value, register_idx); \
                topk_key_table_1.write(register_idx, 0); \
                topk_value_table_1.write(register_idx, 0); \
                valid_entries_stack.write(meta.number_of_entries, 0); \
                meta.number_of_entries = meta.number_of_entries - 1; \
                meta.temp = meta.temp - 1; \
                hdr.preamble.remaining_number_of_entries = hdr.preamble.remaining_number_of_entries + 1; \
                } \

                FLUSH_TOPK(0)
                FLUSH_TOPK(1)
                FLUSH_TOPK(2)
                FLUSH_TOPK(3)
                FLUSH_TOPK(4)
                FLUSH_TOPK(5)
                FLUSH_TOPK(6)
                FLUSH_TOPK(7)
                FLUSH_TOPK(8)
                FLUSH_TOPK(9)

                #define INVALID_ENTRY(i) \
                if(meta.temp > 0){ \
                    hdr.entry[##i].key = 0 ; \
                    hdr.entry[##i].value = 0 ; \
                    hdr.entry[##i].setInvalid(); \
                    meta.temp = meta.temp - 1; \
                } \

                INVALID_ENTRY(9)
                INVALID_ENTRY(8)
                INVALID_ENTRY(7)
                INVALID_ENTRY(6)
                INVALID_ENTRY(5)
                INVALID_ENTRY(4)
                INVALID_ENTRY(3)
                INVALID_ENTRY(2)
                INVALID_ENTRY(1)

                hdr.frame_type.frame_type = 0; 
                clone3(CloneType.I2E, 100, standard_metadata);

                
                // if (standard_metadata.egress_spec == 5){
                //     recirculate(standard_metadata);
                // }

            } else {
                pushout_cnt.read(meta.num_of_pushout_entries, 0);
                hdr.preamble.remaining_number_of_entries = 0;
                meta.temp = 10 - (bit<32>)(meta.num_of_pushout_entries);
                flush_pushout_table.apply();
                pushout_cnt.write(0, 0);

                INVALID_ENTRY(9)
                INVALID_ENTRY(8)
                INVALID_ENTRY(7)
                INVALID_ENTRY(6)
                INVALID_ENTRY(5)
                INVALID_ENTRY(4)
                INVALID_ENTRY(3)
                INVALID_ENTRY(2)
                INVALID_ENTRY(1)
                
                hdr.frame_type.frame_type = 0; 
            }
            
            // num_of_entries_cnt.write(0, meta.number_of_entries);
            valid_entries_index.write(meta.tree_id, meta.number_of_entries);
            
        }
        else{ // frame_type == 2 (Do nothing, just routing)

        }
    }
}

control MyEgress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    apply {
        if (standard_metadata.egress_port == 5){
            recirculate(standard_metadata);
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
        // packet.emit(hdr.end);
        // packet.emit(hdr.flag);
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
