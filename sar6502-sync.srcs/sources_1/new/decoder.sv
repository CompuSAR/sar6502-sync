`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/20/2024 01:05:03 PM
// Design Name: 
// Module Name: decoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module decoder#(CPU_VARIANT = 0)
(
    input clock_i,
    input reset_i,
    input irq_i,
    input nmi_i,
    output memory_lock_o,
    output sync_o,
    output vector_pull_o,

    output ctl::ControlSignals control_signals_o,
    output ctl::DBSrc db_src_o,
    output ctl::SBSrc sb_src_o,
    output ctl::ADLSrc adl_src_o,
    output ctl::ADHSrc adh_src_o,

    // Outside bus
    input bus_req_ack_i,
    output bus_req_valid_o,
    output bus_req_write_o,

    input bus_rsp_valid_i,
    input [7:0] bus_rsp_data_i
);
endmodule
