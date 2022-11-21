#ifndef _UDP_SENDER_
#define _UDP_SENDER_

#define UDP_LENGTH 157 // 8udp + 20SW + 128
#define IPV4_LENGTH 20 + UDP_LENGTH;

control UDPSender(
    inout header_t hdr,
    inout standard_metadata_t standard_metadata,
    inout metadata_t meta
    ) {

    action set_switch_mac_and_ip(mac_addr_t switch_mac, ipv4_addr_t switch_ip) {
        hdr.ethernet.src_addr = switch_mac;
        hdr.ipv4.src_addr = switch_ip;
        hdr.udp.src_port = meta.switchml_md.src_port;

        hdr.ethernet.ether_type = ETHERTYPE_IPV4;

        hdr.ipv4.version = 4;
        hdr.ipv4.ihl = 5;
        hdr.ipv4.diffserv = 0x00;
        hdr.ipv4.total_len = IPV4_LENGTH;
        hdr.ipv4.identification = 0x0000;
        hdr.ipv4.flags = 0b000;
        hdr.ipv4.frag_offset = 0;
        hdr.ipv4.ttl = 64;
        hdr.ipv4.protocol = ip_protocol_t.UDP;
        hdr.ipv4.src_addr = switch_ip;

        hdr.udp.length = UDP_LENGTH;

        hdr.switchml.setValid();
        hdr.switchml.msg_type = 1;
        hdr.switchml.size = meta.switchml_md.packet_size;
        hdr.switchml.job_number = meta.switchml_md.job_number;
        hdr.switchml.tsi = meta.switchml_md.tsi;

        hdr.switchml.round = meta.switchml_md.round; //FIXME:
        hdr.switchml.round_end_flag = meta.switchml_md.round_end_flag; //FIXME:
        hdr.switchml.packet_type = (bit<8>)meta.switchml_md.packet_type; //FIXME:
        

        hdr.switchml.pool_index[13:0] = meta.switchml_md.pool_index[14:1];

    }

    table switch_mac_and_ip {
        key = {
            hdr.switchml.job_number : ternary;
            }
        actions = { 
            set_switch_mac_and_ip; 
        }
        const entries = {
            _ : set_switch_mac_and_ip(0x0cc47a63ffff, 0x140A00fe);
        }
        // size = 1;
    }

    action set_dst_addr(
        mac_addr_t eth_dst_addr,
        ipv4_addr_t ip_dst_addr) {

        hdr.ethernet.dst_addr = eth_dst_addr;
        hdr.ipv4.dst_addr = ip_dst_addr;

        hdr.udp.dst_port = meta.switchml_md.dst_port;
        hdr.udp.checksum = 0;
        hdr.switchml.pool_index[15:15] = meta.switchml_md.pool_index[0:0];
    }

    table dst_addr {
        key = {
            meta.switchml_md.worker_id : exact;
        }
        actions = {
            set_dst_addr;
        }
        const entries = {
            0 : set_dst_addr( 0x000000000000, 0x140A0001);
            1 : set_dst_addr( 0x000000000000, 0x140A0002);
            2 : set_dst_addr( 0x000000000000, 0x140A0003);
            3 : set_dst_addr( 0x000000000000, 0x140A0004);
            4 : set_dst_addr( 0x000000000000, 0x140A0005);
        }
        size = max_num_workers;
    }

    apply {
        hdr.ethernet.setValid();
        hdr.ipv4.setValid();
        hdr.udp.setValid();
        hdr.switchml.setValid();
        hdr.switchml.pool_index = 16w0;

        switch_mac_and_ip.apply();
        dst_addr.apply();

        // Add payload size
        if (meta.switchml_md.packet_size == 1) {
            hdr.ipv4.total_len = hdr.ipv4.total_len + 256;
            hdr.udp.length = hdr.udp.length + 256;
        }
        else if (meta.switchml_md.packet_size == 3) {
            hdr.ipv4.total_len = hdr.ipv4.total_len + 1024;
            hdr.udp.length = hdr.udp.length + 1024;
        }
    }
}

#endif /* _UDP_SENDER_ */
