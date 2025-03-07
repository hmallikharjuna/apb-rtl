`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.03.2025 18:00:47
// Design Name: 
// Module Name: tb_apb_wrapper
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


module tb_apb_wrapper(

    );
     parameter ADDR_WIDTH = 5;
    parameter DATA_WIDTH = 16;
    
    // Testbench signals
    logic                   pclk;
    logic                   preset_n;
    logic                   transfer;
    logic [ADDR_WIDTH-1:0]  apb_paddr;
    logic [DATA_WIDTH-1:0]  apb_pwdata;
    logic                   apb_control;  // 1: write, 0: read
    wire [DATA_WIDTH-1:0]   apb_spwdata;
    wire [DATA_WIDTH-1:0]   apb_prdata;
    
    apb_wrapper  #(
        .addr_width(ADDR_WIDTH),
        .data_width(DATA_WIDTH)
    ) dut (.*);
    always #5 pclk =~pclk;
    //always #1000 preset_n=~preset_n;
    always #20 apb_paddr=apb_paddr+1;
    always #20 apb_pwdata=$urandom % 2**DATA_WIDTH;
    always #1200 apb_control=~apb_control;
    always #3000 transfer =~transfer;
    initial begin
    #0 preset_n ='b0;
    #100 preset_n='b1;
    end
    initial begin 
    pclk='b0;
    transfer='b1;
    apb_paddr='h0;
    apb_control='b1;
    apb_pwdata='b0;
    end
    initial begin
    
    #8000 $finish();
    end
endmodule
