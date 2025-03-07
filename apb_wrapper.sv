`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.03.2025 17:28:55
// Design Name: 
// Module Name: apb_wrapper
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


module apb_wrapper#(parameter addr_width = 5, data_width = 16)(
    input bit pclk,                  // APB clock signal (rising edge triggered)
    input bit preset_n,              // Active-low reset signal (resets FSM to idle)
    //input logic pready,              // Slave ready signal: indicates when the slave is ready for data transfer
    input logic transfer,  
    input logic [addr_width - 1 : 0] apb_paddr, // Address input from the higher-level interface
    input logic [data_width - 1 : 0] apb_pwdata, // Write data input from the higher-level interface
    input logic apb_control ,        // Control signal: 1 for write, 0 for read transactions  
    output logic [data_width - 1 : 0] apb_spwdata,   
    output logic [data_width - 1 : 0] apb_prdata // Data captured from the APB slave during read transactions  
    );
    logic [addr_width-1:0] paddr;
    logic pselx;
    bit penable;
    logic pwrite;
    logic [data_width-1:0] pwdata;
    logic [data_width/8-1:0] pstrb; 
    logic                    pready;
    logic [data_width -1:0]  prdata;
    
    
    apb_master #(.addr_width(addr_width), .data_width(data_width)) DUT (
        .pclk(pclk),
        .preset_n(preset_n),
        .pready(pready),
        .transfer(transfer),
        .prdata(prdata),
        .apb_paddr(apb_paddr),
        .apb_pwdata(apb_pwdata),
        .apb_control(apb_control),
        .paddr(paddr),
        .pselx(pselx),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .pstrb(pstrb),
        .apb_prdata(apb_prdata)
    );
     apb_slave #(
        .addr_width(addr_width),
        .data_width(data_width)
    ) dut (
        .pclk       (pclk),
        .preset_n   (preset_n),
        .pselx      (pselx),
        .penable    (penable),
        .pwrite     (pwrite),
        .paddr      (paddr),
        .pwdata     (pwdata),
        .apb_spwdata(apb_spwdata),
        .prdata     (prdata),
        .pready     (pready)
    );
endmodule
