#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_NSH = 0x894f;
const bit<16> TYPE_IPV4 = 0x800;
const bit<16> TYPE_ETHER = 0x6558;
const bit<8> TYPE_TCP = 6;
const bit<8> TYPE_UDP = 17;


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
    bit<16>   Nextpro;
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
    bit<32>   srcAddr;
    bit<32>   dstAddr;
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

header udp_t {
    
    bit<16>    srcPort;
    bit<16>    dstPort;
    bit<16>    length_;
    bit<16>    checksum;
    
}
struct headers {
    ethernet_t   out_ethernet;
    nsh_t        nsh;
    ethernet_t   in_ethernet;
    ipv4_t       ipv4;
    tcp_t        tcp;
    udp_t        udp;
}

struct l3_metadata_t {
    bit<2>   lkp_ip_type;
    bit<4>   lkp_ip_version;
    bit<8>   lkp_ip_proto;
    bit<8>   lkp_dscp;
    bit<8>   lkp_ip_ttl;
    bit<16>  lkp_l4_sport ;
    bit<16>  lkp_l4_dport ;
    bit<16>  lkp_outer_l4_sport ;
    bit<16>  lkp_outer_l4_dport ;

    //bit<>vrf : VRF_BIT_WIDTH;                   /* VRF */
    bit<10> rmac_group;                       /* Rmac group, for rmac indirection */
    bit<1>  rmac_hit ;                          /* dst mac is the router's mac */
    bit<2>  urpf_mode;                         /* urpf mode for current lookup */
    bit<1>  urpf_hit;                       /* hit in urpf table */
    bit<1>  urpf_check_fail;                    /* urpf check failed */
    //bit<>urpf_bd_group : BD_BIT_WIDTH;          /* urpf bd group */
    bit<1>  fib_hit ;                           /* fib hit */
    bit<16> fib_nexthop ;                      /* next hop from fib */
    bit<2>  fib_nexthop_type ;                  /* ecmp or nexthop */
    //bit<>same_bd_check : BD_BIT_WIDTH;          /* ingress bd xor egress bd */
    bit<16> nexthop_index ;                    /* nexthop/rewrite index */
    bit<1>  routed ;                            /* is packet routed? */
    bit<1>  outer_routed ;                      /* is outer packet routed? */
    bit<8>  mtu_index ;                         /* index into mtu table */
    bit<1>  l3_copy ;                           /* copy packet to CPU */
    bit<16> l3_mtu_check;                    /* result of mtu check */

    bit<16> egress_l4_sport;
    bit<16> egress_l4_dport;
 
}

struct ipv4_metadata_t {
    bit<32>   lkp_ipv4_sa;
    bit<32>   lkp_ipv4_da;
    bit<1>    ipv4_unicast_enabled;      /* is ipv4 unicast routing enabled */
    bit<2>    ipv4_urpf_mode;            /* 0: none, 1: strict, 3: loose */
    
}
//SF1 metadata
struct pkt_id_t {
    bit<32> id;
    bit<32> next_id;
}

//SF2 metadata
struct nat_metadata_t {
    bit<2>  ingress_nat_mode;           /* 0: none, 1: inside, 2: outside */
    bit<2>  egress_nat_mode;            /* nat mode of egress_bd */
    bit<16> nat_nexthop;                /* next hop from nat */
    bit<2>  nat_nexthop_type;           /* ecmp or nexthop */
    bit<1>  nat_hit;                    /* fwd and rewrite info from nat */
    bit<14> nat_rewrite_index;          /* NAT rewrite index */
    bit<1>  update_checksum;            /* update tcp/udp checksum */
    bit<1>  update_inner_checksum;      /* update inner tcp/udp checksum */    
    bit<16> l4_len;                     /* l4 length */
}

// Total SFC metadata
struct metadata {
    // Basic
    bit<24>    metadata_spi;
    bit<8>     metadata_si;
    bit<1>     metadata_nsh;
    l3_metadata_t l3_metadata;
    ipv4_metadata_t ipv4_metadata;
    // SF1
    pkt_id_t   pkt_id;

    // SF2
    nat_metadata_t  nat_metadata;

    // SF3
    bit<14> ecmp_select;
}


