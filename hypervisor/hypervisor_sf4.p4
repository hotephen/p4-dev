#include <core.p4>
#include <v1model.p4>

/* 
1:L2
2:L3
3:FW
4:ARP proxy 
*/

// https://github.com/MNCHr/HyperV/blob/hr/src/HyperV_hr_p4_16/demo_191104/%EC%BA%A1%EC%B3%90)HyperV_demo_bmv2.p4 




#define MAX_LEN 2
#define CPU_PORT    255
#define DROP_PORT   511

#define CONST_STAGE_1				1
#define	CONST_STAGE_2				2
#define	CONST_STAGE_3				3
#define	CONST_STAGE_4				4

#define BIT_MASK_HEADER       4
#define BIT_MASK_USER_META    2
#define BIT_MASK_STD_META     1

#define USER_META     		meta.user_metadata.meta
#define ACTION_BITMAP 	    meta.vdp_metadata.action_chain_bitmap

#define PROG_ID	  meta.vdp_metadata.inst_id

//bit mask for each field of each header 
#define def_mask_112_dstAddr  112w0xFFFFFFFFFFFF0000000000000000
#define def_mask_112_srcAddr  112w0x000000000000FFFFFFFFFFFF0000
#define def_mask_112_bothAddr 112w0xFFFFFFFFFFFFFFFFFFFFFFFF0000
/// for ip header
#define def_mask_160_srcAddr 160w0x000000000000000000000000FFFFFFFF00000000
#define def_mask_160_dstAddr 160w0x00000000000000000000000000000000FFFFFFFF
/// for tcp header
#define def_mask_161_srcPort 160w0xFFFF000000000000000000000000000000000000
#define def_mask_161_dstPort 160w0x0000FFFF00000000000000000000000000000000
/// for arp header
#define def_mask_224_opcode  224w0x000000000000FFFF0000000000000000000000000000000000000000

#define def_mask_224_srcMAC  224w0x0000000000000000FFFFFFFFFFFF0000000000000000000000000000
#define def_mask_224_dstMAC  224w0x000000000000000000000000000000000000FFFFFFFFFFFF00000000
#define def_mask_224_bothMAC 224w0x0000000000000000FFFFFFFFFFFF00000000FFFFFFFFFFFF00000000

#define def_mask_224_srcIP   224w0x0000000000000000000000000000FFFFFFFF00000000000000000000
#define def_mask_224_dstIP   224w0x000000000000000000000000000000000000000000000000FFFFFFFF
#define def_mask_224_bothIP  224w0x0000000000000000000000000000FFFFFFFF000000000000FFFFFFFF

//bit mask for primitive action
#define BIT_MASK_DO_FORWARD 1 // 1st
#define BIT_MASK_MOD_112_DSTADDR 1<<1
#define BIT_MASK_MOD_112_SRCADDR 1<<2
#define BIT_MASK_MOD_160_DSTADDR 1<<3 //unused
#define BIT_MASK_MOD_160_SRCADDR 1<<4 //unused
#define BIT_MASK_MOD_161_DSTADDR 1<<5 //unused
#define BIT_MASK_MOD_161_SRCADDR 1<<6 //unused
#define BIT_MASK_MOD_224_OPCODE_n_RESPONSE 1<<7 // arp
#define BIT_MASK_EXTRACT_n_SHIFT_112_SRCADDR 1<<8 //arp //Extract from src & Shift to dst
#define BIT_MASK_MOD_112_BOTHADDR 1<<9 //arp 
#define BIT_MASK_EXTRACT_n_SHIFT_224_SRCMAC 1<<10 //arp 
#define BIT_MASK_MOD_224_BOTHMAC 1<<11 //arp 
#define BIT_MASK_EXTRACT_n_SHIFT_224_SRCIP 1<<12 //arp 
#define BIT_MASK_MOD_224_BOTHIP 1<<13 //arp 
#define BIT_MASK_DROP 1<<31

/* Header */
header description_hdr_t {
    bit<8> flag;
    bit<8> len;
    bit<16> vdp_id;
}

//L2 format
header hdr_112_t {
    bit<112> buffer;
}

//L3/L4 format
header hdr_160_t {
    bit<160> buffer;
}

//L3 arp
header hdr_224_t {
    bit<224> buffer;
}

//L4
header hdr_64_t {
    bit<64> buf;
}

