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




    register<bit<1>>(FLOW_REGISTER_SIZE) bloom_filter_new;
    register<bit<1>>(FLOW_REGISTER_SIZE) bloom_filter_old;
    
    register<bit<32>>(10) num_active_flow;
    register<bit<32>>(1) scan_pointer_reg;


    bit<1> bf0_new; 
    bit<1> bf1_new; 
    bit<1> bf2_new;
    bit<1> bf3_new;
    bit<1> bf4_new;
    bit<1> bf5_new;


    bit<1> bf0_old; 
    bit<1> bf1_old; 
    bit<1> bf2_old;
    bit<1> bf3_old;
    bit<1> bf4_old;
    bit<1> bf5_old;

    bit<1> bf0; 
    bit<1> bf1; 
    bit<1> bf2;
    bit<1> bf3;
    bit<1> bf4;
    bit<1> bf5;

    bit<32> bf0_idx; 
    bit<32> bf1_idx; 
    bit<32> bf2_idx;
    bit<32> bf3_idx;
    bit<32> bf4_idx;
    bit<32> bf5_idx;



    apply{


    // Bloom Filter
    hash(bf0_idx, HashAlgorithm.crc32, 16w0, 
        { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort },
        16w6);
    bloom_filter_new.read(bf0_new, (bit<32>)bf0_idx);
    bloom_filter_old.read(bf0_old, (bit<32>)bf0_idx);

    hash(bf1_idx, HashAlgorithm.crc16, 16w6, 
        { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort },
        16w6);
    bloom_filter_new.read(bf1_new, (bit<32>)bf1_idx);
    bloom_filter_old.read(bf1_old, (bit<32>)bf1_idx);

    hash(bf2_idx, HashAlgorithm.csum16, 16w12, 
        { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort },
        16w6);
    bloom_filter_new.read(bf2_new, (bit<32>)bf2_idx);
    bloom_filter_old.read(bf2_old, (bit<32>)bf2_idx);

    hash(bf3_idx, HashAlgorithm.identity, 16w18, 
        { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort },
        16w6);
    bloom_filter_new.read(bf3_new, (bit<32>)bf3_idx);
    bloom_filter_old.read(bf3_old, (bit<32>)bf3_idx);

    hash(bf4_idx, HashAlgorithm.crc16_custom, 16w24, 
        { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort },
        16w6);
    bloom_filter_new.read(bf4_new, (bit<32>)bf4_idx);
    bloom_filter_old.read(bf4_old, (bit<32>)bf4_idx);

    hash(bf5_idx, HashAlgorithm.crc32_custom, 16w30, 
        { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort },
        16w6);
    bloom_filter_new.read(bf5_new, (bit<32>)bf5_idx);
    bloom_filter_old.read(bf5_old, (bit<32>)bf5_idx);

    
    


    bf0 = bf0_new | bf0_old; // OR operation
    bf1 = bf1_new | bf1_old;
    bf2 = bf2_new | bf2_old;
    bf3 = bf3_new | bf3_old;
    bf4 = bf4_new | bf4_old;
    bf5 = bf5_new | bf5_old;

    bit<32> active_flow;
    num_active_flow.read(active_flow, 0);

    if (bf0 == 1 && bf1 == 1 && bf2 == 1 && bf3 == 1 && bf4 == 1 && bf5 == 1 ){ // If element exists
    }
    else{ // If element is firstly joined

        active_flow = active_flow + 1;  // increase the number of active flows
        num_active_flow.write(0, active_flow);

        // Write 1 to corresponding buckets
        bloom_filter_new.write(bf0_idx, 1);
        bloom_filter_new.write(bf1_idx, 1);
        bloom_filter_new.write(bf2_idx, 1);
        bloom_filter_new.write(bf3_idx, 1);
        bloom_filter_new.write(bf4_idx, 1);
        bloom_filter_new.write(bf5_idx, 1);

    }

    // Read scan pointer to know the order of current time.
    bit<32> scan_pointer; // 0-> .. -> MAX_BUCKET -> 0
    scan_pointer_reg.read(scan_pointer, 0);
    
    // Read new 
    bloom_filter_new.read(bf0_new, scan_pointer  );
    bloom_filter_new.read(bf1_new, scan_pointer+1 );
    bloom_filter_new.read(bf2_new, scan_pointer+2 );
    bloom_filter_new.read(bf3_new, scan_pointer+3 );
    bloom_filter_new.read(bf4_new, scan_pointer+4 );
    bloom_filter_new.read(bf5_new, scan_pointer+5 );

    // old = new
    bloom_filter_old.write(scan_pointer, bf0_new);
    bloom_filter_old.write(scan_pointer+1, bf1_new);
    bloom_filter_old.write(scan_pointer+2, bf2_new);
    bloom_filter_old.write(scan_pointer+3, bf3_new);
    bloom_filter_old.write(scan_pointer+4, bf4_new);
    bloom_filter_old.write(scan_pointer+5, bf5_new);

    // new = 0
    bloom_filter_new.write(scan_pointer, 0);
    bloom_filter_new.write(scan_pointer+1, 0);
    bloom_filter_new.write(scan_pointer+2, 0);
    bloom_filter_new.write(scan_pointer+3, 0);
    bloom_filter_new.write(scan_pointer+4, 0);
    bloom_filter_new.write(scan_pointer+5, 0);

    scan_pointer = scan_pointer + STEP_SIZE;
    // Increase scan pointer
    if (scan_pointer == MAX_BUCKET ){ // If MAX_BUCKET -> initialize to 0
        scan_pointer = 0;
        num_active_flow.write(0, 0); // initialize num_active_flow to 0
    }
    scan_pointer_reg.write(0, scan_pointer);

    standard_metadata.egress_spec = (bit<9>)active_flow;

    // Clear 
    }
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