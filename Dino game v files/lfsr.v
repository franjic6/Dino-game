`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:09:02 06/18/2025 
// Design Name: 
// Module Name:    lfsr 
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
module lfsr8(
    input wire clk,
    input wire rst,
    output reg [7:0] rnd
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            rnd <= 8'h1; // ne smije biti 0
        else
            rnd <= {rnd[6:0], rnd[7] ^ rnd[5] ^ rnd[4] ^ rnd[3]};
    end
endmodule

