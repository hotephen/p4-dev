#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_NSH = 0x894f;
const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_ETHER = 0x6558;

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


header nsh_t {
    bit<2>    ver;
    bit<1>    oam;
    bit<1>    un1;
    bit<6>    ttl;
    bit<6>    len;
    bit<4>    un4;
    bit<4>    MDtype;
    bit<16>    Nextpro;
    bit<24>   spi;
    bit<8>    si;
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


struct metadata {
}

struct headers {
    nsh_t        nsh;
    ethernet_t   ethernet;
    ipv4_t       ipv4;
}


/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
		inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ether;
    }

    state parse_nsh {
        packet.extract(hdr.nsh);
        transition select(hdr.nsh.Nextpro) {
            TYPE_ETHER: parse_ether;
            default: accept;
        }
    }

    state parse_ether {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
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


    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }


    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }



    action si_decrease() {
        hdr.nsh.si = hdr.nsh.si - 1;
    }

    action loopback() {
        hdr.nsh.si = hdr.nsh.si - 1;
        standard_metadata.egress_spec = standard_metadata.ingress_port;
    }




/*
    action l2_forward(egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.nsh.sidx = hdr.nsh.sidx - 1;
    }
*/
    table sf1 {
        key = {
            hdr.nsh.spi: exact;
            hdr.nsh.si: exact;
        }
        actions = {
            si_decrease;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }


    table sf2 {
        key = {
            hdr.nsh.spi: exact;
            hdr.nsh.si: exact;
        }
        actions = {
            loopback;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = drop();
    }

    apply {
        if (hdr.ipv4.isValid() && !hdr.nsh.isValid()) {
            // Process only non-tunneled IPv4 packets
            ipv4_lpm.apply();
        }

        if (hdr.nsh.isValid()) {
            // process tunneled packets
            sf1.apply();
            sf2.apply();
        }
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
        packet.emit(hdr.nsh);
        packet.emit(hdr.ipv4);
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
