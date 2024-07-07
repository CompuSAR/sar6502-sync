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
    output ir5_o,

    input [7:0] flags_i,
    input dl7_i,
    output logic [ctl::NumCtlSignals-1:0] control_signals_o,
    output ctl::DBSrc db_src_o,
    output ctl::SBSrc sb_src_o,
    output ctl::ADLSrc adl_src_o,
    output ctl::ADHSrc adh_src_o,
    output ctl::ALUOp  alu_op_o,
    output ctl::AluBSrc alu_b_src_o,

    input alu_acr_i,

    // Outside bus
    input bus_req_ack_i,
    output logic bus_req_valid_o,
    output logic bus_req_write_o,

    input bus_rsp_valid_i,
    input [7:0] bus_rsp_data_i
);

enum logic[31:0] {
    C_INVALID   = 32'bX,
    C_NO_MATCH  = 32'b00000000000000000000000000000000,
    C_FETCH1    = 32'b00000000000000000000000000000001,
    C_FETCH2    = 32'b00000000000000000000000000000010,
    C_ADDR1     = 32'b00000000000000000000000000000100,
    C_ADDR2     = 32'b00000000000000000000000000001000,
    C_ADDR3     = 32'b00000000000000000000000000010000,
    C_ADDR4     = 32'b00000000000000000000000000100000,
    C_ADDR5     = 32'b00000000000000000000000001000000,
    C_ADDR6     = 32'b00000000000000000000000010000000,
    C_ADDR7     = 32'b00000000000000000000000100000000,
    C_ADDR8     = 32'b00000000000000000000001000000000,
    C_ADDR9     = 32'b00000000000000000000010000000000,
    C_ADDR10    = 32'b00000000000000000000100000000000,
    C_ADDR11    = 32'b00000000000000000001000000000000,
    C_ADDR_MASK = 32'b00000000000000000001111111111100,
    C_OP1       = 32'b00000000000000000100000000000000,
    C_OP2       = 32'b00000000000000001000000000000000,
    C_OP3       = 32'b00000000000000010000000000000000,
    C_OP4       = 32'b00000000000000100000000000000000,
    C_OP5       = 32'b00000000000001000000000000000000,
    C_OP6       = 32'b00000000000010000000000000000000,
    C_PENDING7  = 32'b00000000000100000000000000000000,
    C_PENDING8  = 32'b00000000001000000000000000000000,
    C_PENDING9  = 32'b00000000010000000000000000000000,
    C_PENDING10 = 32'b00000000100000000000000000000000,
    C_PENDING11 = 32'b00000001000000000000000000000000,
    C_PENDING12 = 32'b00000010000000000000000000000000,
    C_PENDING13 = 32'b00000100000000000000000000000000,
    C_PENDING14 = 32'b00001000000000000000000000000000,
    C_PENDING15 = 32'b00010000000000000000000000000000,
    C_PENDING16 = 32'b00100000000000000000000000000000,
    C_PENDING17 = 32'b01000000000000000000000000000000,
    C_PENDING18 = 32'b10000000000000000000000000000000
} instruction_counter, instruction_counter_next;

logic bus_waiting_result = 1'b0;
reg [7:0] instruction_register, instruction_register_next;
assign ir5_o = instruction_register[5];

reg addr_load_value;
reg alu_acr_delayed;