/* Metadata */
struct vdp_metadata_t {
    bit<8> inst_id; //program id
    bit<8> stage_id; //indicate where programs are installed
    bit<3> match_chain_bitmap; //3 options/ 100:header, 010:user md, 001: std md
    bit<48> match_chain_result; //temp to make chain for action_chain_id
    bit<32> action_chain_bitmap; //call defined actions, next stage =0
    bit<48> action_chain_id; //save match_chain_result
    bit<4>  table_chain_bitmap; //bitmap enabling tables for each header. 4options. 0001:112, 0010:160_1, 0100:160_2, 1000:224
    bit<4> header_chain_bitmap;
}

struct user_metadata_t {
    bit<256> meta;

}

struct temp_metadata_t {
    bit<112> temp_112;
    bit<112> temp_extract_112;
    bit<160> temp_160;
    bit<160> temp_extract_160;
    bit<160> temp_161;
    bit<160> temp_extract_161;
    bit<224> temp_224;
    bit<224> temp_extract_224;
}

struct metadata {
    vdp_metadata_t vdp_metadata;
    user_metadata_t user_metadata;
    temp_metadata_t temp_metadata;
}

struct headers {
    description_hdr_t  desc_hdr;
    hdr_112_t          hdr_112;
    hdr_160_t[MAX_LEN] hdr_160;
    hdr_224_t          hdr_224;
    hdr_64_t           hdr_64;  	
}

/* Parser */
parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_desc;
    }

    /* state parse_112 {
        packet.extract(hdr.hdr_112);

        transition parse_desc;
    } */

    state parse_desc {
        packet.extract(hdr.desc_hdr);
        transition select(hdr.desc_hdr.vdp_id) {
            1:  parse_vPDP1; //L2
            2:  parse_vPDP2; //L3
            3:  parse_vPDP3; //FW
            4:  parse_vPDP4; //ARP_proxy
            default:  accept;
        }
    }

    state parse_vPDP1 {
        packet.extract(hdr.hdr_112);
        transition accept;
    }

    state parse_vPDP2 {
        packet.extract(hdr.hdr_112);
        packet.extract(hdr.hdr_160[0]);
        transition accept;
    }

    state parse_vPDP3 {
        packet.extract(hdr.hdr_112);
        packet.extract(hdr.hdr_160[0]);
        transition parse_vPDP3_1;        
    }

    state parse_vPDP3_1 {
        packet.extract(hdr.hdr_160[1]);
        transition accept;
    }

    state parse_vPDP4 {
        packet.extract(hdr.hdr_112);
        packet.extract(hdr.hdr_224);
        transition accept;
    }
}

