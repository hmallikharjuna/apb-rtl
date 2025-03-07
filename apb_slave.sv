`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.03.2025 23:16:31
// Design Name: 
// Module Name: apb_slave
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


module apb_slave#(
    parameter addr_width = 5,
    parameter data_width = 16
)(
    input  logic pclk,
    input  logic preset_n,
    input  logic pselx,
    input  logic penable,
    input  logic pwrite,
    input  logic [addr_width - 1 : 0] paddr,
    input  logic [data_width - 1 : 0] pwdata,
    output logic [data_width - 1 : 0] apb_spwdata,
    output logic [data_width - 1 : 0] prdata,
    output logic pready
);
    
    logic [data_width-1:0] mem [0:2**addr_width]; 

    // State Definitions
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        SETUP = 2'b01,
        ACCESS = 2'b10
    } state_t;

    state_t present_state, next_state;

    // State Transition
    always_ff @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            present_state <= IDLE;
        else
            present_state <= next_state;
    end 

    // Next State Logic
    always_comb begin
        case (present_state)
            IDLE: begin
                if (pselx && !penable) // Setup phase detected
                    next_state = SETUP;
                else
                    next_state = IDLE;
            end
            SETUP: begin
                if (pselx && penable) // Move to Access phase
                    next_state = ACCESS;
                else
                    next_state = IDLE;
            end
            ACCESS: begin
                if (!pselx) // Transaction complete, go back to IDLE
                    next_state = IDLE;
                else
                    next_state = SETUP; // If `PSEL` remains high, go back to SETUP
            end
            default: next_state = IDLE;
        endcase
    end

    // Output Logic
    always_ff @(posedge pclk or negedge preset_n) begin
        if (!preset_n)
            pready <= 1'b0;
        else if (present_state == ACCESS)
            pready <= 1'b1;
        else
            pready <= 1'b0;
    end

    always_ff @(posedge pclk) begin
//   if (!preset_n) begin
//        for (int i = 0; i < 256; i = i + 1) // Initialize memory
//            mem[i] <= 16'h0000;
//    end
       if (pready && pwrite) begin
            mem[paddr] <= pwdata;
            apb_spwdata <= pwdata;
        end
    end

    always_ff @(posedge pclk) begin
        if (pready && !pwrite)
            prdata <= mem[paddr];
    end

endmodule

