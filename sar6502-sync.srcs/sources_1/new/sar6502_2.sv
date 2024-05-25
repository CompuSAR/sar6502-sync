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
logic [7:0] alu_result;
logic alu_avr, alu_acr, alu_hc;

// Control signals
wire [ctl::NumCtlSignals-1:0] control_signals;
ctl::DBSrc data_bus_source;
ctl::SBSrc special_bus_source;
ctl::ADHSrc address_bus_high_source;
ctl::ADLSrc address_bus_low_source;
ctl::ALUOp alu_op;
ctl::AluBSrc alu_b_source;

decoder#(.CPU_VARIANT(CPU_VARIANT)) decoder(
    .clock_i(clock_i),
    .reset_i(reset_i),
    .irq_i(irq_i),
    .nmi_i(nmi_i),
    .memory_lock_o(memory_lock_o),
    .sync_o(sync_o),
    .vector_pull_o(vector_pull_o),

    .control_signals_o(control_signals),
    .db_src_o(data_bus_source),
    .sb_src_o(special_bus_source),
    .adl_src_o(address_bus_low_source),
    .adh_src_o(address_bus_high_source),
    .alu_op_o(alu_op),
    .alu_b_src_o(alu_b_source),

    .alu_acr_i(alu_acr),

    .bus_req_ack_i(bus_req_ack_i),
    .bus_req_valid_o(bus_req_valid_o),
    .bus_req_write_o(bus_req_write_o),
    .bus_rsp_valid_i(bus_rsp_valid_i),
    .bus_rsp_data_i(bus_rsp_data_i)
);



initial begin
    // Assert proper width of bus controls
    if($clog2(data_bus_source.last() + 1) != $size(ctl::DBSrc))
        $error("DBSrc needs to be %d bits", $clog2(data_bus_source.last() + 1));

    if($clog2(special_bus_source.last() + 1) != $size(ctl::SBSrc))
        $error("SBSrc needs to be %d bits", $clog2(special_bus_source.last() + 1));

    if($clog2(address_bus_high_source.last() + 1) != $size(ctl::ADHSrc))
        $error("ADHSrc needs to be %d bits", $clog2(address_bus_high_source.last() + 1));

    if($clog2(address_bus_low_source.last() + 1) != $size(ctl::ADLSrc))
        $error("ADLSrc needs to be %d bits", $clog2(address_bus_low_source.last() + 1));

    if($clog2(alu_op.last() + 1) != $size(ctl::ALUOp))
        $error("ALUOp needs to be %d bits", $clog2(alu_op.last() + 1));

    if($clog2(alu_b_source.last() + 1) != $size(ctl::AluBSrc))
        $error("AluBSrc needs to be %d bits", $clog2(alu_b_source.last() + 1));
end

genvar i;

generate

for( i=0; i<NumRegisters; ++i ) begin : regs
    wire [7:0] data_in, data_out;
    wire ctl_store;

    register register(
        .clock_i(clock_i),
        .data_i(data_in),
        .ctl_store_i(ctl_store),
        .data_o(data_out)
    );
end

endgenerate

wire [7:0] adh_generated_values;
adh_gen adh_generator( .ctrl(control_signals[ctl::O_ADH_1_7:ctl::O_ADH_0]), .out(adh_generated_values) );

wire [7:0] adl_generated_values;
adl_gen adl_generator( .ctrl(control_signals[ctl::O_ADL_2:ctl::O_ADL_0]), .out(adl_generated_values) );

assign regs[RegA].data_in = special_bus;        // XXX Actually a BCD adjustment unit
assign regs[RegA].ctl_store = control_signals[ctl::SB_AC];

assign regs[RegX].data_in = special_bus;
assign regs[RegX].ctl_store = control_signals[ctl::SB_X];

assign regs[RegY].data_in = special_bus;
assign regs[RegY].ctl_store = control_signals[ctl::SB_Y];

assign regs[RegS].data_in = special_bus;
// XXX Actual stack pointer has a "hold" signal connected to S/S
assign regs[RegS].ctl_store = control_signals[ctl::SB_S];


wire [7:0] pcl_select = control_signals[ctl::ADL_PCL] ? addr_bus_low : regs[RegPcL].data_out;
wire [8:0] pcl_select_increment = pcl_select + (control_signals[ctl::I_PC] ? 8'h01 : 8'h00);
wire pcl_carry = pcl_select_increment[8];

assign regs[RegPcL].data_in = pcl_select_increment[7:0];
assign regs[RegPcL].ctl_store = 1'b1;


