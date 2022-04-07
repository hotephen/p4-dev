#include <core.p4>
#include <v1model.p4>

#include "configuration.p4"
#include "types.p4"
#include "headers.p4"
#include "parsers.p4"
#include "arp_icmp_responder.p4"
#include "forwarder.p4"
#include "drop_simulator.p4"
#include "udp_receiver.p4"
#include "udp_sender.p4"
// #include "rdma_receiver.p4"
// #include "rdma_sender.p4"
#include "bitmap_checker.p4"
#include "workers_counter.p4"
#include "exponents.p4"
#include "processor.p4"
#include "next_step_selector.p4"

#include "process_sign.p4"
// #include "extraction.p4"
// #include "Popcount.p4"
#include "k_counter.p4"
// #include "k_update.p4"



#define HALF_NUM_PARAMETERS 400000
#define PARAMETERS 16384
#define S_THRESHOLD 450000
#define K_THRESHOLD 5

// control Ingress(
//     inout header_t hdr,
//     inout ingress_metadata_t ig_md,
//     in ingress_intrinsic_metadata_t ig_intr_md,
//     in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
//     inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
//     inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

control MyIngress(inout headers hdr,
    inout metadata meta,
    inout standard_metadata_t standard_metadata) {


    register<bit<32>>(PARAMETERS) sign;
    register<bit<32>>(PARAMETERS) sign1;
    register<bit<32>>(1) idx_counter_register;
    register<bit<32>>(1) sum_grad_sign;
    register<bit<32>>(1) k_counter;
    register<bit<32>>(1) k_register;

    // Instantiate controls

    ARPandICMPResponder() arp_icmp_responder;
    Forwarder() forwarder;

    UDPReceiver() udp_receiver;
    WorkersCounter() workers_counter;
    ReconstructWorkerBitmap() reconstruct_worker_bitmap;
    UpdateAndCheckWorkerBitmap() update_and_check_worker_bitmap;

    NextStepSelector() next_step_selector;

    Exponents() exponents;

    Processor() value00;
    Processor() value01;
    Processor() value02;
    Processor() value03;
    Processor() value04;
    Processor() value05;
    Processor() value06;
    Processor() value07;
    Processor() value08;
    Processor() value09;
    Processor() value10;
    Processor() value11;
    Processor() value12;
    Processor() value13;
    Processor() value14;
    Processor() value15;
    Processor() value16;
    Processor() value17;
    Processor() value18;
    Processor() value19;
    Processor() value20;
    Processor() value21;
    Processor() value22;
    Processor() value23;
    Processor() value24;
    Processor() value25;
    Processor() value26;
    Processor() value27;
    Processor() value28;
    Processor() value29;
    Processor() value30;
    Processor() value31;

    apply { //FIXME:


        if (meta.switchml_md.packet_type == packet_type_t.CONSUME0) {
            udp_receiver.apply(hdr, meta);
            meta.switchml_md.ingress_port = standard_metadata.ingress_port;

        } else if (meta.switchml_md.packet_type == packet_type_t.CONSUME1 ||
            meta.switchml_md.packet_type == packet_type_t.CONSUME2 ||
            meta.switchml_md.packet_type == packet_type_t.CONSUME3) {
            reconstruct_worker_bitmap.apply(meta);
        }

        // If the packet is valid, should be either forwarded or processed
        if (meta.drop_flag == 1w0) { //FIXME:
            if (meta.switchml_md.packet_type == packet_type_t.CONSUME0 ||
                meta.switchml_md.packet_type == packet_type_t.CONSUME1 ||
                meta.switchml_md.packet_type == packet_type_t.CONSUME2 ||
                meta.switchml_md.packet_type == packet_type_t.CONSUME3) {
                // For CONSUME packets, record packet reception and check if this packet is a retransmission
                update_and_check_worker_bitmap.apply(hdr, meta);
                k_register.read(meta.switchml_md.k, 0);
                workers_counter.apply(hdr, meta);
            }
            // If it's a SwitchML packet, process it
            if ((packet_type_underlying_t) ig_md.switchml_md.packet_type >=
                (packet_type_underlying_t) packet_type_t.CONSUME0) { // all consume or harvest types

                // Aggregate values
                value00.apply(hdr.d0.d00, hdr.d0.d00, meta.switchml_md);
                value01.apply(hdr.d0.d01, hdr.d0.d01, meta.switchml_md);
                value02.apply(hdr.d0.d02, hdr.d0.d02, meta.switchml_md);
                value03.apply(hdr.d0.d03, hdr.d0.d03, meta.switchml_md);
                value04.apply(hdr.d0.d04, hdr.d0.d04, meta.switchml_md);
                value05.apply(hdr.d0.d05, hdr.d0.d05, meta.switchml_md);
                value06.apply(hdr.d0.d06, hdr.d0.d06, meta.switchml_md);
                value07.apply(hdr.d0.d07, hdr.d0.d07, meta.switchml_md);
                value08.apply(hdr.d0.d08, hdr.d0.d08, meta.switchml_md);
                value09.apply(hdr.d0.d09, hdr.d0.d09, meta.switchml_md);
                value10.apply(hdr.d0.d10, hdr.d0.d10, meta.switchml_md);
                value11.apply(hdr.d0.d11, hdr.d0.d11, meta.switchml_md);
                value12.apply(hdr.d0.d12, hdr.d0.d12, meta.switchml_md);
                value13.apply(hdr.d0.d13, hdr.d0.d13, meta.switchml_md);
                value14.apply(hdr.d0.d14, hdr.d0.d14, meta.switchml_md);
                value15.apply(hdr.d0.d15, hdr.d0.d15, meta.switchml_md);
                value16.apply(hdr.d0.d16, hdr.d0.d16, meta.switchml_md);
                value17.apply(hdr.d0.d17, hdr.d0.d17, meta.switchml_md);
                value18.apply(hdr.d0.d18, hdr.d0.d18, meta.switchml_md);
                value19.apply(hdr.d0.d19, hdr.d0.d19, meta.switchml_md);
                value20.apply(hdr.d0.d20, hdr.d0.d20, meta.switchml_md);
                value21.apply(hdr.d0.d21, hdr.d0.d21, meta.switchml_md);
                value22.apply(hdr.d0.d22, hdr.d0.d22, meta.switchml_md);
                value23.apply(hdr.d0.d23, hdr.d0.d23, meta.switchml_md);
                value24.apply(hdr.d0.d24, hdr.d0.d24, meta.switchml_md);
                value25.apply(hdr.d0.d25, hdr.d0.d25, meta.switchml_md);
                value26.apply(hdr.d0.d26, hdr.d0.d26, meta.switchml_md);
                value27.apply(hdr.d0.d27, hdr.d0.d27, meta.switchml_md);
                value28.apply(hdr.d0.d28, hdr.d0.d28, meta.switchml_md);
                value29.apply(hdr.d0.d29, hdr.d0.d29, meta.switchml_md);
                value30.apply(hdr.d0.d30, hdr.d0.d30, meta.switchml_md);
                value31.apply(hdr.d0.d31, hdr.d0.d31, meta.switchml_md);

                next_step_selector.apply(hdr, meta);
            }
            else {
                
                arp_icmp_responder.apply(hdr, meta);
                forwarder.apply(hdr, meta);

            }
        }
        
        if (hdr.switchml.round_end_flag == 1){
            
            bit<32> sign_reg_idx;
            bit<32> sign_vector1;
            bit<32> sign_vector2;
            bit<32> xor_result;
            bit<32> idx_counter;

            sign_reg_idx = (bit<32>)hdr.switchml.tsi[31:5];

            if (hdr.switchml.round % 2 == 0){
                sign2.read(sign_vector2, sign_reg_idx);
                sign_vector2 = sign_vector2 << 1;
                sign_vector2 = sign_vector2 + (bit<32>)hdr.d0.d00[31:31];
                sign2.write(sign_reg_idx, sign_vector2);
                idx_counter_register.read(idx_counter, 0);
                
                if(idx_counter == 31){
                    sign1.read(sign_vector1, sign_reg_idx);
                    xor_result = sign_vector2 ^ sign_vector1;
                    sign1.write(sign_reg_idx, 0);
                    idx_counter_register.write(0, 0);
                }
                else{
                    idx_counter_register.write(0, idx_counter+1);
                }
            }
            else{ // if(hdr.switchml.round % 2 == 0) {
                sign1_read(sign_vector1 , sign_reg_idx);
                sign_vector1 = sign_vector1 << 1;
                sign_vector1 = sign_vector1 + (bit<32>)hdr.d0.d00[31:31];
                sign1.write(sign_reg_idx, sign_vector1);
                idx_counter_register.read(idx_counter, 0);
                
                if(idx_counter == 31){
                    sign2.read(sign_vector2, sign_reg_idx);
                    xor_result = sign_vector1 ^ sign_vector2;
                    sign2.write(sign_reg_idx, 0);
                    idx_counter_register.write(0, 0);
                }
                else{
                    idx_counter_register.write(0, idx_counter+1);
                }
            }
            
            temp1 = xor_result & 0x55555555;
            temp2 = (xor_result >> 1) & 0x55555555;
            popcount_result = temp1 + temp2;
            temp1 = popcount_result & 0x33333333;
            temp2 = (popcount_result >> 2) & 0x33333333;
            popcount_result = temp1 + temp2;
            temp1 = popcount_result & 0x0f0f0f0f;
            temp2 = (popcount_result >> 4) & 0x0f0f0f0f;
            popcount_result = temp1 + temp2;
            temp1 = popcount_result & 0x00ff00ff;
            temp2 = (popcount_result >> 8) & 0x00ff00ff;
            popcount_result = temp1 + temp2;
            temp1 = popcount_result & 0x0000ffff;
            temp2 = (popcount_result >> 16) & 0x0000ffff;
            popcount_result = temp1 + temp2;

            bit<32>sum;
            sum_grad_sign.read(sum, 0);
            sum = sum + popcount_result;
            if(hdr.switchml.round_end_flag){ //FIXME:
                sum_grad_sign.write(0, 0);
            }
            else{
                sum_grad_sign.write(0, sum)
            }

            bit<32> k_count
            k_counter.read(k_count, 0);
            if(sum >= S_THRESHOLD){
                k_count = k_count + 1;
                k_counter.write(0, k_count);
            }
            if(k_count >= K_THRESHOLD){
                bit<32> k;
                k_register.read(k, 0);
                k_register.write(0,k+1);
            }
        }

    }
}

control MyEgress(
    inout header_t hdr,
    inout standard_metadata_t standard_metadata,
    inout metadata_t meta){

    UDPSender() udp_sender;

    apply {
        udp_sender.apply();
}


V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
