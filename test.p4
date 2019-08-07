#define EXTEND_ACTION_MODIFY_STADARD_METADATA 37
#define BIT_MASK_MOD_STD_META (1<<EXTEND_ACTION_MODIFY_STADARD_METADATA)
#define CONST_NUM_OF_STAGE 0x1f
#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>

header_type description_hdr_t {
    fields {
        flag : 8;
        len : 8;
        vdp_id : 16;
    }
}


header_type hdr1_t {
    fields {
        buf : 112;
    }
}
header_type hdr2_t {
    fields {
        buf : 160;
    }
}

header description_hdr_t desc_hdr;
header hdr1_t hdr1;
header hdr2_t hdr2;

header_type vdp_metadata_t {
    fields {
        inst_id    : 8;
        stage_id   : 8;
        action_chain_id     : 48; 
        action_chain_bitmap : 48;
        match_chain_result  : 48;
        match_chain_bitmap  : 3;
        table_chain : 3;
    }
}

metadata vdp_metadata_t vdp_metadata;


parser start {
    return parse_desc;
}

parser parse_desc {
    extract(desc_hdr);
    return select(desc_hdr.vdp_id) {
        1 : parse_hdr1;
        2 : parse_hdr2;
        default: ingress;
    }
}


parser parse_hdr1 {
    extract(hdr1);
    return ingress;
}

parser parse_hdr2 {
    extract(hdr2);
    return ingress;
}

action set_initial_config(progid, stageid, match_bitmap, table_chain) {
    modify_field(vdp_metadata.inst_id , progid);
    modify_field(vdp_metadata.stage_id , stageid);
    modify_field(vdp_metadata.match_chain_bitmap , match_bitmap);
    modify_field(vdp_metadata.table_chain , table_chain);        
}

table table_config_at_initial {
    reads {
        desc_hdr.vdp_id: exact;
        vdp_metadata.inst_id: exact;
        vdp_metadata.stage_id: exact;
    }
    actions {
        set_initial_config;
    }
}



action set_action_id(action_bitmap, match_bitmap, next_stage, next_prog, match_result) {
    modify_field(vdp_metadata.action_chain_bitmap , action_bitmap);
    modify_field(vdp_metadata.match_chain_bitmap , match_bitmap);
    modify_field(vdp_metadata.stage_id , next_stage);
    modify_field(vdp_metadata.inst_id , next_prog);
    modify_field(vdp_metadata.action_chain_id , match_result);
    modify_field(vdp_metadata.match_chain_result , 0);
}
    
    

    action end(next_prog) {
        set_action_id(0,0,0,next_prog,0);
    }
    
    table table_header_match_stage1_1 {
        reads {
            vdp_metadata.inst_id: exact;
            vdp_metadata.stage_id: exact;
            hdr1.buf: ternary; 
        }
        actions {
            set_action_id;
            end;
        }
    }
     
    table table_header_match_stage1_2 {
        reads {
            vdp_metadata.inst_id: exact;
            vdp_metadata.stage_id: exact;
            hdr2.buf: ternary; 
        }
        actions {
            set_action_id;
            end;
        }
    }
    
    table table_std_meta_match_stage1 {
        reads {
            vdp_metadata.inst_id: exact;
            vdp_metadata.stage_id: exact;
            standard_metadata.ingress_port: ternary;
            standard_metadata.egress_spec: ternary;
            standard_metadata.instance_type: ternary;       
        }
        actions {
            set_action_id;
        }
    }
    
    table table_header_match_stage2 {
        reads {
            vdp_metadata.inst_id: exact;
            vdp_metadata.stage_id: exact;
            hdr1.buf: ternary; 
        }
        actions {
            set_action_id;
            end;
        }
    }
    
    table table_std_meta_match_stage2 {
        reads {
            vdp_metadata.inst_id: exact;
            vdp_metadata.stage_id: exact;
            standard_metadata.ingress_port: ternary;
            standard_metadata.egress_spec: ternary;
            standard_metadata.instance_type: ternary;       
        }
        actions {
            set_action_id;
        }
    }

    table table_header_match_stage3 {
        reads {
            vdp_metadata.inst_id: exact;
            vdp_metadata.stage_id: exact;
            hdr1.buf: ternary; 
        }
        actions {
            set_action_id;
            end;
        }
    }
    
    table table_std_meta_match_stage3 {
        reads {
            vdp_metadata.inst_id: exact;
            vdp_metadata.stage_id: exact;
            standard_metadata.ingress_port: ternary;
            standard_metadata.egress_spec: ternary;
            standard_metadata.instance_type: ternary;       
        }
        actions {
            set_action_id;
        }
    }

    table table_header_match_stage4 {
        reads {
            vdp_metadata.inst_id: exact;
            vdp_metadata.stage_id: exact;
            hdr1.buf: ternary; 
        }
        actions {
            set_action_id;
            end;
        }
    }
    
    table table_std_meta_match_stage4 {
        reads {
            vdp_metadata.inst_id: exact;
            vdp_metadata.stage_id: exact;
            standard_metadata.ingress_port: ternary;
            standard_metadata.egress_spec: ternary;
            standard_metadata.instance_type: ternary;       
        }
        actions {
            set_action_id;
        }
    }
    


    action do_forward(port) {
        modify_field(standard_metadata.egress_spec , port);
    }

    action do_drop() {
        drop();
    }

    table table_mod_std_meta_stage1 {
        reads {
            vdp_metadata.action_chain_id: ternary;
        }
        actions {
            do_forward;
            do_drop;
        }
    }
            
    table table_mod_std_meta_stage2 {
        reads {
            vdp_metadata.action_chain_id: ternary;
        }
        actions {
            do_forward;
            do_drop;
        }
    }

    table table_mod_std_meta_stage3 {
        reads {
            vdp_metadata.action_chain_id: ternary;
        }
        actions {
            do_forward;
            do_drop;
        }
    }

    table table_mod_std_meta_stage4 {
        reads {
            vdp_metadata.action_chain_id: ternary;
        }
        actions {
            do_forward;
            do_drop;
        }
    }



