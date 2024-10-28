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


module sar65s_processor_status#(
    CPU_VARIANT = 0
)(
    input clock_i,
    input reset_i,
    input halt_i,

    input [7:0] data_i,

    input ir5_i,
    input acr_i,
    input avr_i,
    input so_i,

    input [sar65s_ctl::NumCtlSignals-1 : 0] control_signals_i,

    output [7:0] data_o
    );

logic [7:0] flags;
assign data_o = { flags[7:6], 1'b1, ~control_signals_i[sar65s_ctl::O_B], flags[3:0] };
logic prev_so = 1'b0;

always_ff@(posedge clock_i) begin
    if( reset_i ) begin
        flags[sar65s_ctl::FlagIntMask] <= 1'b1;
        if( CPU_VARIANT>=2 )
            flags[sar65s_ctl::FlagDecimal] <= 1'b0;
    end else begin
        if( !prev_so && so_i )
            flags[sar65s_ctl::FlagOverflow] <= 1'b1;
        prev_so <= so_i;

        if( control_signals_i[sar65s_ctl::DB0_C] )
            flags[sar65s_ctl::FlagCarry] <= data_i[0];
        if( control_signals_i[sar65s_ctl::IR5_C] )
            flags[sar65s_ctl::FlagCarry] <= ir5_i;
        if( control_signals_i[sar65s_ctl::ACR_C] )
            flags[sar65s_ctl::FlagCarry] <= acr_i;

        if( control_signals_i[sar65s_ctl::DB1_Z] )
            flags[sar65s_ctl::FlagZero] <= data_i[1];
        if( control_signals_i[sar65s_ctl::DBZ_Z] )
            flags[sar65s_ctl::FlagZero] <= (data_i == 8'h00);

        if( control_signals_i[sar65s_ctl::DB2_I] )
            flags[sar65s_ctl::FlagIntMask] <= data_i[2];
        if( control_signals_i[sar65s_ctl::IR5_I] )
            flags[sar65s_ctl::FlagIntMask] <= ir5_i;

        if( control_signals_i[sar65s_ctl::DB3_D] )
            flags[sar65s_ctl::FlagDecimal] <= data_i[3];
        if( control_signals_i[sar65s_ctl::IR5_D] )
            flags[sar65s_ctl::FlagDecimal] <= ir5_i;

        if( control_signals_i[sar65s_ctl::DB6_V] )
            flags[sar65s_ctl::FlagOverflow] <= data_i[6];
        if( control_signals_i[sar65s_ctl::AVR_V] )
            flags[sar65s_ctl::FlagOverflow] <= avr_i;
        if( control_signals_i[sar65s_ctl::I_V] )
            flags[sar65s_ctl::FlagOverflow] <= 1'b1;

        if( control_signals_i[sar65s_ctl::DB7_N] )
            flags[sar65s_ctl::FlagNegative] <= data_i[7];
    end
end

endmodule