/* Pipeline */
control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) { 

	action set_initial_config (bit<8> inst_id, bit<8> stage_id, bit<3> match_chain_bitmap, bit<4> header_chain_bitmap) { //need-to-check
		meta.vdp_metadata.inst_id = inst_id; //어떤 프로그램이 설치되었는지
		meta.vdp_metadata.stage_id = stage_id;
		meta.vdp_metadata.match_chain_bitmap = match_chain_bitmap; //
		meta.vdp_metadata.header_chain_bitmap = header_chain_bitmap; // related to headers       
	}

    table table_config_at_initial {
        key = {
            hdr.desc_hdr.vdp_id: exact;
        }
        actions = {
            set_initial_config();
        }
        const entries = {
            1 : set_initial_config(1,1,0b100,0b0001);  //1 = l2 forwarding
            2 : set_initial_config(2,2,0b100,0b0010);  //2 = l3 router
            3 : set_initial_config(3,3,0b101,0b0110);  //3 = TCP fw
            4 : set_initial_config(4,4,0b101,0b1000);  //4 = NAT
        }
    }



    // stage entering
    action set_action_id(bit<32> action_bitmap, bit<48> match_chain_result) { 
        meta.vdp_metadata.action_chain_bitmap = action_bitmap;
        meta.vdp_metadata.match_chain_result = match_chain_result;
    }

    table table_header_match_112_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact ;
            hdr.hdr_112.buffer : ternary ; // should include mask field
        }
        actions = {
            set_action_id(); // enabling primitive actions
        }
        //default_action = set_action_id(0x80000000, 0x8000000000);
        /* const entries = {
            (1, 112w0x0000000000020000000000000000 &&& 112w0xFFFFFFFFFFFF0000000000000000) : set_action_id(0x00000001);
            
        } */
    }

    table table_header_match_160_stage2 {
        key = {
            meta.vdp_metadata.inst_id : exact ;
            hdr.hdr_160[0].buffer : ternary ; // should include mask field
        }
        actions = {
            set_action_id(); // enabling primitive actions
        }
        //default_action = set_action_id(0x80000000, 0x8000000000);
        /* const entries = { 
            (2, 160w0x000000000000000000000000000000000A000201 &&& 160w0x00000000000000000000000000000000FFFFFF00) : set_action_id(0x00000111);
        } */
    }

    table table_header_match_160_stage3 {
        key = {
            meta.vdp_metadata.inst_id : exact ;
            hdr.hdr_160[0].buffer : ternary ; // should include mask field
        }
        actions = {
            set_action_id(); // enabling primitive actions
        }
        //default_action = set_action_id(0x80000000, 0x8000000000);
        /* const entries = {
            (3, 160w0x0000000000000000000000000A00010000000000 &&& 160w0x000000000000000000000000FFFFFF0000000000) : set_action_id(0x00000001);
            (3, 160w0x0000000000000000000000000A00020000000000 &&& 160w0x000000000000000000000000FFFFFF0000000000) : set_action_id(0x80000000, 0x8000000000);
            // srcIP : 10.0.1.0/24 :Pass
            // srcIP : 10.0.2.0/24 :drop
        }*/
    }
    table table_header_match_161_stage3 { //161 : tcp
        key = {
            meta.vdp_metadata.inst_id : exact ;
            hdr.hdr_160[1].buffer : ternary ; // should include mask field
        }
        actions = {
            set_action_id(); // enabling primitive actions
        }
        
        /* const entries = {
            (3, 160w0x0000005000000000000000000000000000000000 &&& 160w0x0000FFFF00000000000000000000000000000000) : set_action_id(0x00000001);
            (3, 160w0x0000001600000000000000000000000000000000 &&& 160w0x0000FFFF00000000000000000000000000000000) : set_action_id(0x80000000, 0x8000000000);
            // dstPort : 80 : Pass 
            // dstPort : 22 : drop
            
        }*/
    }

    table table_header_match_224_stage4 { 
        key = {
            meta.vdp_metadata.inst_id : exact ;
            hdr.hdr_224.buffer : ternary ; // should include mask field
        }
        actions = {
            set_action_id(); // enabling primitive actions
        }
        //default_action = set_action_id(0x80000000, 0x8000000000);
        /* const entries = { 
        //#define def_mask_224_opcode  224w0x000000000000FFFF0000000000000000000000000000000000000000
        // set_action_id = 48w0b(0001 1111 1000 0001) = 48w0x1F81
            (4, 224w0x00000000000000010000000000000000000000000000000000000000 &&& 224w0x000000000000FFFF0000000000000000000000000000000000000000) : set_action_id(0x00001F81);
        } */
        // opcode==1 이면, 
    }
   
/////primitive actions + tables + entries /////
	action action_forward(bit<9> port) { // 1st primitive
		standard_metadata.egress_spec = port;
	}
    table table_action_forward_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact;
            meta.vdp_metadata.match_chain_result : exact;
        }
        actions = {
            action_forward();
        }
        /* const entries = {
            1 : action_forward(1); //daechung
        } */
    }
    table table_action_forward_stage2 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_forward();
        }
        /* const entries = {
            2 : action_forward(2); //
        } */
    }
    table table_action_forward_stage3 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_forward();
        }
        /* const entries = {
            3 : action_forward(3); //
        } */
    }
    table table_action_forward_stage4 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_forward();
        }
        /* const entries = {
            4 : action_forward(4); //
        } */
    }
// 2nd primitive , error-prone?
    action action_mod_112_dstAddr(bit<112> value_112_dstAddr) { 
        hdr.hdr_112.buffer = (hdr.hdr_112.buffer&(~def_mask_112_dstAddr))
                             |(value_112_dstAddr&def_mask_112_dstAddr);
    }

