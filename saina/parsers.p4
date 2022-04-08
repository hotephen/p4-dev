#ifndef _PARSERS_
#define _PARSERS_

#include "types.p4"
#include "headers.p4"

parser MyParser(packet_in pkt,
                out header_t hdr,
		        inout metadata_t meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_consume {
        pkt.extract(hdr.d0);
        transition accept;
    }

    state parse_harvest {
        pkt.extract(hdr.d0);
        transition accept;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_ARP : parse_arp;
            ETHERTYPE_IPV4 : parse_ipv4;
            default : accept_regular;
        }
    }

    state parse_arp {
        pkt.extract(hdr.arp);
        transition select(hdr.arp.hw_type, hdr.arp.proto_type) {
            (0x0001, ETHERTYPE_IPV4) : parse_arp_ipv4;
            default: accept_regular;
        }
    }

    state parse_arp_ipv4 {
        pkt.extract(hdr.arp_ipv4);
        transition accept_regular;
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.ihl, hdr.ipv4.frag_offset, hdr.ipv4.protocol) {
            (5, 0, ip_protocol_t.ICMP) : parse_icmp;
            (5, 0, ip_protocol_t.UDP)  : parse_udp;
            default                    : accept_regular;
        }
    }

    state parse_icmp {
        pkt.extract(hdr.icmp);
        transition accept_regular;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition select(hdr.udp.dst_port) {
            UDP_PORT_SWITCHML_BASE &&& UDP_PORT_SWITCHML_MASK : parse_switchml;
            default                                           : accept_regular;
        }
    }

    state parse_switchml {
        pkt.extract(hdr.switchml);
        transition parse_values;
    }

    state parse_values {
        pkt.extract(hdr.d0);
        meta.switchml_md.setValid();
        meta.fastest.setValid();
        meta.switchml_md.packet_type = 4;
        transition accept;
    }

    state accept_regular {
        meta.switchml_md.setValid();
        meta.switchml_md.packet_type = 3;
        transition accept;
    }
}


control MyComputeChecksum(inout header_t  hdr, inout metadata_t meta) {
     apply {
    }
}




#endif /* _PARSERS_ */
