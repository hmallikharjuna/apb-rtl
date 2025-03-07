`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.03.2025 12:22:13
// Design Name: 
// Module Name: tb_apb_slave
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
module tb_apb_slave();
    parameter ADDR_WIDTH = 8;
    parameter DATA_WIDTH = 16;

    // Testbench signals
    logic pclk;
    logic preset_n;
    logic pselx;
    logic penable;
    logic pwrite;
    logic [ADDR_WIDTH-1:0]  paddr;
    logic [DATA_WIDTH-1:0]  pwdata;
    wire  [DATA_WIDTH-1:0]  apb_spwdata;
    wire  [DATA_WIDTH-1:0]  prdata;
    wire                    pready;

    // Declare read_data at the module level
    logic [DATA_WIDTH-1:0] read_data;

    // Instantiate DUT
    apb_slave #(
        .addr_width(ADDR_WIDTH),
        .data_width(DATA_WIDTH)
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

    //-------------------------------------------------------------------------
    // 1) CLOCK GENERATION (1 MHz clock: period = 1000 ns, toggle every 500 ns)
    //-------------------------------------------------------------------------
    initial begin
        pclk = 0;
        forever #500 pclk = ~pclk;
    end

    //-------------------------------------------------------------------------
    // 2) RESET GENERATION
    //-------------------------------------------------------------------------
    initial begin
        preset_n = 0;
        #1000;           // Hold reset for 1000 ns
        preset_n = 1;    // Deassert reset
    end

    //-------------------------------------------------------------------------
    // 3) INITIALIZE CONTROL SIGNALS
    //-------------------------------------------------------------------------
    initial begin
        pselx   = 0;
        penable = 0;
        pwrite  = 0;
        paddr   = '0;
        pwdata  = '0;
    end

    //-------------------------------------------------------------------------
    // 4) APB WRITE TASK
    //-------------------------------------------------------------------------
    task apb_write(
        input [ADDR_WIDTH-1:0]  addr,
        input [DATA_WIDTH-1:0]  data
    );
    begin
        // Setup phase
        @(posedge pclk);
        pselx   <= 1;
        penable <= 0;
        pwrite  <= 1;
        paddr   <= addr;
        pwdata  <= data;

        // Access phase
        @(posedge pclk);
        penable <= 1;

        // Wait for pready (if needed)
        @(posedge pclk);
        while (!pready) @(posedge pclk);

        // Return to IDLE
        pselx   <= 0;
        penable <= 0;
        pwrite  <= 0;
    end
    endtask

    //-------------------------------------------------------------------------
    // 5) APB READ TASK
    //-------------------------------------------------------------------------
    task apb_read(
        input  [ADDR_WIDTH-1:0]  addr,
        output [DATA_WIDTH-1:0]  data
    );
    begin
        // Setup phase
        @(posedge pclk);
        pselx   <= 1;
        penable <= 0;
        pwrite  <= 0;
        paddr   <= addr;

        // Access phase
        @(posedge pclk);
        penable <= 1;

        // Wait for pready
        @(posedge pclk);
        while (!pready) @(posedge pclk);

        // Capture read data
        data = prdata;

        // Return to IDLE
        pselx   <= 0;
        penable <= 0;
    end
    endtask

    //-------------------------------------------------------------------------
    // 6) TEST SEQUENCE
    //-------------------------------------------------------------------------
    initial begin
        // Wait until reset is deasserted
        wait(preset_n == 1);
        @(posedge pclk);

        // Example: Write 0xABCD to address 0x10
        apb_write(8'h10, 16'hABCD);

        // Example: Write 0x1234 to address 0x20
        apb_write(8'h20, 16'h1234);

        // Example: Read from address 0x10
        apb_read(8'h10, read_data);
        $display($time, " Read from 0x10 = 0x%h", read_data);

        // Example: Read from address 0x20
        apb_read(8'h20, read_data);
        $display($time, " Read from 0x20 = 0x%h", read_data);

        // Example: Write 0xDEAD to address 0x30 and read back
        apb_write(8'h30, 16'hDEAD);
        apb_read(8'h30, read_data);
        $display($time, " Read from 0x30 = 0x%h", read_data);

        // Wait a few cycles then finish simulation
        #2000;
        $finish;
    end

endmodule

