/*
Author: Amedeo Sapio
amedeo.sapio@gmail.com
*/

/*
TOTAL_MEM=2*NUMBER_OF_TREES*NUMBER_OF_CELLS*(KEY_SIZE+VALUE_SIZE) + NUMBER_OF_CELLS * LOG(NUMBER_OF_CELLS)
*/
#define NUMBER_OF_TREES 12
#define NUMBER_OF_CELLS 1500 //16384
#define REGISTER_SIZE 36000 // 196608 /* NUMBER_OF_TREES*NUMBER_OF_CELLS */

register remaining_children {
    width: 32;
    instance_count : NUMBER_OF_TREES;
}

register keys {
    width : 128; /* 16 bytes */
    instance_count : REGISTER_SIZE;
}

register values {
    width : 32;
    instance_count : REGISTER_SIZE;
}

register valid_entries_stack {
    width : 18; /* log(REGISTER_SIZE) */
    instance_count : REGISTER_SIZE;
}

/* Index of first empty */
register valid_entries_index {
    width : 18; /* log(REGISTER_SIZE) */
    instance_count : NUMBER_OF_TREES;
}

/* Bitmap */
register bitmap {
    width : 1;
    instance_count : REGISTER_SIZE;
}

register pushout_keys {
    width : 128;
    instance_count : 20;
}

register pushout_values {
    width : 128;
    instance_count : 20;
}

register pushout_count {
    width : 8;
    instance_count : 1;
}

register temp_register {
    width : 8;
    instance_count : 1;
}