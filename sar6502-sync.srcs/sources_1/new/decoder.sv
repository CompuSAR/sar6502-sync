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

enum logic[31:0] {
    C_INVALID   = 32'bX,
    C_INVALID2  = 32'b00000000000000000000000000000000,
    C_FETCH1    = 32'b00000000000000000000000000000001,
    C_FETCH2    = 32'b00000000000000000000000000000010,
    C_ADDR1     = 32'b00000000000000000000000000000100,
    C_ADDR2     = 32'b00000000000000000000000000001000,
    C_ADDR3     = 32'b00000000000000000000000000010000,
    C_ADDR4     = 32'b00000000000000000000000000100000,
    C_ADDR5     = 32'b00000000000000000000000001000000,
    C_ADDR6     = 32'b00000000000000000000000010000000,
    C_ADDR7     = 32'b00000000000000000000000100000000,
    C_PENDING1  = 32'b00000000000000000000001000000000,
    C_PENDING2  = 32'b00000000000000000000010000000000,
    C_PENDING3  = 32'b00000000000000000000100000000000,
    C_PENDING4  = 32'b00000000000000000001000000000000,
    C_PENDING5  = 32'b00000000000000000010000000000000,
    C_PENDING6  = 32'b00000000000000000100000000000000,
    C_PENDING7  = 32'b00000000000000001000000000000000,
    C_PENDING8  = 32'b00000000000000010000000000000000,
    C_PENDING9  = 32'b00000000000000100000000000000000,
    C_PENDING10 = 32'b00000000000001000000000000000000,
    C_PENDING11 = 32'b00000000000010000000000000000000,
    C_PENDING12 = 32'b00000000000100000000000000000000,
    C_PENDING13 = 32'b00000000001000000000000000000000,
    C_PENDING14 = 32'b00000000010000000000000000000000,
    C_PENDING15 = 32'b00000000100000000000000000000000,
    C_PENDING16 = 32'b00000001000000000000000000000000,
    C_PENDING17 = 32'b00000010000000000000000000000000,
    C_PENDING18 = 32'b00000100000000000000000000000000,
    C_PENDING19 = 32'b00001000000000000000000000000000,
    C_PENDING20 = 32'b00010000000000000000000000000000,
    C_PENDING21 = 32'b00100000000000000000000000000000,
    C_PENDING22 = 32'b01000000000000000000000000000000,
    C_PENDING23 = 32'b10000000000000000000000000000000
} instruction_counter, instruction_counter_next;

logic bus_waiting_result = 1'b0;
reg [7:0] instruction_register, instruction_register_next;

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

    control_signals_o = { ctl::NumCtlSignals { 1'b0 } };
    db_src_o = ctl::DB_INVALID;
    sb_src_o = ctl::SB_INVALID;
    adl_src_o = ctl::ADL_INVALID;
    adh_src_o = ctl::ADH_INVALID;

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
    $display("handle_op called inst %02X cycle %x", instruction_register, instruction_counter );
    case( instruction_register )
        8'h00: begin handle_brk(); end
        default: begin
            $error("Invalid opcode in instruction register %x time %t", instruction_register, $time());
            set_invalid_state();
        end
    endcase
endfunction

function void handle_fetch();
    case(instruction_counter)
        C_FETCH1: begin
            adl_src_o = ctl::PCL_ADL;
            adh_src_o = ctl::PCH_ADH;

            bus_req_valid_o = 1'b1;

            int_pending_next = IntNone;

            if( int_pending!=IntNone ) begin
                int_active_next = int_pending;
            end else if( irq_i ) begin
                int_active_next = IntIrq;
            end else begin
                int_active_next = IntNone;

                // Advance PC
                control_signals_o[ctl::PCL_PCL] = 1'b1;
                control_signals_o[ctl::PCH_PCH] = 1'b1;

                control_signals_o[ctl::I_PC] = 1'b1;
            end
        end
        C_FETCH2: begin
            if( int_active!=IntNone )
                instruction_register_next = 8'h00;      // BRK
            else
                instruction_register_next = bus_rsp_data_i;
        end
        default: set_invalid_state();
    endcase
endfunction

function void handle_brk();
    $display("handle_brk cycle %s", instruction_counter.name());
    case( instruction_counter )
        C_ADDR1: begin
            adl_src_o = ctl::GEN_ADL;
            control_signals_o[ctl::O_ADL_0] = 1'b1;
            control_signals_o[ctl::O_ADL_1] = 1'b1;
            control_signals_o[ctl::O_ADL_2] = 1'b0;

            adh_src_o = ctl::GEN_ADH;
            control_signals_o[ctl::O_ADH_0] = 1'b0;
            control_signals_o[ctl::O_ADH_1_7] = 1'b0;

            bus_req_valid_o = 1'b1;
        end
        C_ADDR2: begin end
        C_ADDR3: begin
            adl_src_o = ctl::DL_ADL;
            control_signals_o[ctl::ADL_PCL] = 1'b1;
        end
        C_ADDR4: begin
            adl_src_o = ctl::GEN_ADL;
            control_signals_o[ctl::O_ADL_0] = 1'b0;
            control_signals_o[ctl::O_ADL_1] = 1'b1;
            control_signals_o[ctl::O_ADL_2] = 1'b0;

            adh_src_o = ctl::GEN_ADH;
            control_signals_o[ctl::O_ADH_0] = 1'b0;
            control_signals_o[ctl::O_ADH_1_7] = 1'b0;

            bus_req_valid_o = 1'b1;
        end
        C_ADDR5: begin end
        C_ADDR6: begin
            new_instruction();

            adh_src_o = ctl::DL_ADH;
            control_signals_o[ctl::ADH_PCH] = 1'b1;
        end
        default: set_invalid_state();
    endcase
endfunction

function void new_instruction();
    instruction_counter_next = C_FETCH1;
endfunction

always_ff@(posedge clock_i) begin
    if( reset_i ) begin
        instruction_counter <= C_FETCH1;
        instruction_register <= 8'h00;
        int_pending <= IntReset;
    end else begin
        instruction_register <= instruction_register_next;
        instruction_counter <= instruction_counter_next;

        int_pending <= int_pending_next;
        int_active <= int_active_next;
    end

    bus_waiting_result <= bus_req_valid_o || (bus_waiting_result && !bus_rsp_valid_i);
end

endmodule
