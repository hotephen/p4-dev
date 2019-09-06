#include <v1model.p4>
#include <core.p4>



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

metadata nat_metadata_t nat_metadata;



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
        transition accept;
    }

}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
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

    #ifndef NAT_DISABLE

    action set_src_nat_rewrite_index(bit<14> nat_rewrite_index) {
        nat_metadata.nat_rewrite_index = nat_rewrite_index;
    }

    action set_dst_nat_nexthop_index(bit<14>) nat_rewrite_index) {
        nat_metadata.nat_rewrite_index = nat_rewrite_index;
        nat_metadata.nat_hit = true;   
    }

    table nat_src {
        key = {
            ipv4_metadata.lkp_ipv4_sa : exact;
            l3_metadata.lkp_ip_proto : exact;
            l3_metadata.lkp_l4_sport : exact;
        }
        actions {
            on_miss;
            set_src_nat_rewrite_index;
        }
    }

    table nat_dst {
        key = {
            ipv4_metadata.lkp_ipv4_da : exact;
            l3_metadata.lkp_ip_proto : exact;
            l3_metadata.lkp_l4_sport : exact;
        }
        actions = {
            on_miss;
            set_dst_nat_nexthop_index;
    }

    table nat_twice {
        key =  {
            //l3_metadata.vrf : exact;
            ipv4_metadata.lkp_ipv4_sa : exact;
            ipv4_metadata.lkp_ipv4_da : exact;
            l3_metadata.lkp_ip_proto : exact;
            l3_metadata.lkp_l4_sport : exact;
            l3_metadata.lkp_l4_dport : exact;
        }
        actions = {
            on_miss;
            set_twice_nat_nexthop_index;
        }
        size : IP_NAT_TABLE_SIZE;
    }

    table nat_flow {
        key = {
            //l3_metadata.vrf : ternary;
            ipv4_metadata.lkp_ipv4_sa : exact; //ternary;
            ipv4_metadata.lkp_ipv4_da : exact; //ternary;
            l3_metadata.lkp_ip_proto : exact; //ternary;
            l3_metadata.lkp_l4_sport : exact; //ternary;
            l3_metadata.lkp_l4_dport : exact; //ternary;
        }
        actions = {
            nop;
            set_src_nat_rewrite_index;
            set_dst_nat_nexthop_index;
            set_twice_nat_nexthop_index;
        }
        // size : IP_NAT_FLOW_TABLE_SIZE;
    }

    #endif /* NAT_DISABLE */

    control process_ingress_nat {
    #ifndef NAT_DISABLE
        apply(nat_twice) {
            on_miss {
                apply(nat_dst) {
                    on_miss {
                        apply(nat_src) {
                            on_miss {
                                apply(nat_flow);
                            }
                        }
                    }
                }
            }
        }
    #endif /* NAT DISABLE */
    }




#ifndef NAT_DISABLE
action nat_update_l4_checksum() {
    nat_metadata.update_checksum = 1;
    nat_metadata.l4_len = ipv4.totalLen - 20;
}

action set_nat_src_rewrite(bit<32> src_ip) {
    ipv4.srcAddr = src_ip;
    nat_update_l4_checksum();
}

action set_nat_dst_rewrite(bit<32> dst_ip) {
    ipv4.dstAddr = dst_ip;
    nat_update_l4_checksum();
}

action set_nat_src_dst_rewrite(bit<32> src_ip, bit<32> dst_ip) {
    ipv4.srcAddr = src_ip;
    ipv4.dstAddr = dst_ip;
    nat_update_l4_checksum();
}

action set_nat_src_udp_rewrite(bit<32> src_ip, bit<16> src_port) {
    ipv4.srcAddr = src_ip;
    udp.srcPort = src_port;
    nat_update_l4_checksum();
}

action set_nat_dst_udp_rewrite(bit<32> dst_ip, bit<16> dst_port) {
    ipv4.dstAddr = dst_ip;
    udp.dstPort = dst_port;
    nat_update_l4_checksum();
}

action set_nat_src_dst_udp_rewrite(src_ip, dst_ip, src_port, dst_port) {
    ipv4.srcAddr = src_ip;
    ipv4.dstAddr = dst_ip;
    udp.srcPort = src_port;
    udp.dstPort = dst_port;
    nat_update_l4_checksum();
}

action set_nat_src_tcp_rewrite(bit<32> src_ip, bit<16> src_port) {
    ipv4.srcAddr =  src_ip;
    tcp.srcPort = src_port;
    nat_update_l4_checksum();
}

action set_nat_dst_tcp_rewrite(bit<32> dst_ip, bit<16> dst_port) {
    ipv4.dstAddr = dst_ip;
    tcp.dstPort = dst_port;
    nat_update_l4_checksum();
}

action set_nat_src_dst_tcp_rewrite(bit<32> src_ip, bit<32> dst_ip, bit<16> src_port, bit<16> dst_port) {
    ipv4.srcAddr =  src_ip;
    ipv4.dstAddr =  dst_ip;
    tcp.srcPort = src_port;
    tcp.dstPort = dst_port;
    nat_update_l4_checksum();
}

table egress_nat {
    key = {
        nat_metadata.nat_rewrite_index : exact;
    }
    actions {
        nop;
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
    // size : EGRESS_NAT_TABLE_SIZE;
}
#endif /* NAT_DISABLE */

control process_egress_nat {
#ifndef NAT_DISABLE
    // if ((nat_metadata.ingress_nat_mode != NAT_MODE_NONE) and
    //     (nat_metadata.ingress_nat_mode != nat_metadata.egress_nat_mode)) {
        apply(egress_nat);
    // }
#endif /* NAT_DISABLE */
}
