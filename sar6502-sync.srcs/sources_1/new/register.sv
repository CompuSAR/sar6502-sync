`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/17/2024 08:36:02 PM
// Design Name: 
// Module Name: register
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


module sar65s_register#(Width = 8)
(
    input clock_i,
    input [Width-1:0] data_i,

    input ctl_store_i,

    output [Width-1:0] data_o
);

reg [Width-1:0] data = 8'h00;

assign data_o = data;

always_ff@(posedge clock_i) begin
    if( ctl_store_i )
        data <= data_i;
end

endmodule