logic condtion_flag, condition_flags[4];
assign condition_flags[2'b00] = flags_i[ctl::FlagNegative];
assign condition_flags[2'b01] = flags_i[ctl::FlagOverflow];
assign condition_flags[2'b10] = flags_i[ctl::FlagCarry];
assign condition_flags[2'b11] = flags_i[ctl::FlagZero];

assign condtion_flag = condition_flags[ instruction_register[7:6] ];

enum {
    IntReset,
    IntNmi,
    IntIrq,
    IntNone
} int_pending = IntNone, int_pending_next, int_active, int_active_next;

function void set_default();
    memory_lock_o = 1'b0;
    sync_o = 1'b0;
    vector_pull_o = 1'b0;

    addr_load_value = 1'b0;

    control_signals_o = { ctl::NumCtlSignals { 1'b0 } };
    db_src_o = ctl::DB_INVALID;
    sb_src_o = ctl::SB_INVALID;
    adl_src_o = ctl::ADL_INVALID;
    adh_src_o = ctl::ADH_INVALID;
    alu_op_o = ctl::ALU_INVALID;
    alu_b_src_o = ctl::ALU_B_INVALID;

    bus_req_valid_o = 1'b0;
    bus_req_write_o = 1'b0;

    instruction_register_next = instruction_register;
    int_active_next = int_active;
    int_pending_next = int_pending;

    if( bus_waiting_result && !bus_rsp_valid_i )
        instruction_counter_next = instruction_counter;
    else
        $cast( instruction_counter_next, { instruction_counter[30:0], 1'b0 } );
endfunction

function void set_invalid_state();
    memory_lock_o = 1'bX;
    sync_o = 1'bX;
    vector_pull_o = 1'bX;

    control_signals_o = { ctl::NumCtlSignals { 1'bX } };
    db_src_o = ctl::DB_INVALID;
    sb_src_o = ctl::SB_INVALID;
    adl_src_o = ctl::ADL_INVALID;
    adh_src_o = ctl::ADH_INVALID;
    alu_op_o = ctl::ALU_INVALID;
    alu_b_src_o = ctl::ALU_B_INVALID;

    bus_req_valid_o = 1'bX;
    bus_req_write_o = 1'bX;

    instruction_register_next = 8'hXX;

    instruction_counter_next = C_INVALID;
endfunction

always_comb begin
    set_default();

    if( reset_i ) begin
    end else case( instruction_counter )
        C_FETCH1: handle_fetch();
        C_FETCH2: handle_fetch();
        default: handle_op();
    endcase
end

function void handle_op();
    case( instruction_register )
        8'h00: begin handle_op_brk(); end
        8'h08: begin handle_op_php(); end
        8'h10: begin handle_op_branch(); end
        8'h18: begin handle_op_set_flag(); end
        8'h20: begin handle_op_jsr(); end
        8'h28: begin handle_op_plp(); end
        8'h30: begin handle_op_branch(); end
        8'h38: begin handle_op_set_flag(); end
        8'h40: begin handle_op_rti(); end
        8'h48: begin handle_op_pha(); end
        8'h4c: begin handle_addr_abs(); handle_op_jmp(); end
        8'h50: begin handle_op_branch(); end
        8'h58: begin handle_op_set_flag(); end
        8'h60: begin handle_op_rts(); end
        8'h6d: begin handle_addr_abs(); handle_op_adc(); end
        8'h70: begin handle_op_branch(); end
        8'h78: begin handle_op_set_flag(); end
        8'h8a: begin handle_op_txa(); end
        8'h8d: begin handle_addr_abs(); handle_op_sta(); end
        8'h90: begin handle_op_branch(); end
        8'h98: begin handle_op_tya(); end
        8'h9a: begin handle_op_txs(); end
        8'ha0: begin handle_addr_imm(); handle_op_ldy(); end
        8'ha2: begin handle_addr_imm(); handle_op_ldx(); end
        8'ha5: begin handle_addr_zp(); handle_op_lda(); end
        8'ha9: begin handle_addr_imm(); handle_op_lda(); end
        8'had: begin handle_addr_abs(); handle_op_lda(); end
        8'hb0: begin handle_op_branch(); end
        8'hb8: begin handle_op_clv(); end
        8'hb9: begin handle_addr_abs_y(); handle_op_lda(); end
        8'hbd: begin handle_addr_abs_x(); handle_op_lda(); end
        8'hd0: begin handle_op_branch(); end
        8'hd8: begin handle_op_set_flag(); end
        8'hea: begin handle_op_nop(); end
        8'hf0: begin handle_op_branch(); end
        8'hf8: begin handle_op_set_flag(); end
        default: begin
            $error("Invalid opcode in instruction register %x time %t", instruction_register, $time());
            set_invalid_state();
        end
    endcase
endfunction

function void handle_fetch();
    case(instruction_counter)
        C_FETCH1: begin
            addr_out_pc();

            int_pending_next = IntNone;

            if( int_pending!=IntNone ) begin
                int_active_next = int_pending;
            end else if( irq_i ) begin
                int_active_next = IntIrq;
            end else begin
                int_active_next = IntNone;

                advance_pc();
            end

            sync_o = 1'b1;
        end
        C_FETCH2: begin
            addr_out_pc();

            if( int_active!=IntNone )
                instruction_register_next = 8'h00;      // BRK
            else
                /* In theory, we need here "if( bus_rsp_valid_i )".
                 * In practice, since this cycle never issues a request, the
                 * only reason to stall here is because the response has not
                 * yet arrived. As such, as soon as a response did arrive,
                 * we're guaranteed to advance to the next cycle.
                 */
                instruction_register_next = bus_rsp_data_i;
        end
        default: set_invalid_state();
    endcase
endfunction

`include "decoder_addr.vh"
`include "decoder_ops.vh"

function void advance_pc();
    control_signals_o[ctl::I_PC] = 1'b1;
endfunction

function void new_instruction();
    instruction_counter_next = C_FETCH1;
endfunction

function addr_cycle();
    addr_cycle = (instruction_counter & C_ADDR_MASK) != C_NO_MATCH;
endfunction

function void addr_out_pc();
    adl_src_o = ctl::PCL_ADL;
    control_signals_o[ctl::ADL_ABL] = 1'b1;

    adh_src_o = ctl::PCH_ADH;
    control_signals_o[ctl::ADH_ABH] = 1'b1;

    bus_req_valid_o = 1'b1;
endfunction

function void addr_out_stack( input write );
    adl_src_o = ctl::S_ADL;
    control_signals_o[ctl::ADL_ABL] = 1'b1;

    adh_src_o = ctl::GEN_ADH;
    control_signals_o[ctl::O_ADH_0] = 1'b0;
    control_signals_o[ctl::O_ADH_1_7] = 1'b1;
    control_signals_o[ctl::ADH_ABH] = 1'b1;

    bus_req_valid_o = 1'b1;
    bus_req_write_o = write;
endfunction

function void decrease_sp();
    db_src_o = ctl::O_DB;
    alu_b_src_o = ctl::DBB_ADD;
    sb_src_o = ctl::S_SB;
    alu_op_o = ctl::SUMS;

    control_signals_o[ctl::DAA] = 1'b0;
    control_signals_o[ctl::I_ADDC] = 1'b0;
endfunction

function void increase_sp();
    alu_b_src_o = ctl::ADL_ADD;
    sb_src_o = ctl::O_SB;
    alu_op_o = ctl::SUMS;

    control_signals_o[ctl::DAA] = 1'b0;
    control_signals_o[ctl::I_ADDC] = 1'b1;
endfunction

always_ff@(posedge clock_i) begin
    if( reset_i ) begin
        instruction_counter <= C_FETCH1;
        instruction_register <= 8'h00;
        int_pending <= IntReset;
    end else begin
        if( bus_req_valid_o && ! bus_req_ack_i ) begin
            // Request cannot be served
        end else begin
            instruction_register <= instruction_register_next;
            instruction_counter <= instruction_counter_next;
        end

        int_pending <= int_pending_next;
        int_active <= int_active_next;
    end

    bus_waiting_result <= (bus_req_valid_o && !bus_req_write_o) || (bus_waiting_result && !bus_rsp_valid_i);

    alu_acr_delayed <= alu_acr_i;
end

endmodule
