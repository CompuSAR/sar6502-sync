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

typedef enum {
    RegA = 0,
    RegX,
    RegY,
    RegS,
    RegPcL,
    RegPcH,
    RegDl,              // Input data latch

    NumRegisters
} REGISTER_NAMES;

// Buses
wire [7:0] data_bus, addr_bus_low, addr_bus_high, special_bus;

// Control signals
wire [ctl::NumCtlSignals-1:0] control_signals;
ctl::DBSrc data_bus_source;
ctl::SBSrc special_bus_source;
ctl::ADHSrc address_bus_high_source;
ctl::ADLSrc address_bus_low_source;

assign data_bus_source = ctl::AC_DB;
assign special_bus_source = ctl::AC_SB;
assign address_bus_high_source = ctl::PCH_ADH;
assign address_bus_low_source = ctl::PCL_ADL;

initial
    // Assert proper width of bus controls
    if($clog2(data_bus_source.last() + 1) != $size(ctl::DBSrc))
        $error("DBSrc needs to be %d bits", $clog2(data_bus_source.last() + 1));

    if($clog2(special_bus_source.last() + 1) != $size(ctl::SBSrc))
        $error("SBSrc needs to be %d bits", $clog2(special_bus_source.last() + 1));

    if($clog2(address_bus_high_source.last() + 1) != $size(ctl::ADHSrc))
        $error("ADHSrc needs to be %d bits", $clog2(address_bus_high_source.last() + 1));

    if($clog2(address_bus_low_source.last() + 1) != $size(ctl::ADLSrc))
        $error("ADLSrc needs to be %d bits", $clog2(address_bus_low_source.last() + 1));

genvar i;

generate

for( i=0; i<NumRegisters; ++i ) begin : regs
    wire [7:0] data_in, data_out;
    wire ctl_store;

    register(
        .clock_i(clock_i),
        .data_i(data_in),
        .ctl_store_i(ctl_store),
        .data_o(data_out)
    );
end

endgenerate

assign regs[RegA].data_in = special_bus;        // XXX Actually a BCD adjustment unit
assign regs[RegA].ctl_store = control_signals[ctl::SB_AC];

assign regs[RegX].data_in = special_bus;
assign regs[RegX].ctl_store = control_signals[ctl::SB_X];

assign regs[RegY].data_in = special_bus;
assign regs[RegY].ctl_store = control_signals[ctl::SB_Y];

assign regs[RegS].data_in = special_bus;
// XXX Actual stack pointer has a "hold" signal connected to S/S
assign regs[RegS].ctl_store = control_signals[ctl::SB_S];

// XXX implement PC logic

assign regs[RegDl].data_in = bus_rsp_data_i;
assign regs[RegDl].ctl_store = bus_rsp_valid_i;


wire [7:0] db_inputs[data_bus_source.last()];

assign db_inputs[ctl::AC_DB] = regs[RegA].data_out;
assign db_inputs[ctl::P_DB] = 8'bX;     // XXX Flags register
assign db_inputs[ctl::SB_DB] = special_bus;
assign db_inputs[ctl::PCH_DB] = regs[RegPcH].data_out;
assign db_inputs[ctl::PCL_DB] = regs[RegPcL].data_out;
assign db_inputs[ctl::DL_DB] = regs[RegDl].data_out;

assign data_bus = db_inputs[data_bus_source];


wire [7:0] sb_inputs[special_bus_source.last()];

assign sb_inputs[ctl::AC_SB] = regs[RegA].data_out;
assign sb_inputs[ctl::Y_SB] = regs[RegY].data_out;
assign sb_inputs[ctl::X_SB] = regs[RegX].data_out;
assign sb_inputs[ctl::ADD_SB] = 8'bX;   // XXX ALU output
assign sb_inputs[ctl::S_SB] = regs[RegS].data_out;

assign special_bus = sb_inputs[special_bus_source];


wire [7:0] adh_inputs[address_bus_high_source.last()];

assign adh_inputs[ctl::SB_ADH] = special_bus;
assign adh_inputs[ctl::PCH_ADH] = regs[RegPcH].data_out;
assign adh_inputs[ctl::GEN_ADH] = 8'bX; // XXX generated addresses
assign adh_inputs[ctl::DL_ADH] = regs[RegDl].data_out;

assign addr_bus_high = adh_inputs[address_bus_high_source];


wire [7:0] adl_inputs[address_bus_low_source.last()];

assign adl_inputs[ctl::ADD_ADL] = 8'bX; // XXX ALU output
assign adl_inputs[ctl::S_ADL] = regs[RegS].data_out;
assign adl_inputs[ctl::GEN_ADL] = 8'bX; // XXX generated addresses
assign adl_inputs[ctl::PCL_ADL] = regs[RegPcL].data_out;
assign adl_inputs[ctl::DL_ADL] = regs[RegDl].data_out;

assign addr_bus_low = adl_inputs[address_bus_low_source];


assign bus_req_data_o = data_bus;

endmodule
