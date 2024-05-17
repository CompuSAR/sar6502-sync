`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/17/2024 02:58:56 PM
// Design Name: 
// Module Name: sar6502_2
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


module sar6502_2#( CPU_VARIANT=0 )(
    input clock_i,

    input reset_i,
    input nmi_i,
    input irq_i,
    input set_overflow_i,

    output bus_req_valid_o,
    output [15:0] bus_req_address_o,
    output bus_req_write_o,
    input  bus_req_ack_i,
    output [7:0] bus_req_data_o,
    input  bus_rsp_valid_i,
    input  [7:0] bus_rsp_data_i,

    output sync_o,
    output vector_pull_o,
    output memory_lock_o
    );
endmodule
