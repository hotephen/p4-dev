#include <core.p4>
#include <v1model.p4>


const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_ETHER = 0x6558;
const bit<8> TYPE_TCP = 6;
const bit<8> TYPE_UDP = 17;




/*************************************************************************
*********************** D E F I N E  ***********************************
*************************************************************************/
#define MAX_LEN 11 
#define TRUE 1
#define FALSE 0 
#define SHIM_TCP 77 //NETRE reserved IPv4 Protocol ID
#define SHIM_UDP 78 //NETRE reserved IPv4 Protocol ID
#define IPV4_PROTOCOL_TCP 6
#define IPV4_PROTOCOL_UDP 17
#define FLOW_REGISTER_SIZE 65536
#define FLOW_HASH_BASE_0 16w0
#define FLOW_HASH_MAX_0 16w16383
#define FLOW_HASH_BASE_1 16w16384
#define FLOW_HASH_MAX_1 16w32767
#define FLOW_HASH_BASE_2 16w32768
#define FLOW_HASH_MAX_2 16w49151
#define FLOW_HASH_BASE_3 16w49152
#define FLOW_HASH_MAX_3 16w65535
#define THRESHOLD 64
#define CONTROLLER_PORT 10
#define ENTRY_SIZE 65536


#define FLOW_HASH_MAX 16w3
#define MAX_BUCKET 36
#define STEP_SIZE 6
#define MAX_WINDOW 100


/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

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
    
    bit<16>    srcPort;
    bit<16>    dstPort;
    bit<16>    length_;
    bit<16>    checksum;
    
}

header tcp_t {
    bit<16>     srcPort;
    bit<16>     dstPort;
    bit<32>     seqNo;
    bit<32>     ackNo;
    bit<4>      dataOffset;
    bit<4>      res;
    bit<8>      flags;
    bit<16>     windows;
    bit<16>     checksum;
    bit<16>     urgenPtr;

}


struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    tcp_t        tcp;
    udp_t        udp;
}

struct metadata {
}



/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

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
            TYPE_TCP : parse_tcp;
            default : accept;
        }
    }

    state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }


}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta
) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
		          inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    

    action drop() {
        mark_to_drop();
    }

    register<bit<32>>(FLOW_REGISTER_SIZE) couting_bloom_filter;
    
    register<bit<32>>(10) num_active_flow;

    register<bit<32>>(1) pointer_reg;
    register<bit<32>>(MAX_WINDOW) window_reg_hash0;
    register<bit<32>>(MAX_WINDOW) window_reg_hash1;
    register<bit<32>>(MAX_WINDOW) window_reg_hash2;



    bit<32> bf0; 
    bit<32> bf1; 
    bit<32> bf2;
    bit<32> bf0_idx; 
    bit<32> bf1_idx; 
    bit<32> bf2_idx;
    bit<32> window_h0_idx;
    bit<32> window_h1_idx;
    bit<32> window_h2_idx;



    apply{


    // Bloom Filter
    hash(bf0_idx, HashAlgorithm.crc32, FLOW_HASH_BASE_0, 
        { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort },
        FLOW_HASH_MAX_0);
    couting_bloom_filter.read(bf0, (bit<32>)bf0_idx);

    hash(bf1_idx, HashAlgorithm.crc16, FLOW_HASH_BASE_1, 
        { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort },
        FLOW_HASH_MAX_1);
    couting_bloom_filter.read(bf1, (bit<32>)bf1_idx);

    hash(bf2_idx, HashAlgorithm.csum16, FLOW_HASH_BASE_2, 
        { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort },
        FLOW_HASH_MAX_2);
    couting_bloom_filter.read(bf2, (bit<32>)bf2_idx);



    bit<32> active_flow;
    num_active_flow.read(active_flow, 0);

    if (bf0 == 1 && bf1 == 1 && bf2 == 1 ){ // If element exists
    }
    else{  // If element is firstly joined

        // increase the number of active flows
        active_flow = active_flow + 1;  
        num_active_flow.write(0, active_flow);

        // Increase 1 to corresponding buckets of CBF
        couting_bloom_filter.write(bf0_idx, bf0+1);
        couting_bloom_filter.write(bf1_idx, bf1+1);
        couting_bloom_filter.write(bf2_idx, bf2+1);

    }

/* Window Register Operation*/
    // Read pointer
    bit<32> pointer; // 0-> .. -> MAX_WINDOW -> 0
    bit<32> value0;
    bit<32> value1;
    bit<32> value2;
    pointer_reg.read(pointer, 0);
    
    // Read value from current pointer (to be decrease 1 from window)
    window_reg_hash0.read(window_h0_idx, pointer);
    window_reg_hash1.read(window_h1_idx, pointer);
    window_reg_hash2.read(window_h2_idx, pointer);
    couting_bloom_filter.read(value0, window_h0_idx);
    couting_bloom_filter.read(value1, window_h1_idx);
    couting_bloom_filter.read(value2, window_h2_idx);
    value0 = value0 - 1;
    value1 = value1 - 1;
    value2 = value2 - 1;
    // Update CBF
    couting_bloom_filter.write(window_h0_idx,value0);
    couting_bloom_filter.write(window_h1_idx,value1);
    couting_bloom_filter.write(window_h2_idx,value2);


    // Update Window : Write new hash index(value) to (current pointer-1)th index
    window_reg_hash0.write(pointer-1, bf0_idx);
    window_reg_hash1.write(pointer-1, bf1_idx);
    window_reg_hash2.write(pointer-1, bf2_idx);

    // Update pointer + 1 
    pointer = pointer + 1;
    if (pointer == MAX_WINDOW){
        pointer = 0; // Initialize to 0
    }    
    pointer_reg.write(0, pointer+1);


/* Active Flow Operation */
    // If entry is deleted from CBF -> decrase num_active_flow
    if (value0 == 0 || value1 == 0 || value2 == 0)
        active_flow = active_flow - 1;
        num_active_flow.write(0, active_flow);


    // For fast test
    standard_metadata.egress_spec = (bit<9>)active_flow;


    } // apply
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
		         inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {
       
    }

}



/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {

    }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);      
        packet.emit(hdr.ipv4);
        packet.emit(hdr.udp);
        packet.emit(hdr.tcp);
    }
}


/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;