register<bit<32>>(16384) set_pkt_id_reg;

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
		        inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_out_ethernet;
    }

    state parse_out_ethernet {
        packet.extract(hdr.out_ethernet);
        transition select(hdr.out_ethernet.etherType) {
            TYPE_NSH: parse_nsh;
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_nsh {
        packet.extract(hdr.nsh);
        transition select(hdr.nsh.Nextpro) {
            TYPE_ETHER: parse_in_ethernet;
            default: accept;
        }
    }

    state parse_in_ethernet {
        packet.extract(hdr.in_ethernet);
        transition select(hdr.in_ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol){
            TYPE_TCP: parse_tcp;
            TYPE_UDP: parse_udp;
        }
    }

    state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {
        packet.extract(hdr.udp);
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
    

/*************************  A C T I O N S   *****************************/

// essential actions
    action drop() {
        mark_to_drop();
    }

    action loopback() {  
        resubmit(meta);
    }

    action change_hdr_to_meta() {

	    meta.metadata_spi = hdr.nsh.spi;
	    meta.metadata_si = hdr.nsh.si;	
        meta.l3_metadata.lkp_ip_proto = hdr.ipv4.protocol;
        meta.l3_metadata.lkp_l4_sport = hdr.tcp.srcPort;
        meta.l3_metadata.lkp_l4_dport = hdr.tcp.dstPort;
        meta.ipv4_metadata.lkp_ipv4_sa = hdr.ipv4.srcAddr;
        meta.ipv4_metadata.lkp_ipv4_da = hdr.ipv4.dstAddr;
        
        } 
   action l2_forward(egressSpec_t port, macAddr_t dstAddr) {
        standard_metadata.egress_spec = port;
        hdr.out_ethernet.srcAddr = hdr.out_ethernet.dstAddr;
        hdr.out_ethernet.dstAddr = dstAddr;   
    }

    action on_miss(){

    }

    action nop(){

    }



//SF1 actions
    action read_id_from_reg() {
        // read id from register
        set_pkt_id_reg.read(meta.pkt_id.id, 0);
        // plus the register value
        meta.pkt_id.next_id = meta.pkt_id.id + 1;
        set_pkt_id_reg.write(0, meta.pkt_id.next_id);
    }
    action send_to_monitor(egressSpec_t port) {
        set_pkt_id_reg.write(0, 0);
        standard_metadata.egress_spec = port;
     	meta.metadata_si = meta.metadata_si - 1;

    }

//SF2 actions
    action set_src_nat_rewrite_index(bit<14> nat_rewrite_index) {
        meta.nat_metadata.nat_rewrite_index = nat_rewrite_index;
    }

    action set_dst_nat_nexthop_index(bit<14> nat_rewrite_index) { // nexthop_index, nexthop_type,
    // modify_field(meta.nat_metadata.nat_nexthop, nexthop_index);
    // modify_field(meta.nat_metadata.nat_nexthop_type, nexthop_type);
        meta.nat_metadata.nat_rewrite_index = nat_rewrite_index;
        meta.nat_metadata.nat_hit = 1;
    }

    action set_twice_nat_nexthop_index(bit<14> nat_rewrite_index) { // nexthop_index, nexthop_type,
    // modify_field(meta.nat_metadata.nat_nexthop, nexthop_index);
    // modify_field(meta.nat_metadata.nat_nexthop_type, nexthop_type);
        meta.nat_metadata.nat_rewrite_index = nat_rewrite_index;
        meta.nat_metadata.nat_hit = 1;  
    }

    action nat_update_l4_checksum() {
        meta.nat_metadata.update_checksum = 1;
        meta.nat_metadata.l4_len = hdr.ipv4.totalLen -20;
    }       

    action set_nat_src_rewrite(bit<32> src_ip) {
        hdr.ipv4.srcAddr = src_ip;
        nat_update_l4_checksum();
        meta.metadata_si = meta.metadata_si - 1;
    }


    action set_nat_dst_rewrite(bit<32> dst_ip) {
        hdr.ipv4.dstAddr = dst_ip;
        nat_update_l4_checksum();
        meta.metadata_si = meta.metadata_si - 1;
    }

    action set_nat_src_dst_rewrite(bit<32> src_ip, bit<32> dst_ip) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.ipv4.dstAddr = dst_ip;
        nat_update_l4_checksum();
        meta.metadata_si = meta.metadata_si - 1;
    }

    action set_nat_src_udp_rewrite(bit<32> src_ip, bit<16> src_port) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.udp.srcPort = src_port;
        nat_update_l4_checksum();
        meta.metadata_si = meta.metadata_si - 1;
    }

    action set_nat_dst_udp_rewrite(bit<32> dst_ip, bit<16>dst_port) {
        hdr.ipv4.dstAddr = dst_ip;
        hdr.udp.dstPort = dst_port;
        nat_update_l4_checksum();
        meta.metadata_si = meta.metadata_si - 1;
    }

    action set_nat_src_dst_udp_rewrite(bit<32> src_ip, bit<32> dst_ip, bit<16> src_port, bit<16> dst_port) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.ipv4.dstAddr = dst_ip;
        hdr.udp.srcPort = src_port;
        hdr.udp.dstPort = dst_port;
        nat_update_l4_checksum();
        meta.metadata_si = meta.metadata_si - 1;
    }

    action set_nat_src_tcp_rewrite(bit<32> src_ip, bit<16> src_port) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.tcp.srcPort = src_port;
        nat_update_l4_checksum();
        meta.metadata_si = meta.metadata_si - 1;
    }

    action set_nat_dst_tcp_rewrite(bit<32> dst_ip, bit<16> dst_port) {
        hdr.ipv4.dstAddr = dst_ip;
        hdr.tcp.dstPort = dst_port;
        nat_update_l4_checksum();
        meta.metadata_si = meta.metadata_si - 1;
    }

    action set_nat_src_dst_tcp_rewrite(bit<32> src_ip, bit<32> dst_ip, bit<16> src_port, bit<16> dst_port) {
        hdr.ipv4.srcAddr = src_ip;
        hdr.ipv4.dstAddr = dst_ip;
        hdr.tcp.srcPort = src_port;
        hdr.tcp.dstPort = dst_port;
        nat_update_l4_checksum();
        meta.metadata_si = meta.metadata_si - 1;
    }
