`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.03.2025 22:02:07
// Design Name: 
// Module Name: tb_apb_master
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




`timescale 1ns/1ps

module tb_apb_master;

    // Parameters
    parameter ADDR_WIDTH = 8;
    parameter DATA_WIDTH = 16;

    // Testbench signals
    logic pclk;
    logic preset_n;
    logic pready;
    logic transfer;
    logic [ADDR_WIDTH-1:0] apb_paddr;
    logic [DATA_WIDTH-1:0] apb_pwdata;
    logic [DATA_WIDTH-1:0] prdata;
    logic apb_control;
    
    // DUT outputs
    logic [ADDR_WIDTH-1:0] paddr;
    logic pselx;
    bit penable;
    logic pwrite;
    logic [DATA_WIDTH-1:0] pwdata;
    logic [DATA_WIDTH/8-1:0] pstrb;
    logic [DATA_WIDTH-1:0] apb_prdata;

    // Instantiate the DUT (Device Under Test)
    apb_master #(.addr_width(ADDR_WIDTH), .data_width(DATA_WIDTH)) DUT (
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

    // Clock Generation (50MHz = 20ns period)
    always #10 pclk = ~pclk;

    // Task to perform a write transaction
    task apb_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            $display("Starting Write Transaction: ADDR = %h, DATA = %h at time %0t", addr, data, $time);
            transfer = 1;
            apb_paddr = addr;
            apb_pwdata = data;
            apb_control = 1; // Write operation
            #20;
            pready = 1; // Slave ready
            #20;
            pready = 0;
            transfer = 0;
            #40;
            $display("Completed Write Transaction: ADDR = %h, DATA = %h at time %0t", addr, data, $time);
        end
    endtask

    // Task to perform a read transaction
    task apb_read(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] expected_data);
        begin
            $display("Starting Read Transaction: ADDR = %h, Expected DATA = %h at time %0t", addr, expected_data, $time);
            transfer = 1;
            apb_paddr = addr;
            apb_control = 0; // Read operation
            prdata = expected_data;
            #20;
            pready = 1; // Slave ready
            #20;
            pready = 0;
            transfer = 0;
            #40;

            // Check read data after transaction completion
            if (apb_prdata == expected_data) begin
                $display("Read SUCCESS: ADDR = %h, Received DATA = %h at time %0t", addr, apb_prdata, $time);
            end else begin
                $display("Read ERROR: ADDR = %h, Expected = %h, Received = %h at time %0t", addr, expected_data, apb_prdata, $time);
            end
        end
    endtask

    // Test Sequence
    initial begin
        // Initialize signals
        pclk = 0;
        preset_n = 0;
        pready = 0;
        transfer = 0;
        apb_paddr = 0;
        apb_pwdata = 0;
        prdata = 0;
        apb_control = 0;

        // Apply Reset
        #25 preset_n = 1;
        $display("Reset Released at time %0t", $time);

        // Perform multiple write transactions
        apb_write(8'h10, 16'hAAAA);
        apb_write(8'h20, 16'hBBBB);
        apb_write(8'h30, 16'hCCCC);
        apb_write(8'h40, 16'hDDDD);

        // Perform multiple read transactions
        apb_read(8'h10, 16'hAAAA);
        apb_read(8'h20, 16'hBBBB);
        apb_read(8'h30, 16'hCCCC);
        apb_read(8'h40, 16'hDDDD);

        // Introduce delayed pready responses
        transfer = 1;
        apb_paddr = 8'h50;
        apb_control = 1;
        apb_pwdata = 16'hEEEE;
        #20;
        pready = 0; // Slave not ready
        #40;
        pready = 1; // Now slave is ready
        #20;
        pready = 0;
        transfer = 0;
        #40;

        // Another delayed read
        transfer = 1;
        apb_paddr = 8'h60;
        apb_control = 0;
        prdata = 16'hFFFF;
        #20;
        pready = 0; // Slave not ready
        #40;
        pready = 1; // Now slave is ready
        #20;
        pready = 0;
        transfer = 0;
        #40;

        // Run the test for 2000ns
        #1200;

        // End simulation
        $finish;
    end

    // Monitor DUT signals
    initial begin
        $monitor("Time: %0t | State: %b | PADDR: %h | PWDATA: %h | PRDATA: %h | PWRITE: %b | PSELX: %b | PENABLE: %b", 
                 $time, DUT.present_state, paddr, pwdata, apb_prdata, pwrite, pselx, penable);
    end

endmodule
