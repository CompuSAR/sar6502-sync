`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/26/2024 02:28:40 PM
// Design Name: 
// Module Name: simulation_top
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

module simulation_top#
(
    parameter CPU_VARIANT = 0,
    parameter MEMORY_FILE = "",
    parameter TEST_PLAN_FILE = ""
)
(
);

localparam tPWL = 5;            // Time Pulse Width Low (clock)
localparam tPWH = 5;            // Time Pulse Width High (clock)
localparam MaxCyclesPerBus=4;   // Maximum number of clock cycles between bus operations
localparam AckDelayCounter=5;
localparam RspDelayCounter=3;

logic clock;
logic [7:0] memory[65535:0];
logic [35:0]test_plan[30000];

logic [15:0] rsp_delay_counter = 0;
logic [7:0] rsp_data;

typedef enum { SigReset, SigIrq, SigNmi, SigSo, SigReady, Sig_NumElements } signal_types;
wire signals[Sig_NumElements-1:0];
struct {
    int delay = 0;
    int count = 0;
} pending_signals[Sig_NumElements-1:0];

initial begin
    pending_signals[0].delay = 0;
    pending_signals[0].count = 10;
end

genvar i;

generate
for(i=0; i<Sig_NumElements; ++i)
    assign signals[i] = pending_signals[i].delay==0 && pending_signals[i].count!=0;
endgenerate

int ack_counter = 0;
logic cpu_req_valid, cpu_req_write, cpu_sync, cpu_rsp_valid = 1'b0;
wire cpu_req_ack = !signals[SigReady] && ack_counter>=AckDelayCounter;
logic [7:0] cpu_req_data, prev_req_data = 8'hXX, cpu_rsp_data = 8'hXX;
logic [15:0] cpu_req_address, prev_req_address = 16'hXXXX;
logic prev_req_write;

sar6502_sync#(.CPU_VARIANT(CPU_VARIANT))
cpu(
    .clock_i(clock),

    .reset_i( signals[SigReset] ),
    .nmi_i( signals[SigNmi] ),
    .irq_i( signals[SigIrq] ),
    .set_overflow_i( signals[SigSo] ),
    .sync_o(cpu_sync),

    .bus_req_valid_o(cpu_req_valid),
    .bus_req_address_o(cpu_req_address),
    .bus_req_write_o(cpu_req_write),
    .bus_req_ack_i(cpu_req_ack),
    .bus_req_data_o(cpu_req_data),
    .bus_rsp_valid_i(cpu_rsp_valid),
    .bus_rsp_data_i(cpu_rsp_data)
);

initial begin
    $readmemh(MEMORY_FILE, memory);
    $readmemh(TEST_PLAN_FILE, test_plan);
end

initial forever begin
    clock = 1'b0;
    #tPWL
    clock = 1'b1;
    #tPWH
    ;
end

int cycles_since_bus = 0;
int cycle_num = 0;
logic reset_sequence = 0;
int cycles_skip;

always_ff@(posedge clock) begin
    if( cpu_req_ack && cpu_req_valid ) begin
        ack_counter <= 0;

        prev_req_address <= 16'hXXXX;
        prev_req_data <= 8'hXX;
        prev_req_write <= 1'bX;
    end else begin
        ack_counter <= ack_counter+1;

        if( cpu_req_valid ) begin
            if( prev_req_address === 16'hXXXX ) begin
                prev_req_address <= cpu_req_address;
                prev_req_write <= cpu_req_write;
                prev_req_data <= cpu_req_data;
            end else begin
                assert_state( cpu_req_address, prev_req_address, "Previously unacked request had different address" );
                assert_state( cpu_req_write, prev_req_write, "Previously unacked request had different write state" );
                if( prev_req_write )
                    assert_state( cpu_req_data, prev_req_data, "Previously unacked request had different data" );
            end
        end
    end
end

always_ff@(posedge clock) begin
    cpu_rsp_data <= 8'hXX;
    cpu_rsp_valid <= 1'b0;

    if( rsp_delay_counter>0 ) begin
        rsp_delay_counter <= rsp_delay_counter-1;

        if( rsp_delay_counter==1 ) begin
            cpu_rsp_valid <= 1'b1;
            cpu_rsp_data <= rsp_data;

            rsp_data <= 8'hXX;
        end
    end

    if( signals[SigReset] ) begin
        reset_sequence <= 1'b1;

        for( cycles_skip=0; test_plan[cycle_num+cycles_skip][31:16] != 16'hfffc; ++cycles_skip ) begin
        end

        cycle_num <= cycle_num+cycles_skip;
    end

    if( cycles_since_bus==MaxCyclesPerBus ) begin
        if( signals[SigReset] || signals[SigReady] || reset_sequence ) begin
            update_pending_status();
            cycles_since_bus <= 0;
            if( !reset_sequence && !signals[SigReset] ) begin
                cycle_num <= cycle_num+1;
            end
        end else begin
            $error("Too many cycles since last bus operation on cycle %d time %t", cycle_num + 1, $time);
            $finish();
        end
    end else begin
        if( cpu_req_ack || signals[SigReady] )
            cycles_since_bus <= cycles_since_bus+1;

        if( cpu_req_valid && cpu_req_ack ) begin
            cycles_since_bus <= 0;

            update_pending_status();
            handle_bus_op();
        end
    end
end

task update_pending_status();
    foreach( pending_signals[i] ) begin
        if( pending_signals[i].delay != 0 )
            pending_signals[i].delay <= pending_signals[i].delay - 1;
        else if( pending_signals[i].count != 0 )
            pending_signals[i].count <= pending_signals[i].count - 1;
    end
endtask

wire [35:0] plan_line = test_plan[cycle_num];

task handle_bus_op();
    if( reset_sequence ) begin
        if( cpu_req_valid && cpu_req_address===16'hfffc ) begin
            $display("Detected reset done condition at time %t", $time);

            reset_sequence <= 1'b0;
        end else begin
            $display("In-reset cycle %s address %04x data %02x time %t", cpu_req_write ? "write" : "read", cpu_req_address, cpu_req_data, $time);

            assert_state( rsp_delay_counter, 0, "Request arrives while a response is pending (reset)" );
            rsp_data <= 8'hXX;
            rsp_delay_counter <= RspDelayCounter;
            return;
        end
    end

    assert_state( cpu_req_address, plan_line[31:16], "Address bus" );
    assert_state( cpu_req_write, !plan_line[0], "Read/write" );
    assert_state( cpu_sync, plan_line[1], "Sync" );
    //assert_state( vector_pull, !plan_line[3], "Vector pull" );

    if( cpu_req_write ) begin
        // Write
        memory[cpu_req_address] <= cpu_req_data;
        assert_state( cpu_req_data, plan_line[15:8], "Data out" );

        if( cpu_req_address[15:8]==8'h02 )
            perform_io();
    end else begin
        // Read
        //if( !incompatible )
        assert_state( memory[cpu_req_address], plan_line[15:8], "Data in" );

        assert_state( rsp_delay_counter, 0, "Request arrives while a response is pending" );
        rsp_data <= memory[cpu_req_address];
        rsp_delay_counter <= RspDelayCounter;
    end

    cycle_num <= cycle_num+1;
endtask

task assert_state( input logic [15:0]actual, input logic [15:0]expected, input string name );
    if( actual === expected )
        return;

    $display("Verification failed on cycle %d time %t pin %s: expected %x, received %x on address %04x",
        cycle_num+1, $time, name, expected, actual, cpu_req_address);
    $finish();
endtask

task perform_io();
    $display("Cycle %d: IO writing %x to %x", cycle_num+1, cpu_req_data, cpu_req_address);

    casex( cpu_req_address[7:0] )
        8'h00: begin
            $display("Test finished successfully cycle %d", cycle_num+1);
            $finish();
        end
        8'h81: begin pending_signals[SigReady].delay <= cpu_req_data; pending_signals[SigReady].count <= memory[16'h0280]; end
        8'h83: begin pending_signals[SigSo].delay <= cpu_req_data; pending_signals[SigSo].count <= memory[16'h0282]; end
        8'hfb: begin pending_signals[SigNmi].delay <= cpu_req_data; pending_signals[SigNmi].count <= memory[16'h02fa]; end
        8'hfd: begin pending_signals[SigReset].delay <= cpu_req_data; pending_signals[SigReset].count <= memory[16'h02fc]; end
        8'hff: begin pending_signals[SigIrq].delay <= cpu_req_data; pending_signals[SigIrq].count <= memory[16'h02fe]; end
    endcase
endtask

endmodule
