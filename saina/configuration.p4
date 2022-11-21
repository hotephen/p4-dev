#ifndef _CONFIGURATION_
#define _CONFIGURATION_

// Register size
// 16384 is the largest power-of-two stateful 64b register size per stage in Tofino 1
// This is enough for a single 2MB message in flight when using 2 slots
#define register_size 16384
// const int register_size = 16384;

// Each slot has two registers because of the shadow copy
#define num_slots 8192

// Max number of SwitchML workers we support
#define max_num_workers 32
#define max_num_workers_log2 5 // log base 2 of max_num_workers

// Size of the forwarding table
#define forwarding_table_size 1024

// Number of destination queue pairs per-worker
#define max_num_queue_pairs_per_worker 512
#define max_num_queue_pairs_per_worker_log2 9

// Total number of destination queue pairs
#define max_num_queue_pairs 512*32
#define max_num_queue_pairs_log2  max_num_queue_pairs_per_worker_log2 + max_num_workers_log2

#define TEST_OUTPUT_PORT 16


#endif /* _CONFIGURATION_ */
