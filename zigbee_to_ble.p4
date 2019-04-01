#include <core.p4>
#include <v1model.p4>

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

header mac_t {
    bit<16> framecontrol;
    bit<16> dstpan;
    bit<16> dst;
    bit<16> src;
    
}


header zigbee_network_t {
    bit<16> framecontrol;
    bit<16> dst;
    bit<16> src;
    bit<8>  radius;
    bit<8>  seq;
    bit<64> extended_dst;
    bit<64> extended_src;

}


header zigbee_app_t {
    bit<8>  framecontrol;
    bit<8>  dst_end;
    bit<16> cluster;
    bit<16> profile;
    bit<8>  src_endpoint;
    bit<8>  counter;

}

header zigbee_cluster_t {
    bit<8>  framecontrol;
    bit<8>  command;
}



header ble_hci_t {
    bit<8>  code;
    bit<16> acl;
    bit<16> total_length;
    
}

header ble_l2cap_t {
    bit<16> data_length;
    bit<16> cid;
    
}

header ble_att_t {
    bit<8>  opcode;
    bit<16> handle;
    bit<8>  value;
}


struct metadata {

}

struct headers {
    mac_t               mac;
    zigbee_network_t    zigbee_network;
    zigbee_app_t        zigbee_app;
    zigbee_cluster_t    zigbee_cluster;
    ble_hci_t           ble_hci;
    ble_l2cap_t         ble_l2cap;
    ble_att_t           ble_att;
}

    


/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
		        inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_mac;
    }

    state parse_mac {
        packet.extract(hdr.mac);
        transition parse_zigbee_network;
        
        }
    }

    state parse_zigbee_network {
        packet.extract(hdr.zigbee_network);
        transition parse_zigbee_app;

        }
    }

    state parse_zigbee_app {
        packet.extract(hdr.zigbee_app);
        transition parse_zigbee_cluster;
        
        }
    }

    state parse_zigbee_cluster {
        packet.extract(hdr.zigbee_cluster);
        transition accept;
    }

}

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

/*
control MyVerifyChecksum(inout headers hdr, inout metadata meta
) {
    apply {  }
}
*/

/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
		 inout metadata meta,
         inout standard_metadata_t standard_metadata) {
        
    action drop() {
        mark_to_drop();
    }

*/
    action zigbee_network_valid() {
	    hdr.zigbee_network.setInvalid();
    }
    
        hdr.zigbee_app.setInvalid();
        hdr.zigbee_cluster.setInvalid();
        
        
/*
        hdr.ble_hci.setValid();
        hdr.ble_l2cap.setValid();
        hdr.ble_att.setValid();
*/
    }

   
    }
/*
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
        default_action = NoAction();
    }
*/
    table command {
        key = {
            hdr.zigbee_cluster.command : exact;
        }
        actions = {
            convert_zig_to_ble;
            drop;
            NoAction;
        }
        default_action = NoAction();
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
        
        packet.emit(hdr.ble_hci);
        packet.emit(hdr.ble_l2cap);
        packet.emit(hdr.ble_att);
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
