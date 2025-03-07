`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.03.2025 21:40:30
// Design Name: 
// Module Name: apb_master
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



module apb_master#(parameter addr_width =5 , data_width = 16) (
    input bit pclk,                  // APB clock signal (rising edge triggered)
    input bit preset_n,              // Active-low reset signal (resets FSM to idle)
    input logic pready,              // Slave ready signal: indicates when the slave is ready for data transfer
    input logic transfer,            // Transfer request signal from the higher-level interface
    input logic [data_width - 1 : 0] prdata, // Data read from the slave during read operations
    //input bit pslverr,             // Slave error signal (unused here; commented out as good practice)
    input logic [addr_width - 1 : 0] apb_paddr, // Address input from the higher-level interface
    input logic [data_width - 1 : 0] apb_pwdata, // Write data input from the higher-level interface
    input logic apb_control,         // Control signal: 1 for write, 0 for read transactions
    output logic [addr_width - 1 : 0] paddr, // Address output driven to the APB slave
    output logic pselx,              // Slave select signal (active high)
    output bit penable,              // APB enable signal: asserted during access state to latch data
    output logic pwrite,             // Write control signal (assigned from apb_control)
    output logic [data_width - 1 : 0] pwdata, // Write data output to the APB slave (used only for write transactions)
    output logic [data_width / 8 - 1 : 0] pstrb, // Byte strobe signals for write transactions (one bit per byte)
    output logic [data_width - 1 : 0] apb_prdata // Data captured from the APB slave during read transactions
);

//-----------------------------------------------------------------------------
// Local Parameter Definitions for FSM States
//-----------------------------------------------------------------------------
localparam logic [2:0] idle   = 3'b001; // Idle state: no transaction in progress
localparam logic [2:0] setup  = 3'b010; // Setup state: address and control signals are set up
localparam logic [2:0] access = 3'b100; // Access state: data transfer (read or write) occurs

logic [2:0] present_state, next_state;  // FSM state registers
logic [data_width - 1 : 0] temp_apb_prdata;
//-----------------------------------------------------------------------------
// State Register: Updates current state on clock's rising edge or reset
//-----------------------------------------------------------------------------
always_ff @(posedge pclk, negedge preset_n) begin
    if (!preset_n)
        present_state <= idle;      // Reset to idle state when preset_n is low
    else
        present_state <= next_state; // Update state based on next_state logic
end

//-----------------------------------------------------------------------------
// Next-State Logic: Determines the next state based on current state and inputs
//-----------------------------------------------------------------------------
always_comb begin
    case (present_state)
        idle: begin
            // In idle state, if a transfer is requested, move to setup
            if (transfer) begin
                next_state = setup;
            end else begin
                next_state = idle;
            end
        end

        setup: begin
            // In setup state, if transfer remains asserted, transition to access state
            if (transfer) begin 
                next_state = access;
            end else begin
                next_state = idle;
            end
        end

        access: begin
            // In access state, wait until the slave indicates readiness (pready high)
            // Once ready, complete the transaction and return to idle
            if (pready == 'b1) begin
                next_state = idle;
            end else begin
                next_state = access; // Remain in access if slave is not ready
            end
        end

        default: next_state = idle;  // Default state safety: revert to idle
    endcase
end

//-----------------------------------------------------------------------------
// Output Logic for pselx and penable based on the current state
//-----------------------------------------------------------------------------
always_comb begin
    case (present_state)
        idle: begin
            pselx   = 'b0;  // No slave is selected in idle state
            penable = 'b0;  // APB enable signal is deasserted in idle state
        end
        setup: begin
            pselx   = 'b1;  // Select the slave during setup state
            penable = 'b0;  // Keep enable deasserted during setup (address setup phase)
        end
        access: begin
            pselx   = 'b1;  // Slave remains selected in access state
            penable = 'b1;  // Assert enable signal to perform data transfer
        end
        default: begin
            pselx   = 'b0;
            penable = 'b0;
        end
    endcase
end           

//-----------------------------------------------------------------------------
// Output Logic for paddr and pwdata: Drive address and write data during transaction
//-----------------------------------------------------------------------------
always_comb begin
    if ((present_state == setup) || (present_state == access)) begin
        paddr = apb_paddr; // Drive the address to the slave in both setup and access states
        if (apb_control) begin // Write transaction: drive write data from input
            pwdata = apb_pwdata;
        end else begin // Read transaction: no write data is sent
            pwdata = 'b0;
        end
    end else begin // In idle state, clear address and write data outputs
        paddr = 'b0;
        pwdata = 'b0;
    end
end

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Read Data Capture: Latch data from the slave during a read transaction
//-----------------------------------------------------------------------------
always_ff @(posedge pclk, negedge preset_n) begin
    if (!preset_n) begin
        temp_apb_prdata <= '0;
    end else if (pready && !apb_control) begin
        temp_apb_prdata <= prdata;
    end
end


//-----------------------------------------------------------------------------
// pstrb Generation: Generate byte strobe signals during write transactions
//-----------------------------------------------------------------------------
always_comb begin
    if (pwrite && pselx && penable) begin
        // When performing a write transaction, assert strobe for each byte lane
        pstrb = {data_width / 8 {1'b1}};
    end else begin
        pstrb = 'b0; // Otherwise, deassert byte strobe signals
    end
end

//-----------------------------------------------------------------------------
// pwrite Signal Assignment: Directly assign from apb_control (1 for write, 0 for read)
//-----------------------------------------------------------------------------
assign pwrite = apb_control;
assign apb_prdata=temp_apb_prdata;
endmodule
        

