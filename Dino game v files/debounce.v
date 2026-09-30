`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:24:41 06/16/2025 
// Design Name: 
// Module Name:    debounce 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module debounce #(
    parameter DEBOUNCE_CYCLES = 16,      // Koliko ciklusa mora biti stabilan signal
    parameter COUNTER_WIDTH = 4          // Širina brojaèa (log2(DEBOUNCE_CYCLES))
)(
    input wire clk,
    input wire btn_in,
    output reg btn_out
);

    reg [COUNTER_WIDTH-1:0] cnt = 0;
    reg btn_sync = 0;

    always @(posedge clk) begin
        btn_sync <= btn_in;  // Sinkronizacija na clock domenu

        if (btn_sync != btn_out) begin
            cnt <= cnt + 1;
            if (cnt == DEBOUNCE_CYCLES-1) begin
                btn_out <= btn_sync;
                cnt <= 0;
            end
        end else begin
            cnt <= 0;
        end
    end

endmodule