//SF3 actions
    action set_ecmp_select(bit<16> ecmp_base, bit<32> ecmp_count) {
        hash(meta.ecmp_select,
	    HashAlgorithm.crc16,
	    ecmp_base,
	    { hdr.ipv4.srcAddr,
	      hdr.ipv4.dstAddr,
              hdr.ipv4.protocol,
              hdr.tcp.srcPort,
              hdr.tcp.dstPort },
	    ecmp_count);
    }

    action set_nhop(bit<48> nhop_dmac, bit<32> nhop_ipv4, bit<9> port) {
        hdr.out_ethernet.dstAddr = nhop_dmac;
        hdr.ipv4.dstAddr = nhop_ipv4;
        standard_metadata.egress_spec = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    action rewrite_mac(bit<48> smac) {
        hdr.out_ethernet.srcAddr = smac;
        meta.metadata_si = meta.metadata_si - 1;

    }
    
/****************** Ingress Tables*******************/
/****************** Ingress Tables*******************/
/****************** Ingress Tables*******************/
/****************** Ingress Tables*******************/
/****************** Ingress Tables*******************/
// precheck table
/*    
    table precheck{
        key = {
            standard_metadata.instance_type : exact;
        }
        actions = {
            change_hdr_to_meta;
            drop;
            NoAction;
        }
        default_action = NoAction();
    }
*/


// SF1 Table : Basic Monitor
    table set_pkt_id {
        key = {
            meta.metadata_spi: exact;
            meta.metadata_si: exact;
        }
        actions = {
            read_id_from_reg;
            NoAction;
        }
        default_action = NoAction();
    }

    table basic_monitor {
        key = {
            meta.pkt_id.id : exact;
            meta.metadata_spi: exact;
            meta.metadata_si: exact;
        }
        actions = {
            send_to_monitor;
            NoAction;
        }
        default_action = NoAction();
    }
// SF1' Table : Basic Monitor'
    table set_pkt_id_copy {
        key = {
            meta.metadata_spi: exact;
            meta.metadata_si: exact;
        }
        actions = {
            read_id_from_reg;
            NoAction;
        }
        default_action = NoAction();
    }

    table basic_monitor_copy {
        key = {
            meta.pkt_id.id : exact;
            meta.metadata_spi: exact;
            meta.metadata_si: exact;
        }
        actions = {
            send_to_monitor;
            NoAction;
        }
        default_action = NoAction();
    }

// SF2 Table : NAT
    table nat_twice {
        key = {
            meta.ipv4_metadata.lkp_ipv4_sa : exact;
            meta.ipv4_metadata.lkp_ipv4_da : exact;
            meta.l3_metadata.lkp_ip_proto : exact;
            meta.l3_metadata.lkp_l4_sport : exact;
            meta.l3_metadata.lkp_l4_dport : exact;
            meta.metadata_spi: exact;
            meta.metadata_si: exact;
        }
        actions = {
            on_miss;
            set_twice_nat_nexthop_index;
            NoAction;
        }
        default_action = NoAction();
        // size : IP_NAT_TABLE_SIZE;
    }

    table nat_dst {
        key = {
            //l3_metadata.vrf : exact;
            meta.ipv4_metadata.lkp_ipv4_da : exact;
            meta.l3_metadata.lkp_ip_proto : exact;
            meta.l3_metadata.lkp_l4_dport : exact;
            meta.metadata_spi: exact;
            meta.metadata_si: exact;
        }
        actions = {
            on_miss;
            set_dst_nat_nexthop_index;
            NoAction;
        }
        default_action = NoAction();
        // size : IP_NAT_TABLE_SIZE;
    }

    table nat_src {
        key = {
            //l3_metadata.vrf : exact;
            meta.ipv4_metadata.lkp_ipv4_sa : exact;
            meta.l3_metadata.lkp_ip_proto : exact;
            meta.l3_metadata.lkp_l4_sport : exact;
            meta.metadata_spi: exact;
            meta.metadata_si: exact;
        }
        actions = {
            on_miss;
            set_src_nat_rewrite_index;
            NoAction;
        }
        default_action = NoAction();
        // size : IP_NAT_TABLE_SIZE;
    }

    table nat_flow {
        key = {
            //l3_metadata.vrf : ternary;
            meta.ipv4_metadata.lkp_ipv4_sa : exact; //ternary;
            meta.ipv4_metadata.lkp_ipv4_da : exact; //ternary;
            meta.l3_metadata.lkp_ip_proto : exact; //ternary;
            meta.l3_metadata.lkp_l4_sport : exact; //ternary;
            meta.l3_metadata.lkp_l4_dport : exact; //ternary;
            meta.metadata_spi: exact;
            meta.metadata_si: exact;
        }
        actions = {
            
            set_src_nat_rewrite_index;
            set_dst_nat_nexthop_index;
            set_twice_nat_nexthop_index;
            NoAction;
        }
        default_action = NoAction();
        // size = IP_NAT_FLOW_TABLE_SIZE;
    }

    table egress_nat {
        key =  {
            meta.nat_metadata.nat_rewrite_index : exact;
            meta.metadata_spi: exact;
            meta.metadata_si: exact;
        }
        actions = {
            NoAction;
            set_nat_src_rewrite;
            set_nat_dst_rewrite;
            set_nat_src_dst_rewrite;
            set_nat_src_udp_rewrite;
            set_nat_dst_udp_rewrite;
            set_nat_src_dst_udp_rewrite;
            set_nat_src_tcp_rewrite;
            set_nat_dst_tcp_rewrite;
            set_nat_src_dst_tcp_rewrite;
        }
        default_action = NoAction();
        // size : EGRESS_NAT_TABLE_SIZE;
    }

// SF3 Table : LB
    table ecmp_group {
        key = {
            hdr.ipv4.dstAddr: lpm;
            meta.metadata_spi: exact;
            meta.metadata_si: exact;
        }
        actions = {
            drop;
            set_ecmp_select;
        }
        size = 1024;
    }
    table ecmp_nhop {
        key = {
            meta.ecmp_select: exact;
            meta.metadata_spi: exact;
            meta.metadata_si: exact;
        }
        actions = {
            drop;
            set_nhop;
        }
        size = 2;
    }
    table send_frame {
        key = {
            standard_metadata.egress_spec: exact;
            meta.metadata_spi: exact;
            meta.metadata_si: exact;
        }
        actions = {
            rewrite_mac;
            drop;
        }
        size = 256;
    }
/******************************* apply *******************************/

    apply{
        change_hdr_to_meta();
        
        //SF1
        set_pkt_id.apply(); 
	    basic_monitor.apply(); 

        //SF2
        nat_twice.apply();
        nat_dst.apply();
        nat_src.apply();
        nat_flow.apply();
        egress_nat.apply();

        //SF3 : LB
        ecmp_group.apply();
        ecmp_nhop.apply();
        send_frame.apply();
        
        //SF1' : BM
        set_pkt_id_copy.apply(); 
	    basic_monitor_copy.apply(); 

    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
		         inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    
    
    
    
    apply{}
    
    
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
        packet.emit(hdr.out_ethernet);
	    packet.emit(hdr.nsh);
        packet.emit(hdr.in_ethernet);      
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);
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