control ingress{
    apply(table_config_at_initial);
    if ((vdp_metadata.stage_id & CONST_NUM_OF_STAGE) == 1) {
        if (vdp_metadata.match_chain_bitmap&4 != 0) {
       if(vdp_metadata.table_chain&1 != 0)
                apply(table_header_match_stage1_1);
       else if(vdp_metadata.table_chain&2 != 0)
      apply(table_header_match_stage1_2);
        }
        if (vdp_metadata.match_chain_bitmap&1 != 0) {
            apply(table_std_meta_match_stage1);
        }
        
        if (vdp_metadata.action_chain_bitmap&1  != 0) {
            apply(table_mod_std_meta_stage1);
        }
    }

    if ((vdp_metadata.stage_id & CONST_NUM_OF_STAGE) == 2) {
        if (vdp_metadata.match_chain_bitmap&4 != 0) {
            apply(table_header_match_stage2);
        }
        if (vdp_metadata.match_chain_bitmap&1 != 0) {
            apply(table_std_meta_match_stage2);
        }
        if (vdp_metadata.action_chain_bitmap&1  != 0) {
                apply(table_mod_std_meta_stage2);
        }
    }

    if ((vdp_metadata.stage_id & CONST_NUM_OF_STAGE) == 3) {
        if (vdp_metadata.match_chain_bitmap&4 != 0) {
            apply(table_header_match_stage3);
        }
        if (vdp_metadata.match_chain_bitmap&1 != 0) {
            apply(table_std_meta_match_stage3);
        }
        if (vdp_metadata.action_chain_bitmap&1  != 0) {
                apply(table_mod_std_meta_stage3);
        }
     }
     if ((vdp_metadata.stage_id & CONST_NUM_OF_STAGE) == 4) {
         if (vdp_metadata.match_chain_bitmap&4 != 0) {
            apply(table_header_match_stage4);
        }
         if (vdp_metadata.match_chain_bitmap&1 != 0) {
            apply(table_std_meta_match_stage4);
        }
        if (vdp_metadata.action_chain_bitmap&1  != 0) {
                apply(table_mod_std_meta_stage4);
         }
     }

}



control egress{
}
