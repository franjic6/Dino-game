`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:33:12 06/13/2025 
// Design Name: 
// Module Name:    vga_sync 
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
module vga_sync(
    input clk,
    output reg hsync,
    output reg vsync,
    output [9:0] x,
    output [9:0] y,
    output active
);

// Horizontalni parametri
parameter HD = 640;  // Vidljivi horizontalni pikseli
parameter HF = 16;   // Horizontalni front porch
parameter HB = 48;   // Horizontalni back porch
parameter HR = 96;   // Horizontalni retrace
parameter HT = HD + HF + HB + HR; // Ukupni horizontalni taktovi

// Vertikalni parametri
parameter VD = 480;  // Vidljivi vertikalni linije
parameter VF = 10;    // Vertikalni front porch
parameter VB = 33;    // Vertikalni back porch
parameter VR = 2;     // Vertikalni retrace
parameter VT = VD + VF + VB + VR; // Ukupni vertikalni taktovi

// Registri za brojanje
reg [9:0] h_counter = 0;
reg [9:0] v_counter = 0;

// Generiranje horizontalnog brojaèa
always @(posedge clk) begin
    if(h_counter == HT-1) begin
        h_counter <= 0;
        if(v_counter == VT-1)
            v_counter <= 0;
        else
            v_counter <= v_counter + 1;
    end
    else
        h_counter <= h_counter + 1;
end

// Horizontalna sinhronizacija
always @* begin
    hsync = ~((h_counter >= HD + HF) && (h_counter < HD + HF + HR));
end

// Vertikalna sinhronizacija
always @* begin
    vsync = ~((v_counter >= VD + VF) && (v_counter < VD + VF + VR));
end

// Aktivno podruèje prikaza
assign active = (h_counter < HD) && (v_counter < VD);

// Izlazne pozicije piksela
assign x = (active) ? h_counter : 10'hX;
assign y = (active) ? v_counter : 10'hX;

endmodule

