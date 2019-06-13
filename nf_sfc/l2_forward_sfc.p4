action l2_forward_sf(port) {
	modify_field(standard_metadata.egress_spec, port);
    modify_field(meta.metadata_si, meta.metadata_si-1);
}




table l2_forward_sf_t {
	reads {
		ethernet.dstAddr : exact;
        meta.metadata_spi : exact;
        meta.metadata_si : exact;
	}
	actions {
		on_miss; l2_forward;
	}
}

table sf_t {
    reads {
        meta.metadata_spi: exact;
        meta.metadata_si: exact;
    }
    actions {
        si_decrease;
        drop;
    }
}


control process_l2_forward {
	apply(l2_forward_t);
}