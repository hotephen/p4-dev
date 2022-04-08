#ifndef _FORWARDER_
#define _FORWARDER_

#include "configuration.p4"
#include "types.p4"
#include "headers.p4"

control Forwarder(
    in header_t hdr,
    inout standard_metadata_t standard_metadata,
    inout metadata_t meta){

    action set_egress_port(bit<9> egress_port) {
        standard_metadata.egress_spec = egress_port;
        
        meta.switchml_md.setInvalid();
    }

    action flood(bit<16> flood_mgid) {
        standard_metadata.mcast_grp = flood_mgid;
        //We use 0x8000 + dev_port as the RID and XID for the flood group

        meta.switchml_md.setInvalid();
    }

    table forward {
        key = {
            hdr.ethernet.dst_addr : exact;
        }
        actions = {
            set_egress_port;
            flood;
        }
        size = forwarding_table_size;
    }

    apply {
        forward.apply();
    }
}

#endif /* _FORWARDER_ */
