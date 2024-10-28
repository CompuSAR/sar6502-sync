`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/20/2024 05:06:07 PM
// Design Name: 
// Module Name: adh_gen
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


module sar65s_adh_gen(
    input [sar65s_ctl::O_ADH_1_7 : sar65s_ctl::O_ADH_0] ctrl,
    output logic[7:0] out

    );

always_comb begin
    out = 8'b11111111;

    if( ctrl[sar65s_ctl::O_ADH_0] )
        out[0] = 1'b0;
    if( ctrl[sar65s_ctl::O_ADH_1_7] )
        out[7:1] = 7'b0;
end

endmodule