/*     action action_modify_Ethernet(bit<112> Ethernet_dstAddr) {
        hdr.hdr_Ethernet.all = (hdr.hdr_Ethernet.all&(~mask_Ethernet_dstAddr))|
                              (Ethernet_dstAddr&mask_Ethernet_dstAddr);
    } */

    table table_action_mod_112_dstAddr_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact;
            meta.vdp_metadata.match_chain_result : exact;
        }
        actions = {
            action_mod_112_dstAddr();
        }
        /* const entries = {
            2 : action_mod_112_dstAddr (0x0000000002000000000000000000);
        } */
    }
    table table_action_mod_112_dstAddr_stage2 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_dstAddr();
        }
        /* const entries = {
            2 : action_mod_112_dstAddr (0x0000000003000000000000000000);
        } */
    }
    table table_action_mod_112_dstAddr_stage3 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_dstAddr();
        }
        /* const entries = {
            3 : action_mod_112_dstAddr (0x0000000004000000000000000000);
        } */
    }
    table table_action_mod_112_dstAddr_stage4 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_dstAddr();
        }
        /* const entries = {
            4 : action_mod_112_dstAddr (0x0000000005000000000000000000);
        } */
    }

    action action_mod_112_srcAddr(bit<112> value_112_srcAddr) { // 3rd primitive, error-prone?
        hdr.hdr_112.buffer = (hdr.hdr_112.buffer&(~def_mask_112_srcAddr))|(value_112_srcAddr&def_mask_112_srcAddr);
    }
    table table_action_mod_112_srcAddr_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_srcAddr();
        }
        /* const entries = {
            2 : action_mod_112_srcAddr(0x0000000000000000000000020000);
        } */
    }
    table table_action_mod_112_srcAddr_stage2 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_srcAddr();
        }
        /* const entries = {
            2 : action_mod_112_srcAddr(0x0000000000000000000000030000);
        } */
    }
    table table_action_mod_112_srcAddr_stage3 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_srcAddr();
        }
        /* const entries = {
            2 : action_mod_112_srcAddr(0x0000000000000000000000010000);
        } */
    }
    table table_action_mod_112_srcAddr_stage4 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_srcAddr();
        }
        /* const entries = {
            4 : action_mod_112_srcAddr(0x0000000000000000000000040000);
        } */
    }
    
    action action_mod_224_opcode_n_response(bit<224> value_224_opcode) {
        hdr.hdr_224.buffer = (hdr.hdr_224.buffer&(~def_mask_224_opcode))|(value_224_opcode&def_mask_224_opcode);
        standard_metadata.egress_spec = standard_metadata.ingress_port;
    }
    table table_action_mod_224_opcode_n_response_stage4 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_224_opcode_n_response();
        }
        /* const entries = {
            4 : action_mod_224_opcode_n_response(2);
        } */
    }
// variable, is this possible ?
// bit<112> temp_extract_112 = 112w0x1; 
    action action_extract_n_shift_112_srcAddr() { // is this possible ?
        meta.temp_metadata.temp_extract_112 = (hdr.hdr_112.buffer & def_mask_112_srcAddr);
        meta.temp_metadata.temp_extract_112 = meta.temp_metadata.temp_extract_112 << 48;
        meta.temp_metadata.temp_112 = meta.temp_metadata.temp_extract_112;
    }
    table table_action_extract_n_shift_112_srcAddr_stage4 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_extract_n_shift_112_srcAddr();
        }
        /* const entries = {
            4 : action_extract_n_shift_112_srcAddr();
        } */
    }    //cont'//
    action action_mod_112_bothAddr (bit<112> value_112_srcAddr) { // -th primitive, error-prone?
        meta.temp_metadata.temp_112 = (meta.temp_metadata.temp_112 | value_112_srcAddr); //(pre-process) merge to md
        hdr.hdr_112.buffer = (hdr.hdr_112.buffer&(~def_mask_112_bothAddr))| meta.temp_metadata.temp_112;
    }
    table table_action_mod_112_bothAddr_stage4 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_112_bothAddr();
        }
        /* const entries = { 
            // #define def_mask_112_srcAddr  112w0x000000000000FFFFFFFFFFFF0000
            4 : action_mod_112_bothAddr(0x00000000000000000000000A0000);
        } */
    }

