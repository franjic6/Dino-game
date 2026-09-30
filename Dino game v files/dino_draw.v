	`timescale 1ns / 1ps
	//////////////////////////////////////////////////////////////////////////////////
	// Company: 
	// Engineer: 
	// 
	// Create Date:    16:44:36 06/16/2025 
	// Design Name: 
	// Module Name:    dino_draw 
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

	module dino_draw(
		 input wire [9:0]  h_counter,
		 input wire [9:0]  v_counter,
		 input wire [9:0]  dino_y_pos,
		 input wire [10:0] cactus_x,
		 input wire [9:0]  bird_x,
		 input wire [9:0]  bird_y,
		 input wire [9:0]  cloud_x,
		 input wire [9:0]  cloud2_x,
		 input wire [3:0]  thousands,
		 input wire [3:0]  hundreds,
		 input wire [3:0]  tens,
		 input wire [3:0]  units,
		 input wire [3:0]  hs_thousands,
		 input wire [3:0]  hs_hundreds,
		 input wire [3:0]  hs_tens,
		 input wire [3:0]  hs_units,
		 input wire [7:0]  ground_offset,
		 input wire        start_button,
		 input wire        display_area,
		 input wire        is_ducking,
		 input wire        collision,
		 input wire [1:0]  sprite_ver,
		 input wire        clk25,
		 output wire       VGA_R,
		 output wire       VGA_G,
		 output wire       VGA_B
	);

	// -----------------------------------------------------------------------------
	// Parametri i konstante
	// -----------------------------------------------------------------------------
	parameter DINO_X        = 200;
	parameter DINO_W        = 48;    
	parameter DINO_H        = 48;    
	parameter GROUND_Y      = 350;

	parameter CACTUS_W      = 38;
	parameter CACTUS_H      = 48;
	parameter CACTUS_START_X= 640; 

	parameter BIRD_W        = 36;
	parameter BIRD_H        = 16;
	parameter BIRD_START_X  = 640;
	parameter BIRD_Y        = GROUND_Y - BIRD_H - 50; 

	parameter SCORE_X       = 550;  
	parameter SCORE_Y       = 30;   
	parameter DIGIT_W       = 8;    
	parameter DIGIT_H       = 16;   
	parameter SCORE_X_HS    = 88;
	parameter SCORE_Y_HS    = 30;

	parameter GAME_OVER_X   = 270;
	parameter GAME_OVER_Y   = 232;
	parameter GAME_OVER_W   = 96;
	parameter GAME_OVER_H   = 16;

	parameter HS_SPRITE_X   = 58;
	parameter HS_SPRITE_Y   = 30;
	parameter HS_SPRITE_W   = 20;
	parameter HS_SPRITE_H   = 16;

	parameter CLOUD_W       = 36;
	parameter CLOUD_H       = 16;
	
	reg [255:0] GROUND_PATTERN [0:9];
	initial begin
		 GROUND_PATTERN[0] = 256'b1111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111;
		 GROUND_PATTERN[1] = 256'b0000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000;
		 GROUND_PATTERN[2] = 256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000;
		 GROUND_PATTERN[3] = 256'b0001100000000000000000000000000000000000000000000000000000000000000000000011000000000000000001000000000000010000000000000000001110000000000000000000000000000000000000000000000000000011000000000001000000000000000000000000000000000000000000000000000000110000;
		 GROUND_PATTERN[4] = 256'b0000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000011100000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000;
		 GROUND_PATTERN[5] = 256'b0000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110000000000000000;
		 GROUND_PATTERN[6] = 256'b0000000000000000000000000000011000000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
		 GROUND_PATTERN[7] = 256'b0001100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000111000000000000000000000000000000000000000000000000000001100000000000100000000000000000000000000000000000000000000000000000000000;
		 GROUND_PATTERN[8] = 256'b0000111000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000001110000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000110000000000000000000000000000000000001110000000000000000;
		 GROUND_PATTERN[9] = 256'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000;
	end


	wire score_pixel_0, score_pixel_1, score_pixel_2, score_pixel_3;
	wire score_pixel = score_pixel_0 | score_pixel_1 | score_pixel_2 | score_pixel_3;

	wire hs_score_pixel_0, hs_score_pixel_1, hs_score_pixel_2, hs_score_pixel_3;
	wire hs_score_pixel = hs_score_pixel_3 | hs_score_pixel_2 | hs_score_pixel_1 | hs_score_pixel_0;

	digit_draw digit0(
		 .h_pos(h_counter - SCORE_X),
		 .v_pos(v_counter - SCORE_Y),
		 .digit(thousands),
		 .pixel(score_pixel_0)
	);

	digit_draw digit1(
		 .h_pos(h_counter - (SCORE_X + DIGIT_W)),
		 .v_pos(v_counter - SCORE_Y),
		 .digit(hundreds),
		 .pixel(score_pixel_1)
	);

	digit_draw digit2(
		 .h_pos(h_counter - (SCORE_X + 2*DIGIT_W)),
		 .v_pos(v_counter - SCORE_Y),
		 .digit(tens),
		 .pixel(score_pixel_2)
	);

	digit_draw digit3(
		 .h_pos(h_counter - (SCORE_X + 3*DIGIT_W)),
		 .v_pos(v_counter - SCORE_Y),
		 .digit(units),
		 .pixel(score_pixel_3)
	);

	digit_draw hs_digit0(
		 .h_pos(h_counter - SCORE_X_HS),
		 .v_pos(v_counter - SCORE_Y_HS),
		 .digit(hs_thousands),
		 .pixel(hs_score_pixel_0)
	);

	digit_draw hs_digit1(
		 .h_pos(h_counter - (SCORE_X_HS + DIGIT_W)),
		 .v_pos(v_counter - SCORE_Y_HS),
		 .digit(hs_hundreds),
		 .pixel(hs_score_pixel_1)
	);

	digit_draw hs_digit2(
		 .h_pos(h_counter - (SCORE_X_HS + 2*DIGIT_W)),
		 .v_pos(v_counter - SCORE_Y_HS),
		 .digit(hs_tens),
		 .pixel(hs_score_pixel_2)
	);

	digit_draw hs_digit3(
		 .h_pos(h_counter - (SCORE_X_HS + 3*DIGIT_W)),
		 .v_pos(v_counter - SCORE_Y_HS),
		 .digit(hs_units),
		 .pixel(hs_score_pixel_3)
	);

	reg [23:0] dino_sprite [0:23];
	initial begin
        dino_sprite[0]  = 24'b000000000000000000000000;
		  dino_sprite[1]  = 24'b000000000000000111111110;
		  dino_sprite[2]  = 24'b000000000000001111111111;
		  dino_sprite[3]  = 24'b000000000000001110111111;
		  dino_sprite[4]  = 24'b000000000000001111111111;
		  dino_sprite[5]  = 24'b000000000000001111111111;
		  dino_sprite[6]  = 24'b000000000000001111100000;
		  dino_sprite[7]  = 24'b000000000000001111111110;
		  dino_sprite[8]  = 24'b100000000000011111110000;
		  dino_sprite[9]  = 24'b100000000000111111110000;
		  dino_sprite[10] = 24'b111000000011111111111100;
		  dino_sprite[11] = 24'b111111000111111111110100;
		  dino_sprite[12] = 24'b011111111111111111110100;
		  dino_sprite[13] = 24'b000111111111111111110000;
		  dino_sprite[14] = 24'b000001111111111111100000;
		  dino_sprite[15] = 24'b000001111111111111000000;
		  dino_sprite[16] = 24'b000000111111111111000000;
		  dino_sprite[17] = 24'b000000011111111110000000;
		  dino_sprite[18] = 24'b000000001111111100000000;
		  dino_sprite[19] = 24'b000000000111111100000000;
		  dino_sprite[20] = 24'b000000000111011100000000;
		  dino_sprite[21] = 24'b000000000110001100000000;
		  dino_sprite[22] = 24'b000000000100000100000000;
		  dino_sprite[23] = 24'b000000000110000110000000;
	end
	
	reg [23:0] dino_sprite2 [0:23];
	initial begin
        dino_sprite2[0]  = 24'b000000000000000000000000;
		  dino_sprite2[1]  = 24'b000000000000000111111110;
		  dino_sprite2[2]  = 24'b000000000000001111111111;
		  dino_sprite2[3]  = 24'b000000000000001110111111;
		  dino_sprite2[4]  = 24'b000000000000001111111111;
		  dino_sprite2[5]  = 24'b000000000000001111111111;
		  dino_sprite2[6]  = 24'b000000000000001111100000;
		  dino_sprite2[7]  = 24'b000000000000001111111110;
		  dino_sprite2[8]  = 24'b100000000000011111110000;
		  dino_sprite2[9]  = 24'b100000000000111111110000;
		  dino_sprite2[10] = 24'b111000000011111111111100;
		  dino_sprite2[11] = 24'b111111000111111111110100;
		  dino_sprite2[12] = 24'b011111111111111111110100;
		  dino_sprite2[13] = 24'b000111111111111111110000;
		  dino_sprite2[14] = 24'b000001111111111111100000;
		  dino_sprite2[15] = 24'b000001111111111111000000;
		  dino_sprite2[16] = 24'b000000111111111111000000;
		  dino_sprite2[17] = 24'b000000011111111110000000;
		  dino_sprite2[18] = 24'b000000001111111100000000;
		  dino_sprite2[19] = 24'b000000000111111100000000;
		  dino_sprite2[20] = 24'b000000000111011100000000;
		  dino_sprite2[21] = 24'b000000000110001100000000;
		  dino_sprite2[22] = 24'b000000000100000111000000;
		  dino_sprite2[23] = 24'b000000000110000000000000;
	end
	
	reg [23:0] dino_sprite3 [0:23];
	initial begin
        dino_sprite3[0]  = 24'b000000000000000000000000;
		  dino_sprite3[1]  = 24'b000000000000000111111110;
		  dino_sprite3[2]  = 24'b000000000000001111111111;
		  dino_sprite3[3]  = 24'b000000000000001110111111;
		  dino_sprite3[4]  = 24'b000000000000001111111111;
		  dino_sprite3[5]  = 24'b000000000000001111111111;
		  dino_sprite3[6]  = 24'b000000000000001111100000;
		  dino_sprite3[7]  = 24'b000000000000001111111110;
		  dino_sprite3[8]  = 24'b100000000000011111110000;
		  dino_sprite3[9]  = 24'b100000000000111111110000;
		  dino_sprite3[10] = 24'b111000000011111111111100;
		  dino_sprite3[11] = 24'b111111000111111111110100;
		  dino_sprite3[12] = 24'b011111111111111111110100;
		  dino_sprite3[13] = 24'b000111111111111111110000;
		  dino_sprite3[14] = 24'b000001111111111111100000;
		  dino_sprite3[15] = 24'b000001111111111111000000;
		  dino_sprite3[16] = 24'b000000111111111111000000;
		  dino_sprite3[17] = 24'b000000011111111110000000;
		  dino_sprite3[18] = 24'b000000001111111100000000;
		  dino_sprite3[19] = 24'b000000000111111100000000;
		  dino_sprite3[20] = 24'b000000000111011100000000;
		  dino_sprite3[21] = 24'b000000000110001100000000;
		  dino_sprite3[22] = 24'b000000000111000100000000;
		  dino_sprite3[23] = 24'b000000000000000110000000;
	end

	reg [31:0] dino_duck_sprite [0:15];
	initial begin
         dino_duck_sprite[0]  = 32'b10000000000000000000000000000000;
			dino_duck_sprite[1]  = 32'b10000000000000000000000000000000;
			dino_duck_sprite[2]  = 32'b11100000111111111000000111111110;
			dino_duck_sprite[3]  = 32'b11111111111111111110001111111111;
			dino_duck_sprite[4]  = 32'b01111111111111111111111110111111;
			dino_duck_sprite[5]  = 32'b00011111111111111111111111111111;
			dino_duck_sprite[6]  = 32'b00000111111111111111111111111111;
			dino_duck_sprite[7]  = 32'b00000111111111111111111111100000;
			dino_duck_sprite[8]  = 32'b00000011111111111111111111111110;
			dino_duck_sprite[9]  = 32'b00000001111111111111101000000000;
			dino_duck_sprite[10] = 32'b00000000111111111110001100000000;
			dino_duck_sprite[11] = 32'b00000000011111110000000000000000;
			dino_duck_sprite[12] = 32'b00000000011101110000000000000000;
			dino_duck_sprite[13] = 32'b00000000011000110000000000000000;
			dino_duck_sprite[14] = 32'b00000000010000010000000000000000;
		   dino_duck_sprite[15] = 32'b00000000011000011000000000000000;
	end
	
	reg [31:0] dino_duck_sprite2 [0:15];
	initial begin
         dino_duck_sprite2[0]  = 32'b10000000000000000000000000000000;
			dino_duck_sprite2[1]  = 32'b10000000000000000000000000000000;
			dino_duck_sprite2[2]  = 32'b11100000111111111000000111111110;
			dino_duck_sprite2[3]  = 32'b11111111111111111110001111111111;
			dino_duck_sprite2[4]  = 32'b01111111111111111111111110111111;
			dino_duck_sprite2[5]  = 32'b00011111111111111111111111111111;
			dino_duck_sprite2[6]  = 32'b00000111111111111111111111111111;
			dino_duck_sprite2[7]  = 32'b00000111111111111111111111100000;
			dino_duck_sprite2[8]  = 32'b00000011111111111111111111111110;
			dino_duck_sprite2[9]  = 32'b00000001111111111111101000000000;
			dino_duck_sprite2[10] = 32'b00000000111111111110001100000000;
			dino_duck_sprite2[11] = 32'b00000000011111110000000000000000;
			dino_duck_sprite2[12] = 32'b00000000011101110000000000000000;
		   dino_duck_sprite2[13] = 32'b00000000011000110000000000000000;
		   dino_duck_sprite2[14] = 32'b00000000010000011100000000000000;
		   dino_duck_sprite2[15] = 32'b00000000011000000000000000000000;
	end
	
	reg [31:0] dino_duck_sprite3 [0:15];
	initial begin
         dino_duck_sprite3[0]  = 32'b10000000000000000000000000000000;
			dino_duck_sprite3[1]  = 32'b10000000000000000000000000000000;
			dino_duck_sprite3[2]  = 32'b11100000111111111000000111111110;
			dino_duck_sprite3[3]  = 32'b11111111111111111110001111111111;
			dino_duck_sprite3[4]  = 32'b01111111111111111111111110111111;
			dino_duck_sprite3[5]  = 32'b00011111111111111111111111111111;
			dino_duck_sprite3[6]  = 32'b00000111111111111111111111111111;
			dino_duck_sprite3[7]  = 32'b00000111111111111111111111100000;
			dino_duck_sprite3[8]  = 32'b00000011111111111111111111111110;
			dino_duck_sprite3[9]  = 32'b00000001111111111111101000000000;
			dino_duck_sprite3[10] = 32'b00000000111111111110001100000000;
			dino_duck_sprite3[11] = 32'b00000000011111110000000000000000;
			dino_duck_sprite3[12] = 32'b00000000011101110000000000000000;
		   dino_duck_sprite3[13] = 32'b00000000011000110000000000000000;
		   dino_duck_sprite3[14] = 32'b00000000011100010000000000000000;
		   dino_duck_sprite3[15] = 32'b00000000000000011000000000000000;
	end
	
	reg [18:0] cactus1 [0:23];
	initial begin
         cactus1[0]  = 19'b0000000001111000000;
			cactus1[1]  = 19'b0000000011111100000;
			cactus1[2]  = 19'b0000000011111100000;
			cactus1[3]  = 19'b0000000011111100000;
			cactus1[4]  = 19'b0000000011111100010;
			cactus1[5]  = 19'b0110000011111100111;
			cactus1[6]  = 19'b1111000011111100111;
			cactus1[7]  = 19'b1111000011111100111;
			cactus1[8]  = 19'b1111000011111100111;
			cactus1[9]  = 19'b1111000011111100111;
			cactus1[10] = 19'b1111100011111100111;
			cactus1[11] = 19'b0111111111111111111;
			cactus1[12] = 19'b0001111111111111110;
			cactus1[13] = 19'b0000001111111111000;
			cactus1[14] = 19'b0000000011111100000;
			cactus1[15] = 19'b0000000011111100000;
			cactus1[16] = 19'b0000000011111100000;
			cactus1[17] = 19'b0000000011111100000;
			cactus1[18] = 19'b0000000011111100000;
			cactus1[19] = 19'b0000000011111100000;
			cactus1[20] = 19'b0000000011111100000;
			cactus1[21] = 19'b0000000011111100000;
			cactus1[22] = 19'b0000000011111100000;
			cactus1[23] = 19'b0000000011111100000;
	end

	reg [35:0] bird_sprite [0:15];
	initial begin
         bird_sprite[0]  = 36'b000000000000010000000000000000000000;
			bird_sprite[1]  = 36'b000000000000011100000000000000000000;
			bird_sprite[2]  = 36'b000000011100011111000000000000000000;
			bird_sprite[3]  = 36'b000000111110000111100000000000000000;
			bird_sprite[4]  = 36'b000001111111000111111000000000000000;
			bird_sprite[5]  = 36'b000011111111000111111100000000000000;
			bird_sprite[6]  = 36'b000111111111100111111111000000000000;
			bird_sprite[7]  = 36'b001111111111110111111111100000000000;
			bird_sprite[8]  = 36'b011111111111110111111111110000000000;
			bird_sprite[9]  = 36'b111111111111111111111111111000000000;
			bird_sprite[10] = 36'b000000000011111111111111111110000000;
			bird_sprite[11] = 36'b000000000001111111111111111111111111;
			bird_sprite[12] = 36'b000000000000011111111111111111000000;
			bird_sprite[13] = 36'b000000000000000111111111111111111110;
			bird_sprite[14] = 36'b000000000000000001111111111111110000;
			bird_sprite[15] = 36'b000000000000000000011111111111110000;
	end

	reg [95:0] game_over_sprite [0:15];
	initial begin
         game_over_sprite[0]   = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
			game_over_sprite[1]   = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
			game_over_sprite[2]   = 96'b111111110000111111110000110000110000111111110000000011111111000011000011000011111111000011111111;
			game_over_sprite[3]   = 96'b111111110000111111110000111001110000111111110000000011111111000011000011000011111111000011111111;
			game_over_sprite[4]   = 96'b110000000000110000110000111111110000110000000000000011000011000011000011000011000000000011000011;
			game_over_sprite[5]   = 96'b110000000000110000110000111111110000110000000000000011000011000011000011000011000000000011000011;
			game_over_sprite[6]   = 96'b110000000000110000110000110110110000110000000000000011000011000011000011000011000000000011111111;
			game_over_sprite[7]   = 96'b110000000000111111110000110000110000111111110000000011000011000011000011000011111111000011001100;
			game_over_sprite[8]   = 96'b110111110000111111110000110000110000111111110000000011000011000011100111000011111111000011000110;
			game_over_sprite[9]   = 96'b110111110000110000110000110000110000110000000000000011000011000001100110000011000000000011000110;
			game_over_sprite[10]  = 96'b110000110000110000110000110000110000110000000000000011000011000001100110000011000000000011000011;
			game_over_sprite[11]  = 96'b110000110000110000110000110000110000110000000000000011000011000000111100000011000000000011000011;
			game_over_sprite[12]  = 96'b111111110000110000110000110000110000111111110000000011111111000000011000000011111111000011000011;
			game_over_sprite[13]  = 96'b111111110000110000110000110000110000111111110000000011111111000000011000000011111111000011000011;
			game_over_sprite[14]  = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
			game_over_sprite[15]  = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	end

	reg [35:0] cloud_sprite [0:15];
	initial begin
			cloud_sprite[0]  = 36'b000000000000000000000000000000000000;
			cloud_sprite[1]  = 36'b000000000000000000000000000000000000;
			cloud_sprite[2]  = 36'b000000000000000000000000000000000000;
			cloud_sprite[3]  = 36'b000000000000000000000000000000000000;
			cloud_sprite[4]  = 36'b000000000000000000000000000000000000;
			cloud_sprite[5]  = 36'b000000000000000000000000000000000000;
			cloud_sprite[6]  = 36'b000000000000011111111111100000000000;
			cloud_sprite[7]  = 36'b000000000000100000000000011100000000;
			cloud_sprite[8]  = 36'b000000000001000000000000000011000000;
			cloud_sprite[9]  = 36'b000000001110000000000000000000100000;
			cloud_sprite[10] = 36'b000000010000000000000000000000010000;
			cloud_sprite[11] = 36'b001100100000000000000000000000001100;
			cloud_sprite[12] = 36'b010011000000000000000000000000000010;
			cloud_sprite[13] = 36'b100000000000000000000000000000000001;
			cloud_sprite[14] = 36'b100000000000000000000000000000000001;
			cloud_sprite[15] = 36'b111111111111111111111111111111111111;
	end

	reg [19:0] hs_sprite [0:15];
	initial begin
          hs_sprite[0]  = 20'b11000011000001111110;
			 hs_sprite[1]  = 20'b11000011000011111111;
			 hs_sprite[2]  = 20'b11000011000011000001;
			 hs_sprite[3]  = 20'b11000011000011000000;
			 hs_sprite[4]  = 20'b11000011000011000000;
			 hs_sprite[5]  = 20'b11000011000011110000;
			 hs_sprite[6]  = 20'b11111111000011111110;
			 hs_sprite[7]  = 20'b11111111000001111111;
			 hs_sprite[8]  = 20'b11000011000000001111;
			 hs_sprite[9]  = 20'b11000011000000000011;
			 hs_sprite[10] = 20'b11000011000000000011;
			 hs_sprite[11] = 20'b11000011000010000011;
			 hs_sprite[12] = 20'b11000011000011111111;
			 hs_sprite[13] = 20'b11000011000001111110;
			 hs_sprite[14] = 20'b00000000000000000000;
			 hs_sprite[15] = 20'b00000000000000000000;
	end

	wire [9:0] cloud_y  = 80;
	wire [9:0] cloud2_y = 110;

	// --- Dino dimenzije i podruèje ---
	wire [9:0] dino_h = is_ducking ? 32 : 48;
	wire [9:0] dino_w = is_ducking ? 64 : 48;

	wire dino_area = (h_counter >= DINO_X) && 
						  (h_counter < DINO_X + dino_w) &&
						  (v_counter >= dino_y_pos - dino_h) &&  
						  (v_counter < dino_y_pos);

	// --- Cactus podruèje ---
	wire cactus_area = 
		 (h_counter >= (cactus_x < 0 ? 0 : cactus_x)) && 
		 (h_counter < (cactus_x > 639 ? 639 : cactus_x + CACTUS_W)) &&
		 (v_counter >= GROUND_Y - CACTUS_H) && 
		 (v_counter < GROUND_Y);

	// --- Bird podruèje ---
	wire bird_area = (h_counter >= bird_x) && 
						  (h_counter < bird_x + (BIRD_W << 1)) && 
						  (v_counter >= bird_y) &&  
						  (v_counter < bird_y + (BIRD_H << 1));

	// --- Ostala podruèja ---
	wire game_over_area = (h_counter >= GAME_OVER_X) && 
								 (h_counter < GAME_OVER_X + GAME_OVER_W) &&
								 (v_counter >= GAME_OVER_Y) && 
								 (v_counter < GAME_OVER_Y + GAME_OVER_H);

	wire cloud_area = (h_counter >= cloud_x) && 
							(h_counter < cloud_x + (CLOUD_W << 1)) &&
							(v_counter >= cloud_y) &&
							(v_counter < cloud_y + (CLOUD_H << 1));

	wire cloud2_area = (h_counter >= cloud2_x) && 
							 (h_counter < cloud2_x + (CLOUD_W << 1)) &&
							 (v_counter >= cloud2_y) &&
							 (v_counter < cloud2_y + (CLOUD_H << 1));

	wire hs_sprite_area = (h_counter >= HS_SPRITE_X) && 
								 (h_counter < HS_SPRITE_X + HS_SPRITE_W) &&
								 (v_counter >= HS_SPRITE_Y) && 
								 (v_counter < HS_SPRITE_Y + HS_SPRITE_H);

	wire ground_area = (v_counter >= GROUND_Y - 4) && (v_counter < GROUND_Y + 8);
	wire [3:0] ground_row_index = v_counter - (GROUND_Y - 4);
	wire [255:0] current_row_pattern = GROUND_PATTERN[ground_row_index];
	wire ground_pattern_bit = ~current_row_pattern[(h_counter + ground_offset) % 256];
	wire background_val = ground_area ? ground_pattern_bit : 1'b1;

	// --- Skaliranje i prikaz spritova ---
	wire [5:0] cloud_col_scaled    = (h_counter - cloud_x) >> 1;
	wire [4:0] cloud_row_scaled    = (v_counter - cloud_y) >> 1;
	wire [5:0] cloud2_col_scaled   = (h_counter - cloud2_x) >> 1;
	wire [4:0] cloud2_row_scaled   = (v_counter - cloud2_y) >> 1;
	wire cloud_pixel               = cloud_area  && cloud_sprite[cloud_row_scaled][cloud_col_scaled];
	wire cloud2_pixel              = cloud2_area && cloud_sprite[cloud2_row_scaled][cloud2_col_scaled];

	wire [5:0] bird_col_scaled     = (h_counter - bird_x) >> 1;
	wire [4:0] bird_row_scaled     = (v_counter - bird_y) >> 1; 
	wire [5:0] bird_col_flipped    = (BIRD_W - 1) - bird_col_scaled;
	wire bird_pixel                = bird_sprite[bird_row_scaled][bird_col_flipped];

	wire [10:0] game_over_col      = h_counter - GAME_OVER_X;
	wire [10:0] game_over_row      = v_counter - GAME_OVER_Y;

	// --- Dino sprite prikaz ---
	wire [4:0] sprite_row          = (v_counter - (dino_y_pos - dino_h)) >> 1;
	wire [5:0] sprite_col          = (h_counter - DINO_X) >> 1;
	wire [31:0] sprite_line        = is_ducking ? 
	                                  ((sprite_ver==0) ? dino_duck_sprite[sprite_row]   :
												  (sprite_ver==1) ? dino_duck_sprite2[sprite_row]  :
                                      (sprite_ver==2) ? dino_duck_sprite3[sprite_row]  :
                                       dino_duck_sprite[sprite_row])                   : 
												(sprite_ver==0) ? {8'b0, dino_sprite[sprite_row]}  :
                                    (sprite_ver==1) ? {8'b0, dino_sprite2[sprite_row]} :
                                    (sprite_ver==2) ? {8'b0, dino_sprite3[sprite_row]} :												
												{8'b0, dino_sprite[sprite_row]};

	wire [4:0] cactus_col          = (h_counter - cactus_x) >> 1;
	wire [4:0] cactus_row          = (v_counter - (GROUND_Y - CACTUS_H)) >> 1;
	wire cactus_pixel              = cactus_area && (cactus_col < 19) && (cactus_row < 24) && cactus1[cactus_row][18 - cactus_col];
	wire obstacle_pixel            = cactus_pixel || (bird_area && bird_pixel);

	// --- Dino oko (bijelo) ---
	wire white_eye = (
		 (!is_ducking && (sprite_row == 4) && (sprite_col == 5)) ||
		 (is_ducking  && (sprite_row == 4) && (sprite_col == 8))
	) && !sprite_line[(is_ducking ? 31 : 23) - sprite_col];

	// --- Validnost dino piksela ---
	wire dino_valid = dino_area && 
							(sprite_col < (is_ducking ? 32 : 24)) && 
							(sprite_row < (is_ducking ? 16 : 24));

	wire [4:0] sprite_index = (is_ducking ? 31 : 23) - sprite_col;
	wire sprite_pixel       = sprite_line[sprite_index];
	wire dino_pixel_val     = white_eye ? 1'b1 : (sprite_pixel ? 1'b0 : 1'b1);

	// --- Highscore sprite ---
	wire [4:0] hs_sprite_col = h_counter - HS_SPRITE_X;
	wire [3:0] hs_sprite_row = v_counter - HS_SPRITE_Y;
	wire hs_sprite_pixel     = hs_sprite_area && hs_sprite[hs_sprite_row][19 - hs_sprite_col];

	wire ground_black = ground_area && (ground_pattern_bit == 1'b0);

	wire pixel_val =
		 (collision && game_over_area) ? ~game_over_sprite[game_over_row][95-game_over_col] :
		 (score_pixel ? 1'b0 :
		 (hs_score_pixel ? 1'b0 :
		 (hs_sprite_pixel ? 1'b0 :   
		 (obstacle_pixel ? 1'b0 :
		 (ground_black ? 1'b0 :
		 (dino_valid ? dino_pixel_val :
		 (cloud_pixel ? 1'b0 :
		 (cloud2_pixel ? 1'b0 : 1'b1))))))));

	assign VGA_R = display_area ? pixel_val : 1'b0;
	assign VGA_G = display_area ? pixel_val : 1'b0;
	assign VGA_B = display_area ? pixel_val : 1'b0;

	endmodule
