`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/24/2024 12:39:26 PM
// Design Name: 
// Module Name: alu
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


module alu(
    input [7:0] a_i,
    input [7:0] b_i,
    input carry_i,

    input ctl::ALUOp op_i,

    output [7:0] result_o,
    output overflow_o,
    output carry_o,
    output half_carry_o
    );

logic [8:0] results[6];
/*
logic [8:0] results[op_i.last() + 1];
*/

wire [4:0] low_half_add = { 1'b0, a_i[3:0] } + { 1'b0, b_i[3:0] } + carry_i;
wire [4:0] high_half_add = { 1'b0, a_i[7:4] } + { 1'b0, b_i[7:4] } + half_carry_o;

assign results[ctl::SUMS] = { high_half_add, low_half_add[3:0] };
assign results[ctl::ANDS] = a_i & b_i;
assign results[ctl::EORS] = a_i ^ b_i;
assign results[ctl::ORS]  = a_i | b_i;
assign results[ctl::SRS]  = { a_i[0], carry_i, a_i[7:1] };
assign results[ctl::SLS]  = { a_i, carry_i };

assign half_carry_o = low_half_add[4];
assign result_o = results[op_i][7:0];
assign carry_o = results[op_i][8];
assign overflow_o = a_i[7]==b_i[7] && results[ctl::SUMS][7]!=a_i[7];

endmodule