// No clock-delay passthrough
wire [7:0] pch_select = control_signals[ctl::ADH_PCH] ? addr_bus_high : regs[RegPcH].data_out;

assign regs[RegPcH].data_in = pch_select + pcl_carry;
assign regs[RegPcH].ctl_store = 1'b1;

assign regs[RegDl].data_in = bus_rsp_data_i;
assign regs[RegDl].ctl_store = bus_rsp_valid_i;

wire [7:0] alu_b_input, alu_result_async;

alu alu_unit(
    .a_i(special_bus),
    .b_i(alu_b_input),
    .decimal_enable_i( control_signals[ctl::DAA] ),
    .carry_i( control_signals[ctl::I_ADDC] ),
    .op_i( alu_op ),

    .result_o( alu_result_async ),
    .overflow_o( alu_avr ),
    .carry_o( alu_acr ),
    .half_carry_o( alu_hc )
);

always_ff@(posedge clock_i)
    alu_result <= alu_result_async;

wire [7:0] db_inputs[data_bus_source.last() + 1];

assign db_inputs[ctl::O_DB] = 8'h00;
assign db_inputs[ctl::AC_DB] = regs[RegA].data_out;
assign db_inputs[ctl::P_DB] = 8'bX;     // XXX Flags register
assign db_inputs[ctl::SB_DB] = special_bus;
assign db_inputs[ctl::PCH_DB] = regs[RegPcH].data_out;
assign db_inputs[ctl::PCL_DB] = regs[RegPcL].data_out;
assign db_inputs[ctl::DL_DB] = regs[RegDl].data_out;

assign data_bus = db_inputs[data_bus_source];
logic [7:0] data_bus_latch;

always_ff@(posedge clock_i)
    data_bus_latch <= data_bus;

wire [7:0] sb_inputs[special_bus_source.last() + 1];

assign sb_inputs[ctl::O_SB] = 8'h00;
assign sb_inputs[ctl::AC_SB] = regs[RegA].data_out;
assign sb_inputs[ctl::Y_SB] = regs[RegY].data_out;
assign sb_inputs[ctl::X_SB] = regs[RegX].data_out;
assign sb_inputs[ctl::ADD_SB] = alu_result;
assign sb_inputs[ctl::S_SB] = regs[RegS].data_out;
assign sb_inputs[ctl::DL_SB] = regs[RegDl].data_out;

assign special_bus = sb_inputs[special_bus_source];


wire [7:0] adh_inputs[address_bus_high_source.last() + 1];

assign adh_inputs[ctl::SB_ADH] = special_bus;
assign adh_inputs[ctl::PCH_ADH] = regs[RegPcH].data_out;
assign adh_inputs[ctl::GEN_ADH] = adh_generated_values;
assign adh_inputs[ctl::DL_ADH] = regs[RegDl].data_out;

assign addr_bus_high = adh_inputs[address_bus_high_source];


wire [7:0] adl_inputs[address_bus_low_source.last() + 1];

assign adl_inputs[ctl::ADD_ADL] = alu_result;
assign adl_inputs[ctl::S_ADL] = regs[RegS].data_out;
assign adl_inputs[ctl::GEN_ADL] = adl_generated_values;
assign adl_inputs[ctl::PCL_ADL] = regs[RegPcL].data_out;
assign adl_inputs[ctl::DL_ADL] = regs[RegDl].data_out;

assign addr_bus_low = adl_inputs[address_bus_low_source];


wire [7:0] alu_b_inputs[alu_b_source.last() + 1];

assign alu_b_inputs[ctl::ADL_ADD] = addr_bus_low;
assign alu_b_inputs[ctl::DB_ADD] = data_bus;
assign alu_b_inputs[ctl::DBB_ADD] = ~ data_bus;

assign alu_b_input = alu_b_inputs[alu_b_source];


logic [7:0] abh_out, abh_out_latch, abl_out, abl_out_latch;

always_ff@(posedge clock_i) begin
    if( control_signals[ctl::ADL_ABL] )
        abl_out_latch <= addr_bus_low;
    if( control_signals[ctl::ADH_ABH] )
        abh_out_latch <= addr_bus_high;
end

assign abh_out = control_signals[ctl::ADH_ABH] ? addr_bus_high : abh_out_latch;
assign abl_out = control_signals[ctl::ADL_ABL] ? addr_bus_low : abl_out_latch;

assign bus_req_data_o = data_bus;
assign bus_req_address_o = { abh_out, abl_out };

endmodule
