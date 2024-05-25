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

    input [ctl::DB7_N : ctl::DB0_C] control_signals_i,

    output [7:0] data_o
    );

logic [7:0] flags;
assign data_o = { flags[7:6], 1'b0, ~control_signals_i[ctl::O_B], flags[3:0] };

always_ff@(posedge clock_i, posedge reset_i) begin
    if( reset_i ) begin
        flags[ctl::FlagIntMask] = 1'b1;
        if( CPU_VARIANT>2 )
            flags[ctl::FlagDecimal] = 1'b0;
    end else begin
        if( control_signals_i[ctl::DB0_C] )
            flags[ctl::FlagCarry] <= data_i[0];
        if( control_signals_i[ctl::IR5_C] )
            flags[ctl::FlagCarry] <= ir5_i;
        if( control_signals_i[ctl::ACR_C] )
            flags[ctl::FlagCarry] <= acr_i;

        if( control_signals_i[ctl::DB1_Z] )
            flags[ctl::FlagZero] <= data_i[1];
        if( control_signals_i[ctl::DBZ_Z] )
            flags[ctl::FlagZero] <= (data_i == 8'h00);

        if( control_signals_i[ctl::DB2_I] )
            flags[ctl::FlagIntMask] <= data_i[2];
        if( control_signals_i[ctl::IR5_I] )
            flags[ctl::FlagIntMask] <= ir5_i;

        if( control_signals_i[ctl::DB3_D] )
            flags[ctl::FlagDecimal] <= data_i[3];
        if( control_signals_i[ctl::IR5_D] )
            flags[ctl::FlagDecimal] <= ir5_i;

        if( control_signals_i[ctl::DB6_V] )
            flags[ctl::FlagOverflow] <= data_i[6];
        if( control_signals_i[ctl::AVR_V] )
            flags[ctl::FlagOverflow] <= avr_i;
        if( control_signals_i[ctl::I_V] )
            flags[ctl::FlagOverflow] <= 1'b1;

        if( control_signals_i[ctl::DB7_N] )
            flags[ctl::FlagNegative] <= data_i[7];
    end
end

endmodule