//const bit<224> temp_extract_224 = 224w0x0; // variable, is this possible ?
    action action_extract_n_shift_224_srcMAC() { // is this possible ?
        meta.temp_metadata.temp_extract_224 = (hdr.hdr_224.buffer & def_mask_224_srcMAC);
        meta.temp_metadata.temp_extract_224 = meta.temp_metadata.temp_extract_224 >> 80;
        meta.temp_metadata.temp_224 = meta.temp_metadata.temp_extract_224;
    }
    table table_action_extract_n_shift_224_srcMAC_stage4 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_extract_n_shift_224_srcMAC();
        }
        /* const entries = {
            4 : action_extract_n_shift_224_srcMAC();
        } */
    }    //cont'//
    action action_mod_224_bothMAC (bit<224> value_224_srcMAC) { // -th primitive, error-prone?
//        meta.temp_mdetadata.temp_224 = 0;
        meta.temp_metadata.temp_224 = (meta.temp_metadata.temp_224 | value_224_srcMAC); //(pre-process) merge to md
        hdr.hdr_224.buffer = (hdr.hdr_224.buffer&(~def_mask_224_bothMAC))| meta.temp_metadata.temp_224;
    }
    table table_action_mod_224_bothMAC_stage4 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_224_bothMAC();
        }
        /* const entries = { 
            // #define def_mask_224_bothMAC 224w0x0000000000000000FFFFFFFFFFFF00000000FFFFFFFFFFFF00000000
            4 : action_mod_224_bothMAC(0x000000000000000000000000000A0000000000000000000000000000);
        } */
    }

    action action_extract_n_shift_224_srcIP() { // is this possible ?
        meta.temp_metadata.temp_extract_224 = (hdr.hdr_224.buffer & def_mask_224_srcIP);
        meta.temp_metadata.temp_extract_224 = meta.temp_metadata.temp_extract_224 >> 80;
        meta.temp_metadata.temp_224 = meta.temp_metadata.temp_extract_224;
    }
    table table_action_extract_n_shift_224_srcIP_stage4 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_extract_n_shift_224_srcIP();
        }
        /* const entries = {
            4 : action_extract_n_shift_224_srcIP();
        } */
    }    //cont'//
    action action_mod_224_bothIP (bit<224> value_224_srcIP) { // -th primitive, error-prone?
        meta.temp_metadata.temp_224 = (meta.temp_metadata.temp_224 | value_224_srcIP); //(pre-process) merge to md
        hdr.hdr_224.buffer = (hdr.hdr_224.buffer&(~def_mask_224_bothIP))| meta.temp_metadata.temp_224;
    }
    table table_action_mod_224_bothIP_stage4 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_mod_224_bothIP();
        }
       /*  const entries = { 
            // #define def_mask_224_bothIP  224w0x0000000000000000000000000000FFFFFFFF000000000000FFFFFFFF
            4 : action_mod_224_bothIP(0x00000000000000000000000000000000000A00000000000000000000);
        } */
    }


    action action_drop() { //48th primitive
		mark_to_drop();
	}
    
    table table_action_drop_stage1 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_drop();
        }
        const entries = {
            1 : action_drop();
        }
    }
    table table_action_drop_stage2 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_drop();
        }
        const entries = {
            2 : action_drop();
        }
    }
    table table_action_drop_stage3 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_drop();
        }
        const entries = {
            3 : action_drop();
        }
    }
    table table_action_drop_stage4 {
        key = {
            meta.vdp_metadata.inst_id : exact;
        }
        actions = {
            action_drop();
        }
        const entries = {
            4 : action_drop();
        }
    }
    

