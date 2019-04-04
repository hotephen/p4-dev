#include <core.p4>
#include <v1model.p4>

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/
#define MIRROR_ID 0

header zigbee_mac_t {
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
    bit<8>  dst_endpoint;
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
    zigbee_mac_t        zigbee_mac;
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
        packet.extract(hdr.zigbee_mac);
        transition parse_zigbee_network;
        
    }
    

    state parse_zigbee_network {
        packet.extract(hdr.zigbee_network);
        transition parse_zigbee_app;

        
    }

    state parse_zigbee_app {
        packet.extract(hdr.zigbee_app);
        transition parse_zigbee_cluster;
        
        
    }

    state parse_zigbee_cluster {
        packet.extract(hdr.zigbee_cluster);
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
        
        apply{}
}
         
         

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
       inout metadata meta,
         inout standard_metadata_t standard_metadata) {

    action drop() {
        mark_to_drop();
    }


    action action_zig_to_zig(bit<9> port) {
        standard_metadata.egress_spec = port;
    }


    action action1() {
       hdr.zigbee_mac.setInvalid();
        hdr.zigbee_network.setInvalid();
           
        hdr.ble_hci.setValid();
        hdr.ble_l2cap.setValid();
        hdr.ble_att.setValid();
       
    }
  
    action action2(){
        hdr.zigbee_app.setInvalid();

        hdr.ble_hci = {2, 16384, 2048};
        hdr.ble_l2cap = {1024, 1024};

    }

    action action3(bit<9> port, bit<8> data){
        hdr.zigbee_cluster.setInvalid();

        hdr.ble_att = {92, 4608, data};
        standard_metadata.egress_spec = port;

    }

    action clone_packet(){
        clone(CloneType.E2E, 0);
    }

    table table_zig_to_zig {
        key = {
            hdr.zigbee_network.framecontrol : exact;
            hdr.zigbee_network.dst : exact;
            hdr.zigbee_network.src : exact;
            hdr.zigbee_cluster.framecontrol : exact;  
            
        }

        actions = {
            action_zig_to_zig;
            drop;
            NoAction;
        }
        default_action = NoAction();
    }


    table table1 {
        key = {
            hdr.zigbee_network.framecontrol : exact;
            hdr.zigbee_network.dst : exact;
            hdr.zigbee_network.src : exact;           
            
        }

        actions = {
            action1;
            drop;
            NoAction;
        }
        default_action = NoAction();
    }

    table table2 {
        key = {
            hdr.zigbee_app.dst_endpoint : exact;
            hdr.zigbee_app.cluster : exact;
            hdr.zigbee_app.profile : exact;
            hdr.zigbee_app.src_endpoint : exact;
            
        }

        actions = {
            action2;
            drop;
            NoAction;
        }
        default_action = NoAction();
    }

    table table3 {
        key = {
            hdr.zigbee_cluster.framecontrol : exact;
            hdr.zigbee_cluster.command : exact;
        }

        actions = {
            action3;
            drop;
            NoAction;
        }
    }

    table table_recirculate{
        key = { 
            standard_metadata.instance_type : exact;
        }

        actions = {
            clone_packet;
            drop;
            NoAction;
        }
    }

    table table_zig_to_zig2 {
        key = {
            hdr.zigbee_network.framecontrol : exact;
            hdr.zigbee_network.dst : exact;
            hdr.zigbee_network.src : exact;
            hdr.zigbee_cluster.framecontrol : exact;     
            
        }

        actions = {
            action_zig_to_zig;
            drop;
            NoAction;
        }
        default_action = NoAction();
    }

   
    apply {

        if(standard_metadata.instance_type==0){    
            table_zig_to_zig.apply();
            table1.apply();
            table2.apply();
            table3.apply();
            table_recirculate.apply();
        }
        else{
            table_zig_to_zig2.apply();
        }
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
        packet.emit(hdr.zigbee_mac);
        packet.emit(hdr.zigbee_network);
        packet.emit(hdr.zigbee_app);
        packet.emit(hdr.zigbee_cluster);
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