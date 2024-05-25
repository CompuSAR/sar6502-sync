`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/25/2024 09:37:03 PM
// Design Name: 
// Module Name: processor_status
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


module processor_status#(
    CPU_VARIANT = 0
)(
    input clock_i,
    input reset_i,

    input [7:0] data_i,

    input ir5_i,
    input acr_i,
    input avr_i,

    input [DB7_N:DB0_C] control_signals_i,

    output [7:0] data_o
    );

logic [7:0] flags;
assign data_o = { flags[7:6], 1'b0, control_signals_i[O_B], flags[3:0] };

always_ff@(posedge clock_i, posedge reset_i) begin
    if( reset_i ) begin
        flags[FlagIntMask] = 1'b1;
        if( CPU_VARIANT>2 )
            flags[FlagDecimal] = 1'b0;
    end else begin
        if( control_signals_i[DB0_C] )
            flags[FlagCarry] <= data_i[0];
        if( control_signals_i[IR5_C] )
            flags[FlagCarry] <= ir5_i;
        if( control_signals_i[ACR_C] )
            flags[FlagCarry] <= acr_i;

        if( control_signals_i[DB1_Z] )
            flags[FlagZero] <= data_i[1];
        if( control_signals_i[DBZ_Z] )
            flags[FlagZero] <= (data_i == 8'h00);

        if( control_signals_i[DB2_I] )
            flags[FlagIntMask] <= data_i[2];
        if( control_signals_i[IR5_I] )
            flags[FlagIntMask] <= ir5_i;

        if( control_signals_i[DB3_D] )
            flags[FlagDecimal] <= data_i[3];
        if( control_signals_i[IR5_D] )
            flags[FlagDecimal] <= ir5_i;

        if( control_signals_i[DB6_V] )
            flags[FlagOverflow] <= data_i[6];
        if( control_signals_i[AVR_V] )
            flags[FlagOverflow] <= avr_i;
        if( control_signals_i[I_V] )
            flags[FlagOverflow] <= 1'b1;

        if( control_signals_i[DB7_N] )
            flags[FlagNegative] <= data_i[7];
    end
end

endmodule
