`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/23/2024 01:38:22 PM
// Design Name: 
// Module Name: decimal_adjust
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


module sar65s_decimal_adjust(
    input decimal_add_i,
    input decimal_subtract_i,
    input [7:0] data_i,
    input half_carry_i,
    input carry_i,

    output [7:0] data_o,
    output carry_o
    );

logic[4:0] add_low;
logic[4:0] add_high;

assign data_o = { add_high[3:0], add_low[3:0] };
assign carry_o = add_high[4];

always_comb begin
    if( decimal_add_i ) begin
        add_low = {1'b0, data_i[3:0]};

        if( !half_carry_i && data_i[3:0]>=10 )
            add_low += 5'd6;
        else if( half_carry_i )
            add_low[3:0] += 4'd6;

        add_high = {1'b0, data_i[7:4]} + add_low[4];
        if( !carry_i && data_i[7:4]>=10 )
            add_high += 5'd6;
        else if( carry_i ) begin
            add_high[3:0] += 4'd6;
            add_high[4] = 1'b1;
        end
    end else if( decimal_subtract_i ) begin
        add_low = {1'b1, data_i[3:0]};

        if( !half_carry_i )
            add_low[3:0] -= 4'd6;

        add_high = {1'b1, data_i[7:4]} - !add_low[4];
        if( !carry_i ) begin
            add_high[3:0] -= 4'd6;
            add_high[4] = 1'b0;
        end
    end else begin
        // Passthrough
        {add_high[3:0], add_low[3:0]} = data_i;
        add_low[4] = 1'bX;
        add_high[4] = carry_i;
    end
end

endmodule