/////////////////////////////////////////////////////////////////
    apply {
        if (PROG_ID ==0) {
            table_config_at_initial.apply();
        }
        if (PROG_ID !=0) {
            if(meta.vdp_metadata.stage_id == CONST_STAGE_1){
                if((meta.vdp_metadata.match_chain_bitmap & BIT_MASK_HEADER) != 0){
                    if(meta.vdp_metadata.header_chain_bitmap&1 != 0)
                        table_header_match_112_stage1.apply();
                }
				// if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_STD_META !=0 ){
				// 		table_std_meta_match_stage1.apply();
				// }
				// if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_USER_META !=0){
				// 		table_user_meta_stage1.apply();
				// }
            }
            if(ACTION_BITMAP != 0) {
                if ((ACTION_BITMAP & BIT_MASK_DO_FORWARD) != 0) {	
		            table_action_forward_stage1.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_DSTADDR) != 0) {	
		            table_action_mod_112_dstAddr_stage1.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_SRCADDR) != 0) {	
		            table_action_mod_112_srcAddr_stage1.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_DROP) != 0) {	
		            table_action_drop_stage1.apply();						
	            }
            if(ACTION_BITMAP == 0) {
                mark_to_drop();
            }
            }

            if(meta.vdp_metadata.stage_id == CONST_STAGE_2){
                if((meta.vdp_metadata.match_chain_bitmap & BIT_MASK_HEADER) != 0){
                    if(meta.vdp_metadata.header_chain_bitmap&2 != 0)
                        table_header_match_160_stage2.apply();
                    //   table_header_match_112_1_stage1.apply();
                    // if(meta.vdp_metadata.table_chain&2 != 0)
                    //   table_header_match_160_1_stage1.apply();
                    // if(meta.vdp_metadata.table_chain&4 != 0)
                    //   table_header_match_160_2_stage1.apply();
                    // if(meta.vdp_metadata.table_chain&8 != 0)
                    //   table_header_match_224_1_stage1.apply();
                }
				// if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_STD_META !=0 ){
				// 		table_std_meta_match_stage1.apply();
				// }
				// if (meta.vdp_metadata.match_chain_bitmap & BIT_MASK_USER_META !=0){
				// 		table_user_meta_stage1.apply();
				// }
            }
            if(ACTION_BITMAP != 0) {
                if ((ACTION_BITMAP & BIT_MASK_DO_FORWARD) != 0) {	
		            table_action_forward_stage2.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_DSTADDR) != 0) {	
		            table_action_mod_112_dstAddr_stage2.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_SRCADDR) != 0) {	
		            table_action_mod_112_srcAddr_stage2.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_DROP) != 0) {	
		            table_action_drop_stage2.apply();						
	            }
            if(ACTION_BITMAP == 0) {
                mark_to_drop();
            }
            }

            if(meta.vdp_metadata.stage_id == CONST_STAGE_3){
                if((meta.vdp_metadata.match_chain_bitmap & BIT_MASK_HEADER) != 0){
                    if(meta.vdp_metadata.header_chain_bitmap&2 != 0)
                        table_header_match_160_stage3.apply();
                    if((ACTION_BITMAP & BIT_MASK_DROP) == 0) { // Drop이 아니면 수행
                        if(meta.vdp_metadata.header_chain_bitmap&4 != 0){
                            table_header_match_161_stage3.apply();
                        }
                    }
                    
                }
				
            }
            if(ACTION_BITMAP != 0) {
                if ((ACTION_BITMAP & BIT_MASK_DO_FORWARD) != 0) {	
		            table_action_forward_stage3.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_DSTADDR) != 0) {	
		            table_action_mod_112_dstAddr_stage3.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_SRCADDR) != 0) {	
		            table_action_mod_112_srcAddr_stage3.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_DROP) != 0) {	
		            table_action_drop_stage3.apply();						
	            }
            if(ACTION_BITMAP == 0) {
                mark_to_drop();
            }
            }

            if(meta.vdp_metadata.stage_id == CONST_STAGE_4){
                if((meta.vdp_metadata.match_chain_bitmap & BIT_MASK_HEADER) != 0){
                    if(meta.vdp_metadata.header_chain_bitmap&8 != 0)
                        table_header_match_224_stage4.apply();
                }
				
            }
            if(ACTION_BITMAP != 0) {
                if ((ACTION_BITMAP & BIT_MASK_DO_FORWARD) != 0) {	
		            table_action_forward_stage4.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_DSTADDR) != 0) {	
		            table_action_mod_112_dstAddr_stage4.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_SRCADDR) != 0) {	
		            table_action_mod_112_srcAddr_stage4.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_224_OPCODE_n_RESPONSE) != 0) {	
		            table_action_mod_224_opcode_n_response_stage4.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_EXTRACT_n_SHIFT_112_SRCADDR) != 0) {	
		            table_action_extract_n_shift_112_srcAddr_stage4.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_112_BOTHADDR) != 0) {	
		            table_action_mod_112_bothAddr_stage4.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_EXTRACT_n_SHIFT_224_SRCMAC) != 0) {	
		            table_action_extract_n_shift_224_srcMAC_stage4.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_224_BOTHMAC) != 0) {	
		            table_action_mod_224_bothMAC_stage4.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_EXTRACT_n_SHIFT_224_SRCIP) != 0) {	
		            table_action_extract_n_shift_224_srcIP_stage4.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_MOD_224_BOTHIP) != 0) {	
		            table_action_mod_224_bothIP_stage4.apply();						
	            }
                if ((ACTION_BITMAP & BIT_MASK_DROP) != 0) {	
		            table_action_drop_stage4.apply();						
	            }
            if(ACTION_BITMAP == 0) {
                mark_to_drop();
            }
            }
        }
    }

    
}


control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply { 
        
    }
}

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
    }
}

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.desc_hdr);
        packet.emit(hdr.hdr_112);
        packet.emit(hdr.hdr_224);
        packet.emit(hdr.hdr_160[0]);
        packet.emit(hdr.hdr_160[1]);
        packet.emit(hdr.hdr_64);
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
