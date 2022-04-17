/* -*- P4_16 -*- */

#include <core.p4>
#include <v1model.p4>

#define KEY_SIZE 128
#define VALUE_SIZE 32
#define NUM_OF_ENTRIES_IN_REGISTER 10
#define NUM_OF_ENTRIES 10

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

header flag_t {
    bit<8> flush;
}

header entry_t {
    bit<KEY_SIZE> key;
    bit<VALUE_SIZE> value;
}

struct metadata {
    bit<14> number_of_entries;
    bit<5> num_of_pushout_entries;
}

struct headers {
    ethernet_t ethernet;
    ipv4_t ipv4;
    udp_t udp;
    flag_t flag;
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
        transition parse_entry;
    }

    state parse_entry {
        packet.extract(hdr.flag);
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

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action set_egress() {
        standard_metadata.egress_spec = 2;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    table ipv4_forward {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            NoAction();
            set_egress;
            drop;
        }
        size = 2048;
        default_action = set_egress;
    }

    #define REGISTER_SIZE 15001
    
    #define HASH_BASE_1 16w1
    #define HASH_MAX_1 16w5000
    #define HASH_BASE_2 16w5001
    #define HASH_MAX_2 16w10000
    #define HASH_BASE_3 16w10001
    #define HASH_MAX_3 16w15000

    // register<T>(bit<32> instance_count) register_name
    // hash(register_position, HashAlgorithm, HASH_BASE, values, HASH_MAX)
    // register_name.write(register_position, values)
    // register_name.read(readvalue, register_position)
    
    register<bit<KEY_SIZE>>(REGISTER_SIZE) topk_key_table_1;
    register<bit<VALUE_SIZE>>(REGISTER_SIZE) topk_value_table_1;
    register<bit<KEY_SIZE>>(NUM_OF_ENTRIES + NUM_OF_ENTRIES) pushout_key_table;
    register<bit<VALUE_SIZE>>(NUM_OF_ENTRIES + NUM_OF_ENTRIES) pushout_value_table;
    register<bit<5>>(1) pushout_cnt;
    register<bit<14>>(1) num_of_entries_cnt;
    
    action flush_entry0(bit<5> pushout_table_cnt) {
        pushout_key_table.read(hdr.entry[0].key, (bit<32>)(pushout_table_cnt - 1));
        pushout_value_table.read(hdr.entry[0].value, (bit<32>)(pushout_table_cnt - 1));
    }

    action flush_entry1(bit<5> pushout_table_cnt) {
        pushout_key_table.read(hdr.entry[1].key, (bit<32>)(pushout_table_cnt - 1));
        pushout_value_table.read(hdr.entry[1].value, (bit<32>)(pushout_table_cnt - 1));
        
        flush_entry0(pushout_table_cnt - 1);
    }

    action flush_entry2(bit<5> pushout_table_cnt) {
        pushout_key_table.read(hdr.entry[2].key, (bit<32>)(pushout_table_cnt - 1));
        pushout_value_table.read(hdr.entry[2].value, (bit<32>)(pushout_table_cnt - 1));
        
        flush_entry1(pushout_table_cnt - 1);
    }

    action flush_entry3(bit<5> pushout_table_cnt) {
        pushout_key_table.read(hdr.entry[3].key, (bit<32>)(pushout_table_cnt - 1));
        pushout_value_table.read(hdr.entry[3].value, (bit<32>)(pushout_table_cnt - 1));
        
        flush_entry2(pushout_table_cnt - 1);
    }

    action flush_entry4(bit<5> pushout_table_cnt) {
        pushout_key_table.read(hdr.entry[4].key, (bit<32>)(pushout_table_cnt - 1));
        pushout_value_table.read(hdr.entry[4].value, (bit<32>)(pushout_table_cnt - 1));
        
        flush_entry3(pushout_table_cnt - 1);
    }

    action flush_entry5(bit<5> pushout_table_cnt) {
        pushout_key_table.read(hdr.entry[5].key, (bit<32>)(pushout_table_cnt - 1));
        pushout_value_table.read(hdr.entry[5].value, (bit<32>)(pushout_table_cnt - 1));
        
        flush_entry4(pushout_table_cnt - 1);
    }

    action flush_entry6(bit<5> pushout_table_cnt) {
        pushout_key_table.read(hdr.entry[6].key, (bit<32>)(pushout_table_cnt - 1));
        pushout_value_table.read(hdr.entry[6].value, (bit<32>)(pushout_table_cnt - 1));
        
        flush_entry5(pushout_table_cnt - 1);
    }

    action flush_entry7(bit<5> pushout_table_cnt) {
        pushout_key_table.read(hdr.entry[7].key, (bit<32>)(pushout_table_cnt - 1));
        pushout_value_table.read(hdr.entry[7].value, (bit<32>)(pushout_table_cnt - 1));
        
        flush_entry6(pushout_table_cnt - 1);
    }

    action flush_entry8(bit<5> pushout_table_cnt) {
        pushout_key_table.read(hdr.entry[8].key, (bit<32>)(pushout_table_cnt - 1));
        pushout_value_table.read(hdr.entry[8].value, (bit<32>)(pushout_table_cnt - 1));
        
        flush_entry7(pushout_table_cnt - 1);
    }

    action flush_entry9(bit<5> pushout_table_cnt) {
        pushout_key_table.read(hdr.entry[9].key, (bit<32>)(pushout_table_cnt - 1));
        pushout_value_table.read(hdr.entry[9].value, (bit<32>)(pushout_table_cnt - 1));
        
        flush_entry8(pushout_table_cnt - 1);
    }

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
        bit<KEY_SIZE> pushout_key;
        bit<VALUE_SIZE> pushout_value;
        bit<5> pushout_table_cnt;
        bit<1> is_saved;


        if ( hdr.flag.flush == 0 ) {
            num_of_entries_cnt.write(0, REGISTER_SIZE - 1);

            { // ---------- entry 0 ----------
                stored_key = 0;
                is_saved = 0;
                pushout_key=0;
                pushout_value=0;
                hash(register_idx, HashAlgorithm.crc32, HASH_BASE_1, { hdr.entry[0].key }, HASH_MAX_1);
                topk_key_table_1.read(stored_key, register_idx);
                topk_value_table_1.read(stored_value, register_idx);

                if (stored_key == 0 || stored_key == hdr.entry[0].key) { // hash hit or empty
                    // count++
                    topk_key_table_1.write(register_idx, hdr.entry[0].key);
                    stored_value = stored_value + hdr.entry[0].value;
                    topk_value_table_1.write(register_idx, stored_value);
                    is_saved = 1;
                } else { // hash collision
                    // push the low value out to next register
                    if (stored_value >= hdr.entry[0].value) { // stored >= hdr
                        pushout_key = hdr.entry[0].key;
                        pushout_value = hdr.entry[0].value;
                    } else {
                        pushout_key = stored_key;
                        pushout_value = stored_value;
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc32_custom, HASH_BASE_2, { hdr.entry[0].key }, HASH_MAX_2);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[0].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[0].key);
                        stored_value = stored_value + hdr.entry[0].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[0].value) { // stored >= hdr
                            pushout_key = hdr.entry[0].key;
                            pushout_value = hdr.entry[0].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc16, HASH_BASE_3, { hdr.entry[0].key }, HASH_MAX_3);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[0].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[0].key);
                        stored_value = stored_value + hdr.entry[0].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[0].value) { // stored >= hdr
                            pushout_key = hdr.entry[0].key;
                            pushout_value = hdr.entry[0].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    pushout_cnt.read(pushout_table_cnt, 0);
                    pushout_key_table.write((bit<32>)pushout_table_cnt, pushout_key);
                    pushout_value_table.write((bit<32>)pushout_table_cnt, pushout_value);
                    pushout_table_cnt = pushout_table_cnt + 1;
                    pushout_cnt.write(0, pushout_table_cnt);

                }
            } // -----------------------------

            { // ---------- entry 1 ----------
                stored_key = 0;
                is_saved = 0;
                hash(register_idx, HashAlgorithm.crc32, HASH_BASE_1, { hdr.entry[1].key }, HASH_MAX_1);
                topk_key_table_1.read(stored_key, register_idx);
                topk_value_table_1.read(stored_value, register_idx);

                if (stored_key == 0 || stored_key == hdr.entry[1].key) { // hash hit or empty
                    // count++
                    topk_key_table_1.write(register_idx, hdr.entry[1].key);
                    stored_value = stored_value + hdr.entry[1].value;
                    topk_value_table_1.write(register_idx, stored_value);
                    is_saved = 1;
                } else { // hash collision
                    // push the low value out to next register
                    if (stored_value >= hdr.entry[1].value) { // stored >= hdr
                        pushout_key = hdr.entry[1].key;
                        pushout_value = hdr.entry[1].value;
                    } else {
                        pushout_key = stored_key;
                        pushout_value = stored_value;
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc32_custom, HASH_BASE_2, { hdr.entry[1].key }, HASH_MAX_2);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[1].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[1].key);
                        stored_value = stored_value + hdr.entry[1].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[1].value) { // stored >= hdr
                            pushout_key = hdr.entry[1].key;
                            pushout_value = hdr.entry[1].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc16, HASH_BASE_3, { hdr.entry[1].key }, HASH_MAX_3);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[1].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[1].key);
                        stored_value = stored_value + hdr.entry[1].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[1].value) { // stored >= hdr
                            pushout_key = hdr.entry[1].key;
                            pushout_value = hdr.entry[1].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    pushout_cnt.read(pushout_table_cnt, 0);
                    pushout_key_table.write((bit<32>)pushout_table_cnt, pushout_key);
                    pushout_value_table.write((bit<32>)pushout_table_cnt, pushout_value);
                    pushout_table_cnt = pushout_table_cnt + 1;
                    pushout_cnt.write(0, pushout_table_cnt);
                }
            } // -----------------------------

            { // ---------- entry 2 ----------
                stored_key = 0;
                is_saved = 0;
                pushout_key=0;
                pushout_value=0;
                hash(register_idx, HashAlgorithm.crc32, HASH_BASE_1, { hdr.entry[2].key }, HASH_MAX_1);
                topk_key_table_1.read(stored_key, register_idx);
                topk_value_table_1.read(stored_value, register_idx);

                if (stored_key == 0 || stored_key == hdr.entry[2].key) { // hash hit or empty
                    // count++
                    topk_key_table_1.write(register_idx, hdr.entry[2].key);
                    stored_value = stored_value + hdr.entry[2].value;
                    topk_value_table_1.write(register_idx, stored_value);
                    is_saved = 1;
                } else { // hash collision
                    // push the low value out to next register
                    if (stored_value >= hdr.entry[2].value) { // stored >= hdr
                        pushout_key = hdr.entry[2].key;
                        pushout_value = hdr.entry[2].value;
                    } else {
                        pushout_key = stored_key;
                        pushout_value = stored_value;
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc32_custom, HASH_BASE_2, { hdr.entry[2].key }, HASH_MAX_2);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[2].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[2].key);
                        stored_value = stored_value + hdr.entry[2].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[2].value) { // stored >= hdr
                            pushout_key = hdr.entry[2].key;
                            pushout_value = hdr.entry[2].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc16, HASH_BASE_3, { hdr.entry[2].key }, HASH_MAX_3);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[2].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[2].key);
                        stored_value = stored_value + hdr.entry[2].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[2].value) { // stored >= hdr
                            pushout_key = hdr.entry[2].key;
                            pushout_value = hdr.entry[2].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    pushout_cnt.read(pushout_table_cnt, 0);
                    pushout_key_table.write((bit<32>)pushout_table_cnt, pushout_key);
                    pushout_value_table.write((bit<32>)pushout_table_cnt, pushout_value);
                    pushout_table_cnt = pushout_table_cnt + 1;
                    pushout_cnt.write(0, pushout_table_cnt);
                }
            } // -----------------------------

            { // ---------- entry 3 ----------
                stored_key = 0;
                is_saved = 0;
                pushout_key=0;
                pushout_value=0;
                hash(register_idx, HashAlgorithm.crc32, HASH_BASE_1, { hdr.entry[3].key }, HASH_MAX_1);
                topk_key_table_1.read(stored_key, register_idx);
                topk_value_table_1.read(stored_value, register_idx);

                if (stored_key == 0 || stored_key == hdr.entry[3].key) { // hash hit or empty
                    // count++
                    topk_key_table_1.write(register_idx, hdr.entry[3].key);
                    stored_value = stored_value + hdr.entry[3].value;
                    topk_value_table_1.write(register_idx, stored_value);
                    is_saved = 1;
                } else { // hash collision
                    // push the low value out to next register
                    if (stored_value >= hdr.entry[3].value) { // stored >= hdr
                        pushout_key = hdr.entry[3].key;
                        pushout_value = hdr.entry[3].value;
                    } else {
                        pushout_key = stored_key;
                        pushout_value = stored_value;
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc32_custom, HASH_BASE_2, { hdr.entry[3].key }, HASH_MAX_2);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[3].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[3].key);
                        stored_value = stored_value + hdr.entry[3].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[3].value) { // stored >= hdr
                            pushout_key = hdr.entry[3].key;
                            pushout_value = hdr.entry[3].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc16, HASH_BASE_3, { hdr.entry[3].key }, HASH_MAX_3);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[3].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[3].key);
                        stored_value = stored_value + hdr.entry[3].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[3].value) { // stored >= hdr
                            pushout_key = hdr.entry[3].key;
                            pushout_value = hdr.entry[3].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    pushout_cnt.read(pushout_table_cnt, 0);
                    pushout_key_table.write((bit<32>)pushout_table_cnt, pushout_key);
                    pushout_value_table.write((bit<32>)pushout_table_cnt, pushout_value);
                    pushout_table_cnt = pushout_table_cnt + 1;
                    pushout_cnt.write(0, pushout_table_cnt);
                }
            } // -----------------------------

            { // ---------- entry 4 ----------
                stored_key = 0;
                is_saved = 0;
                pushout_key=0;
                pushout_value=0;
                hash(register_idx, HashAlgorithm.crc32, HASH_BASE_1, { hdr.entry[4].key }, HASH_MAX_1);
                topk_key_table_1.read(stored_key, register_idx);
                topk_value_table_1.read(stored_value, register_idx);

                if (stored_key == 0 || stored_key == hdr.entry[4].key) { // hash hit or empty
                    // count++
                    topk_key_table_1.write(register_idx, hdr.entry[4].key);
                    stored_value = stored_value + hdr.entry[4].value;
                    topk_value_table_1.write(register_idx, stored_value);
                    is_saved = 1;
                } else { // hash collision
                    // push the low value out to next register
                    if (stored_value >= hdr.entry[4].value) { // stored >= hdr
                        pushout_key = hdr.entry[4].key;
                        pushout_value = hdr.entry[4].value;
                    } else {
                        pushout_key = stored_key;
                        pushout_value = stored_value;
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc32_custom, HASH_BASE_2, { hdr.entry[4].key }, HASH_MAX_2);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[4].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[4].key);
                        stored_value = stored_value + hdr.entry[4].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[4].value) { // stored >= hdr
                            pushout_key = hdr.entry[4].key;
                            pushout_value = hdr.entry[4].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc16, HASH_BASE_3, { hdr.entry[4].key }, HASH_MAX_3);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[4].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[4].key);
                        stored_value = stored_value + hdr.entry[4].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[4].value) { // stored >= hdr
                            pushout_key = hdr.entry[4].key;
                            pushout_value = hdr.entry[4].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    pushout_cnt.read(pushout_table_cnt, 0);
                    pushout_key_table.write((bit<32>)pushout_table_cnt, pushout_key);
                    pushout_value_table.write((bit<32>)pushout_table_cnt, pushout_value);
                    pushout_table_cnt = pushout_table_cnt + 1;
                    pushout_cnt.write(0, pushout_table_cnt);
                }
            } // -----------------------------

            { // ---------- entry 5 ----------
                stored_key = 0;
                is_saved = 0;
                pushout_key=0;
                pushout_value=0;
                hash(register_idx, HashAlgorithm.crc32, HASH_BASE_1, { hdr.entry[5].key }, HASH_MAX_1);
                topk_key_table_1.read(stored_key, register_idx);
                topk_value_table_1.read(stored_value, register_idx);

                if (stored_key == 0 || stored_key == hdr.entry[5].key) { // hash hit or empty
                    // count++
                    topk_key_table_1.write(register_idx, hdr.entry[5].key);
                    stored_value = stored_value + hdr.entry[5].value;
                    topk_value_table_1.write(register_idx, stored_value);
                    is_saved = 1;
                } else { // hash collision
                    // push the low value out to next register
                    if (stored_value >= hdr.entry[5].value) { // stored >= hdr
                        pushout_key = hdr.entry[5].key;
                        pushout_value = hdr.entry[5].value;
                    } else {
                        pushout_key = stored_key;
                        pushout_value = stored_value;
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc32_custom, HASH_BASE_2, { hdr.entry[5].key }, HASH_MAX_2);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[5].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[5].key);
                        stored_value = stored_value + hdr.entry[5].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[5].value) { // stored >= hdr
                            pushout_key = hdr.entry[5].key;
                            pushout_value = hdr.entry[5].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc16, HASH_BASE_3, { hdr.entry[5].key }, HASH_MAX_3);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[5].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[5].key);
                        stored_value = stored_value + hdr.entry[5].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[5].value) { // stored >= hdr
                            pushout_key = hdr.entry[5].key;
                            pushout_value = hdr.entry[5].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    pushout_cnt.read(pushout_table_cnt, 0);
                    pushout_key_table.write((bit<32>)pushout_table_cnt, pushout_key);
                    pushout_value_table.write((bit<32>)pushout_table_cnt, pushout_value);
                    pushout_table_cnt = pushout_table_cnt + 1;
                    pushout_cnt.write(0, pushout_table_cnt);
                }
            } // -----------------------------

            { // ---------- entry 6 ----------
                stored_key = 0;
                is_saved = 0;
                pushout_key=0;
                pushout_value=0;
                hash(register_idx, HashAlgorithm.crc32, HASH_BASE_1, { hdr.entry[6].key }, HASH_MAX_1);
                topk_key_table_1.read(stored_key, register_idx);
                topk_value_table_1.read(stored_value, register_idx);

                if (stored_key == 0 || stored_key == hdr.entry[6].key) { // hash hit or empty
                    // count++
                    topk_key_table_1.write(register_idx, hdr.entry[6].key);
                    stored_value = stored_value + hdr.entry[6].value;
                    topk_value_table_1.write(register_idx, stored_value);
                    is_saved = 1;
                } else { // hash collision
                    // push the low value out to next register
                    if (stored_value >= hdr.entry[6].value) { // stored >= hdr
                        pushout_key = hdr.entry[6].key;
                        pushout_value = hdr.entry[6].value;
                    } else {
                        pushout_key = stored_key;
                        pushout_value = stored_value;
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc32_custom, HASH_BASE_2, { hdr.entry[6].key }, HASH_MAX_2);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[6].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[6].key);
                        stored_value = stored_value + hdr.entry[6].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[6].value) { // stored >= hdr
                            pushout_key = hdr.entry[6].key;
                            pushout_value = hdr.entry[6].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc16, HASH_BASE_3, { hdr.entry[6].key }, HASH_MAX_3);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[6].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[6].key);
                        stored_value = stored_value + hdr.entry[6].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[6].value) { // stored >= hdr
                            pushout_key = hdr.entry[6].key;
                            pushout_value = hdr.entry[6].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    pushout_cnt.read(pushout_table_cnt, 0);
                    pushout_key_table.write((bit<32>)pushout_table_cnt, pushout_key);
                    pushout_value_table.write((bit<32>)pushout_table_cnt, pushout_value);
                    pushout_table_cnt = pushout_table_cnt + 1;
                    pushout_cnt.write(0, pushout_table_cnt);
                }
            } // -----------------------------

            { // ---------- entry 7 ----------
                stored_key = 0;
                is_saved = 0;
                pushout_key=0;
                pushout_value=0;
                hash(register_idx, HashAlgorithm.crc32, HASH_BASE_1, { hdr.entry[7].key }, HASH_MAX_1);
                topk_key_table_1.read(stored_key, register_idx);
                topk_value_table_1.read(stored_value, register_idx);

                if (stored_key == 0 || stored_key == hdr.entry[7].key) { // hash hit or empty
                    // count++
                    topk_key_table_1.write(register_idx, hdr.entry[7].key);
                    stored_value = stored_value + hdr.entry[7].value;
                    topk_value_table_1.write(register_idx, stored_value);
                    is_saved = 1;
                } else { // hash collision
                    // push the low value out to next register
                    if (stored_value >= hdr.entry[7].value) { // stored >= hdr
                        pushout_key = hdr.entry[7].key;
                        pushout_value = hdr.entry[7].value;
                    } else {
                        pushout_key = stored_key;
                        pushout_value = stored_value;
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc32_custom, HASH_BASE_2, { hdr.entry[7].key }, HASH_MAX_2);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[7].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[7].key);
                        stored_value = stored_value + hdr.entry[7].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[7].value) { // stored >= hdr
                            pushout_key = hdr.entry[7].key;
                            pushout_value = hdr.entry[7].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc16, HASH_BASE_3, { hdr.entry[7].key }, HASH_MAX_3);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[7].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[7].key);
                        stored_value = stored_value + hdr.entry[7].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[7].value) { // stored >= hdr
                            pushout_key = hdr.entry[7].key;
                            pushout_value = hdr.entry[7].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    pushout_cnt.read(pushout_table_cnt, 0);
                    pushout_key_table.write((bit<32>)pushout_table_cnt, pushout_key);
                    pushout_value_table.write((bit<32>)pushout_table_cnt, pushout_value);
                    pushout_table_cnt = pushout_table_cnt + 1;
                    pushout_cnt.write(0, pushout_table_cnt);
                }
            } // -----------------------------

            { // ---------- entry 8 ----------
                stored_key = 0;
                is_saved = 0;
                pushout_key=0;
                pushout_value=0;
                hash(register_idx, HashAlgorithm.crc32, HASH_BASE_1, { hdr.entry[8].key }, HASH_MAX_1);
                topk_key_table_1.read(stored_key, register_idx);
                topk_value_table_1.read(stored_value, register_idx);

                if (stored_key == 0 || stored_key == hdr.entry[8].key) { // hash hit or empty
                    // count++
                    topk_key_table_1.write(register_idx, hdr.entry[8].key);
                    stored_value = stored_value + hdr.entry[8].value;
                    topk_value_table_1.write(register_idx, stored_value);
                    is_saved = 1;
                } else { // hash collision
                    // push the low value out to next register
                    if (stored_value >= hdr.entry[8].value) { // stored >= hdr
                        pushout_key = hdr.entry[8].key;
                        pushout_value = hdr.entry[8].value;
                    } else {
                        pushout_key = stored_key;
                        pushout_value = stored_value;
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc32_custom, HASH_BASE_2, { hdr.entry[8].key }, HASH_MAX_2);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[8].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[8].key);
                        stored_value = stored_value + hdr.entry[8].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[8].value) { // stored >= hdr
                            pushout_key = hdr.entry[8].key;
                            pushout_value = hdr.entry[8].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc16, HASH_BASE_3, { hdr.entry[8].key }, HASH_MAX_3);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[8].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[8].key);
                        stored_value = stored_value + hdr.entry[8].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[8].value) { // stored >= hdr
                            pushout_key = hdr.entry[8].key;
                            pushout_value = hdr.entry[8].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    pushout_cnt.read(pushout_table_cnt, 0);
                    pushout_key_table.write((bit<32>)pushout_table_cnt, pushout_key);
                    pushout_value_table.write((bit<32>)pushout_table_cnt, pushout_value);
                    pushout_table_cnt = pushout_table_cnt + 1;
                    pushout_cnt.write(0, pushout_table_cnt);
                }
            } // -----------------------------

            { // ---------- entry 9 ----------
                stored_key = 0;
                is_saved = 0;
                pushout_key=0;
                pushout_value=0;
                hash(register_idx, HashAlgorithm.crc32, HASH_BASE_1, { hdr.entry[9].key }, HASH_MAX_1);
                topk_key_table_1.read(stored_key, register_idx);
                topk_value_table_1.read(stored_value, register_idx);

                if (stored_key == 0 || stored_key == hdr.entry[9].key) { // hash hit or empty
                    // count++
                    topk_key_table_1.write(register_idx, hdr.entry[9].key);
                    stored_value = stored_value + hdr.entry[9].value;
                    topk_value_table_1.write(register_idx, stored_value);
                    is_saved = 1;
                } else { // hash collision
                    // push the low value out to next register
                    if (stored_value >= hdr.entry[9].value) { // stored >= hdr
                        pushout_key = hdr.entry[9].key;
                        pushout_value = hdr.entry[9].value;
                    } else {
                        pushout_key = stored_key;
                        pushout_value = stored_value;
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc32_custom, HASH_BASE_2, { hdr.entry[9].key }, HASH_MAX_2);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[9].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[9].key);
                        stored_value = stored_value + hdr.entry[9].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[9].value) { // stored >= hdr
                            pushout_key = hdr.entry[9].key;
                            pushout_value = hdr.entry[9].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    hash(register_idx, HashAlgorithm.crc16, HASH_BASE_3, { hdr.entry[9].key }, HASH_MAX_3);
                    topk_key_table_1.read(stored_key, register_idx);
                    topk_value_table_1.read(stored_value, register_idx);

                    if (stored_key == 0 || stored_key == hdr.entry[9].key) { // hash hit or empty
                        // count++
                        topk_key_table_1.write(register_idx, hdr.entry[9].key);
                        stored_value = stored_value + hdr.entry[9].value;
                        topk_value_table_1.write(register_idx, stored_value);
                        is_saved = 1;
                    } else { // hash collision
                        // push the low value out to next register
                        if (stored_value >= hdr.entry[9].value) { // stored >= hdr
                            pushout_key = hdr.entry[9].key;
                            pushout_value = hdr.entry[9].value;
                        } else {
                            pushout_key = stored_key;
                            pushout_value = stored_value;
                        }
                    }
                }

                if (is_saved == 0) {
                    pushout_cnt.read(pushout_table_cnt, 0);
                    pushout_key_table.write((bit<32>)pushout_table_cnt, pushout_key);
                    pushout_value_table.write((bit<32>)pushout_table_cnt, pushout_value);
                    pushout_table_cnt = pushout_table_cnt + 1;
                    pushout_cnt.write(0, pushout_table_cnt);
                }
            } // -----------------------------

            pushout_cnt.read(meta.num_of_pushout_entries, 0);
            if (meta.num_of_pushout_entries < NUM_OF_ENTRIES) {
                drop();
            } else { // flush entries ... LIFO
           	pushout_key_table.read(hdr.entry[0].key, (bit<32>)(meta.num_of_pushout_entries - 1));
            pushout_value_table.read(hdr.entry[0].value, (bit<32>)(meta.num_of_pushout_entries - 1));
           	pushout_key_table.read(hdr.entry[1].key, (bit<32>)(meta.num_of_pushout_entries - 2));
   	        pushout_value_table.read(hdr.entry[1].value, (bit<32>)(meta.num_of_pushout_entries - 2));
  	        pushout_key_table.read(hdr.entry[2].key, (bit<32>)(meta.num_of_pushout_entries - 3));
   	        pushout_value_table.read(hdr.entry[2].value, (bit<32>)(meta.num_of_pushout_entries - 3));
            pushout_key_table.read(hdr.entry[3].key, (bit<32>)(meta.num_of_pushout_entries - 4));
            pushout_value_table.read(hdr.entry[3].value, (bit<32>)(meta.num_of_pushout_entries - 4));
            pushout_key_table.read(hdr.entry[4].key, (bit<32>)(meta.num_of_pushout_entries - 5));
            pushout_value_table.read(hdr.entry[4].value, (bit<32>)(meta.num_of_pushout_entries - 5));
            pushout_key_table.read(hdr.entry[5].key, (bit<32>)(meta.num_of_pushout_entries - 6));
            pushout_value_table.read(hdr.entry[5].value, (bit<32>)(meta.num_of_pushout_entries - 6));
            pushout_key_table.read(hdr.entry[6].key, (bit<32>)(meta.num_of_pushout_entries - 7));
            pushout_value_table.read(hdr.entry[6].value, (bit<32>)(meta.num_of_pushout_entries - 7));
            pushout_key_table.read(hdr.entry[7].key, (bit<32>)(meta.num_of_pushout_entries - 8));
            pushout_value_table.read(hdr.entry[7].value, (bit<32>)(meta.num_of_pushout_entries - 8));
            pushout_key_table.read(hdr.entry[8].key, (bit<32>)(meta.num_of_pushout_entries - 9));
            pushout_value_table.read(hdr.entry[8].value, (bit<32>)(meta.num_of_pushout_entries - 9));
            pushout_key_table.read(hdr.entry[9].key, (bit<32>)(meta.num_of_pushout_entries - 10));
            pushout_value_table.read(hdr.entry[9].value, (bit<32>)(meta.num_of_pushout_entries - 10));

            pushout_cnt.write(0, meta.num_of_pushout_entries - NUM_OF_ENTRIES);
            }
        } else { // flush the all of entries stored in register
            num_of_entries_cnt.read(meta.number_of_entries, 0);
            if ( meta.number_of_entries > 0 ) {
                topk_key_table_1.read(hdr.entry[0].key, (bit<32>)(meta.number_of_entries - 1));
                topk_value_table_1.read(hdr.entry[0].value, (bit<32>)(meta.number_of_entries - 1));
                topk_key_table_1.read(hdr.entry[1].key, (bit<32>)(meta.number_of_entries - 2));
                topk_value_table_1.read(hdr.entry[1].value, (bit<32>)(meta.number_of_entries - 2));
                topk_key_table_1.read(hdr.entry[2].key, (bit<32>)(meta.number_of_entries - 3));
                topk_value_table_1.read(hdr.entry[2].value, (bit<32>)(meta.number_of_entries - 3));
                topk_key_table_1.read(hdr.entry[3].key, (bit<32>)(meta.number_of_entries - 4));
                topk_value_table_1.read(hdr.entry[3].value, (bit<32>)(meta.number_of_entries - 4));
                topk_key_table_1.read(hdr.entry[4].key, (bit<32>)(meta.number_of_entries - 5));
                topk_value_table_1.read(hdr.entry[4].value, (bit<32>)(meta.number_of_entries - 5));
                topk_key_table_1.read(hdr.entry[5].key, (bit<32>)(meta.number_of_entries - 6));
                topk_value_table_1.read(hdr.entry[5].value, (bit<32>)(meta.number_of_entries - 6));
                topk_key_table_1.read(hdr.entry[6].key, (bit<32>)(meta.number_of_entries - 7));
                topk_value_table_1.read(hdr.entry[6].value, (bit<32>)(meta.number_of_entries - 7));
                topk_key_table_1.read(hdr.entry[7].key, (bit<32>)(meta.number_of_entries - 8));
                topk_value_table_1.read(hdr.entry[7].value, (bit<32>)(meta.number_of_entries - 8));
                topk_key_table_1.read(hdr.entry[8].key, (bit<32>)(meta.number_of_entries - 9));
                topk_value_table_1.read(hdr.entry[8].value, (bit<32>)(meta.number_of_entries - 9));
                topk_key_table_1.read(hdr.entry[9].key, (bit<32>)(meta.number_of_entries - 10));
                topk_value_table_1.read(hdr.entry[9].value, (bit<32>)(meta.number_of_entries - 10));

                topk_key_table_1.write((bit<32>)meta.number_of_entries - 1, 0);
                topk_value_table_1.write((bit<32>)meta.number_of_entries - 1, 0);
                topk_key_table_1.write((bit<32>)meta.number_of_entries - 2, 0);
                topk_value_table_1.write((bit<32>)meta.number_of_entries - 2, 0);
                topk_key_table_1.write((bit<32>)meta.number_of_entries - 3, 0);
                topk_value_table_1.write((bit<32>)meta.number_of_entries - 3, 0);
                topk_key_table_1.write((bit<32>)meta.number_of_entries - 4, 0);
                topk_value_table_1.write((bit<32>)meta.number_of_entries - 4, 0);
                topk_key_table_1.write((bit<32>)meta.number_of_entries - 5, 0);
                topk_value_table_1.write((bit<32>)meta.number_of_entries - 5, 0);
                topk_key_table_1.write((bit<32>)meta.number_of_entries - 6, 0);
                topk_value_table_1.write((bit<32>)meta.number_of_entries - 6, 0);
                topk_key_table_1.write((bit<32>)meta.number_of_entries - 7, 0);
                topk_value_table_1.write((bit<32>)meta.number_of_entries - 7, 0);
                topk_key_table_1.write((bit<32>)meta.number_of_entries - 8, 0);
                topk_value_table_1.write((bit<32>)meta.number_of_entries - 8, 0);
                topk_key_table_1.write((bit<32>)meta.number_of_entries - 9, 0);
                topk_value_table_1.write((bit<32>)meta.number_of_entries - 9, 0);
                topk_key_table_1.write((bit<32>)meta.number_of_entries - 10, 0);
                topk_value_table_1.write((bit<32>)meta.number_of_entries - 10, 0);

                meta.number_of_entries = meta.number_of_entries - 10;
            } else {
                pushout_cnt.read(meta.num_of_pushout_entries, 0);
                pushout_cnt.write(0, 0);
                flush_pushout_table.apply();
            }
            num_of_entries_cnt.write(0, meta.number_of_entries);
        }
    }
}

control MyEgress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    apply {}
}

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
    apply {}
}

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.flag);
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
