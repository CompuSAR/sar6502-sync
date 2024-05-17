`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/17/2024 02:21:52 PM
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
localparam MaxCyclesPerBus=3;   // Maximum number of clock cycles between bus operations

logic clock;
logic [7:0] memory[65535:0];
logic [35:0]test_plan[30000];

logic cpu_req_valid, cpu_req_write, cpu_req_ack = 1'b1, cpu_rsp_valid = 1'b0;
logic [7:0] cpu_req_data, cpu_rsp_data = 8'hXX;
logic [15:0] cpu_req_address;

logic cpu_reset = 1'b0, cpu_nmi = 1'b0, cpu_irq = 1'b0, cpu_set_overflow = 1'b0;

sar6502_2#(.CPU_VARIANT(CPU_VARIANT))
cpu(
    .clock_i(clock),

    .reset_i(cpu_reset),
    .nmi_i(cpu_nmi),
    .irq_i(cpu_irq),
    .set_overflow_i(cpu_set_overflow),

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

/*
struct {
    int delay;
    int count;
} pending_signals[Sig_NumElements-1:0];
*/

initial forever begin
    clock = 1'b0;
    #tPWL
    clock = 1'b1;
    #tPWH
    ;
end

int cycles_since_bus = 0;
int cycle_num = 0;

always_ff@(posedge clock) begin
    if( cycles_since_bus==MaxCyclesPerBus ) begin
        $display("Too many cycles since last bus operation on cycle %d time %t", cycle_num, $time);
        $finish();
    end

    cycles_since_bus <= cycles_since_bus+1;

    cpu_rsp_valid <= 1'b0;
    cpu_rsp_data <= 8'hXX;

    if( cpu_req_valid && cpu_req_ack ) begin
        cycles_since_bus <= 0;

        handle_bus_op();
    end
end

wire [35:0] plan_line = test_plan[cycle_num];

task handle_bus_op();
    if( cycle_num==0 && cpu_req_address!=16'hfffc ) begin
        $display("Pre-test cycle %s address %04x data %02x time %t", cpu_req_write ? "write" : "read", cpu_req_address, cpu_req_data, $time);

        return;
    end

    assert_state( cpu_req_address, plan_line[31:16], "Address bus" );
    assert_state( cpu_req_write, plan_line[0], "Read/write" );
    //assert_state( sync, plan_line[1], "Sync" );
    //assert_state( vector_pull, !plan_line[3], "Vector pull" );

    if( cpu_req_write ) begin
        // Write
        memory[cpu_req_address] <= cpu_req_data;
        assert_state( cpu_req_data, plan_line[15:8], "Data out" );
    end else begin
        // Read
        //if( !incompatible )
            assert_state( memory[cpu_req_address], plan_line[15:8], "Data in" );

        cpu_rsp_valid <= 1'b1;
        cpu_rsp_data <= memory[cpu_req_address];
    end

    cycle_num <= cycle_num+1;
endtask

task assert_state( input logic [15:0]actual, input logic [15:0]expected, input string name );
    if( actual === expected )
        return;

    $display("Verification failed on cycle %d time %t pin %s: expected %x, received %x on address %04x",
        cycle_num, $time, name, expected, actual, cpu_req_address);
    $finish();
endtask

endmodule
