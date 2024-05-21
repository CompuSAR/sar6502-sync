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
    output logic memory_lock_o,
    output logic sync_o,
    output logic vector_pull_o,

    output logic [ctl::NumCtlSignals-1:0] control_signals_o,
    output ctl::DBSrc db_src_o,
    output ctl::SBSrc sb_src_o,
    output ctl::ADLSrc adl_src_o,
    output ctl::ADHSrc adh_src_o,

    // Outside bus
    input bus_req_ack_i,
    output logic bus_req_valid_o,
    output logic bus_req_write_o,

    input bus_rsp_valid_i,
    input [7:0] bus_rsp_data_i
);

reg [7:0] instruction_register, instruction_register_next;
reg [7:0] instruction_counter, instruction_counter_next;
enum {
    IntReset,
    IntNmi,
    IntIrq,
    IntNone
} interrupt_type;

function set_default();
    memory_lock_o = 1'b0;
    sync_o = 1'b0;
    vector_pull_o = 1'b0;

    control_signals_o = { ctl::NumCtlSignals { 1'b0 } };
    db_src_o = ctl::DB_INVALID;
    sb_src_o = ctl::SB_INVALID;
    adl_src_o = ctl::ADL_INVALID;
    adh_src_o = ctl::ADH_INVALID;

    bus_req_valid_o = 1'b0;
    bus_req_write_o = 1'b0;

    instruction_register_next = instruction_register;
    instruction_counter_next = instruction_counter;
endfunction

always_comb begin
    set_default();

    if( reset_i ) begin
    end else if( instruction_counter==0 && interrupt_type!=IntNone ) begin
        handle_brk();
    end
end

function handle_brk();
    case( instruction_counter )
        0: begin
            control_signals_o[ctl::O_ADL_0] = 1'b1;
            control_signals_o[ctl::O_ADL_1] = 1'b1;
            control_signals_o[ctl::O_ADL_2] = 1'b0;

            control_signals_o[ctl::O_ADH_0] = 1'b0;
            control_signals_o[ctl::O_ADH_1_7] = 1'b0;

            adl_src_o = ctl::GEN_ADL;
            adh_src_o = ctl::GEN_ADH;
            bus_req_valid_o = 1'b1;
        end
    endcase
endfunction

always_ff@(posedge clock_i, posedge reset_i) begin
    if( reset_i ) begin
        instruction_counter <= 0;
        instruction_register <= 8'h00;
        interrupt_type <= IntReset;
    end else begin
        instruction_register <= instruction_register_next;
        instruction_counter <= instruction_counter_next;
    end
end

endmodule
