`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/14/2024 06:35:08 PM
// Design Name: 
// Module Name: wdc_top
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


module wdc_top(

    );

simulation_top#( .CPU_VARIANT(2), .MEMORY_FILE("test_program_wdc.mem"), .TEST_PLAN_FILE("test_plan_wdc.mem") ) top();

endmodule
