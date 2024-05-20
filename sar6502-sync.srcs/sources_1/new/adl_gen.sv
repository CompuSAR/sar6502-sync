`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/20/2024 05:10:15 PM
// Design Name: 
// Module Name: adl_gen
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


module adl_gen(
    input [ctl::O_ADL_2:ctl::O_ADL_0] ctrl,
    output logic[7:0] out

    );

always_comb begin
    out = 8'b11111111;

    if( ctrl[ctl::O_ADL_0] )
        out[0] = 1'b0;
    if( ctrl[ctl::O_ADL_1] )
        out[1] = 1'b0;
    if( ctrl[ctl::O_ADL_2] )
        out[2] = 1'b0;
end

endmodule
