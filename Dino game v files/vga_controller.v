`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:43:45 06/16/2025 
// Design Name: 
// Module Name:    vga_controller 
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
// vga_controller.v
module vga_controller(
    input wire clk25,        // 25 MHz clock
    output reg vga_hsync,
    output reg vga_vsync,
    output wire [9:0] h_count,
    output wire [9:0] v_count,
    output wire display_on
);
    // Horizontal timing parametri (640x480@60Hz)
    parameter H_DISPLAY = 640;
    parameter H_FRONT = 16;
    parameter H_SYNC = 96;
    parameter H_BACK = 48;
    parameter H_TOTAL = 800;
    
    // Vertikalni timing parametri
    parameter V_DISPLAY = 480;
    parameter V_FRONT = 10;
    parameter V_SYNC = 2;
    parameter V_BACK = 33;
    parameter V_TOTAL = 525;

    reg [9:0] h_counter = 0;
    reg [9:0] v_counter = 0;

    // Horizontalni brojaè
    always @(posedge clk25) begin
        if(h_counter == H_TOTAL - 1) begin
            h_counter <= 0;
            if(v_counter == V_TOTAL - 1)
                v_counter <= 0;
            else
                v_counter <= v_counter + 1;
        end else begin
            h_counter <= h_counter + 1;
        end
    end

    // Horizontal sync logika
    always @(*) begin
        vga_hsync = (h_counter >= H_DISPLAY + H_FRONT) && 
                   (h_counter < H_DISPLAY + H_FRONT + H_SYNC);
    end

    // Vertikalni sync logika
    always @(*) begin
        vga_vsync = (v_counter >= V_DISPLAY + V_FRONT) && 
                   (v_counter < V_DISPLAY + V_FRONT + V_SYNC);
    end

    // Display enable signal
    assign display_on = (h_counter < H_DISPLAY) && 
                       (v_counter < V_DISPLAY);

    assign h_count = (h_counter < H_DISPLAY) ? h_counter : 10'h0;
    assign v_count = (v_counter < V_DISPLAY) ? v_counter : 10'h0;

endmodule
