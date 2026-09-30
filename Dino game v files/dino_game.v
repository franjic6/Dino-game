`timescale 1ns / 1ps

module TOP_DINO_VGA(
    input  wire CLK,
    input  wire BTN,
    input  wire BTN_DUCK,
    input  wire START,
    output wire VGA_HSYNC, 
    output wire VGA_VSYNC,
    output wire VGA_R,
    output wire VGA_G,
    output wire VGA_B
);

    // --- Clock & VGA ---
    wire clk25;
    wire [9:0] h_counter, v_counter;
    wire display_area;

    // --- Parametri fizike ---
    parameter JUMP_STRENGTH = -18;
    parameter GRAVITY       = 2;
    parameter GROUND_Y      = 350;
    parameter HITBOX_MARGIN = 8;

    // --- Dino parametri ---
    parameter DINO_X       = 200;
    parameter DINO_W       = 48; 
    parameter DINO_H       = 48;
    parameter DINO_W_DUCK  = 64;
    parameter DINO_H_DUCK  = 32;

    // --- Cactus parametri ---
    parameter CACTUS_W      = 38;
    parameter CACTUS_H      = 48;
    parameter CACTUS_START_X= 640;

    // --- Bird parametri ---
    parameter BIRD_W        = 72;
    parameter BIRD_H        = 32;
    parameter BIRD_START_X  = 640;
    parameter BIRD_Y_LOW    = GROUND_Y - BIRD_H - 30;        
    parameter BIRD_Y_MED    = GROUND_Y - BIRD_H - 50;      
    parameter BIRD_Y_HIGH   = GROUND_Y - BIRD_H - 150;      

    // --- Registri fizike ---
    reg [9:0] dino_y      = GROUND_Y;
    reg [9:0] dino_y_prev = GROUND_Y;
    reg [9:0] dino_vy     = 0;
    reg is_jumping        = 0;
    reg is_ducking        = 0;
    reg duck_ready        = 1;
    reg [19:0] jump_counter = 0;

    // --- Prepreke ---
    reg signed [31:0] cactus_x = CACTUS_START_X;
    reg signed [31:0] bird_x   = BIRD_START_X;
    reg signed [9:0] cloud_x   = 640;
    reg signed [9:0] cloud2_x  = 1050;
    reg [9:0] next_bird_y;
    reg [9:0] bird_y = BIRD_Y_HIGH;

    reg collision     = 0;
    reg game_running  = 0;
    reg [15:0] cactus_clkdiv = 0;
    reg [15:0] bird_clkdiv   = 0;
    reg [17:0] cloud_clkdiv  = 0;
    reg [15:0] ground_clkdiv = 0;
    wire cactus_tick = (cactus_clkdiv == 0);
    wire bird_tick   = (bird_clkdiv == 0);
    wire cloud_tick  = (cloud_clkdiv == 0);
    wire ground_tick = (ground_clkdiv == 0);

    // --- LFSR & spawn kontrola ---
    reg [25:0] lfsr = 26'h2ACE1;
    wire lfsr_bit = lfsr[25] ^ lfsr[24] ^ lfsr[22] ^ lfsr[1];  // CORRECTED LFSR TAPS
    reg [25:0] spawn_delay_counter      = 0;
    reg [25:0] bird_spawn_delay_counter = 0;
    reg waiting_for_spawn      = 0;
    reg waiting_for_bird_spawn = 0;
    parameter MIN_DELAY      = 0;
    parameter MIN_BIRD_DELAY = 25_000_000;

    // --- Score & high score ---
    reg [13:0] score = 0;
    reg [15:0] prev_score = 0;  
    reg decomposition_done = 0; 
    reg [13:0] final_score = 0;

    reg [13:0] high_score = 0; 
    reg [3:0] hs_thousands, hs_hundreds, hs_tens, hs_units; 
    reg [13:0] temp_high_score = 0;
    reg [2:0] hs_state = 0;
    reg hs_decomposition_done = 0;
    reg [13:0] prev_high_score = 0;

    reg [3:0] thousands, hundreds, tens, units;
    reg [13:0] temp_score = 0;
    reg [2:0] state = 0;
    reg [24:0] sec_counter = 0;  
    reg [7:0] ground_offset = 0;
	 
	 reg [1:0] sprite_ver = 0;
	 reg [29:0] cntr = 0;
	 reg [1:0] animation_state = 0;

    // --- Instanciranje modula ---
    clk_divider clkdiv_inst(
        .clk_in(CLK),
        .clk_out(clk25)
    );

    vga_controller vga_inst(
        .clk25(clk25),
        .vga_hsync(VGA_HSYNC),
        .vga_vsync(VGA_VSYNC),
        .h_count(h_counter),
        .v_count(v_counter),
        .display_on(display_area)
    );

    dino_draw dino_inst(
        .h_counter(h_counter),
        .v_counter(v_counter),
        .display_area(display_area),
        .dino_y_pos(dino_y),
        .cactus_x(cactus_x),
        .bird_x(bird_x),
        .bird_y(bird_y),
        .cloud_x(cloud_x),
        .cloud2_x(cloud2_x),
        .thousands(thousands),
        .hundreds(hundreds),
        .tens(tens),
        .units(units),
        .hs_thousands(hs_thousands),
        .hs_hundreds(hs_hundreds),
        .hs_tens(hs_tens),
        .hs_units(hs_units),
        .ground_offset(ground_offset),
        .is_ducking(is_ducking),
        .collision(collision),
		  .sprite_ver(sprite_ver),
		  .clk25(clk25),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B)
    );

    // --- Debounce za tipke ---
    wire jump_pressed, duck_pressed, start_button;
    debounce db(.clk(clk25), .btn_in(BTN), .btn_out(jump_pressed));
    debounce db_duck(.clk(clk25), .btn_in(BTN_DUCK), .btn_out(duck_pressed));
    debounce db_start(.clk(clk25), .btn_in(START), .btn_out(start_button));

wire [6:0] modifikator;
assign modifikator = score>>5;
    // --- Clock divider tickovi ---
    always @(posedge clk25) begin 
	     if(modifikator < 64 ) begin
				if(bird_clkdiv<(65000-modifikator*500)) 
					bird_clkdiv   <= bird_clkdiv + 1;
				else
					bird_clkdiv   <= 0;
				if(cactus_clkdiv<(65000-modifikator*500)) 
					cactus_clkdiv   <= cactus_clkdiv + 1;
				else
					cactus_clkdiv   <= 0;
				if(ground_clkdiv<(65000-modifikator*500)) 
					ground_clkdiv   <= ground_clkdiv + 1;
				else
					ground_clkdiv   <= 0;
			end
			else begin
				if(bird_clkdiv < 30000) 
					bird_clkdiv   <= bird_clkdiv + 1;
				else
					bird_clkdiv   <= 0;
				if(cactus_clkdiv < 30000) 
					cactus_clkdiv   <= cactus_clkdiv + 1;
				else
					cactus_clkdiv   <= 0;
				if(ground_clkdiv < 40000) 
					ground_clkdiv   <= ground_clkdiv + 1;
				else
					ground_clkdiv   <= 0;
			end
	end
	
    always @(posedge clk25) cloud_clkdiv  <= cloud_clkdiv + 1;

    // --- Dekodiranje rezultata ---
    always @(posedge clk25) begin
        if (!game_running && !collision) begin
            prev_score <= 0;
            decomposition_done <= 0;
            thousands <= 0;
            hundreds  <= 0;
            tens      <= 0;
            units     <= 0;
            state     <= 0;
        end else begin
            case(state)
                0: if (score != prev_score && !decomposition_done) begin
                        thousands <= 0; hundreds <= 0; tens <= 0; units <= 0;
                        prev_score <= score; temp_score <= score;
                        decomposition_done <= 1; state <= 1;
                   end
                1: if (temp_score >= 1000) begin
                        thousands <= thousands + 1; temp_score <= temp_score - 1000;
                   end else state <= 2;
                2: if (temp_score >= 100) begin
                        hundreds <= hundreds + 1; temp_score <= temp_score - 100;
                   end else state <= 3;
                3: if (temp_score >= 10) begin
                        tens <= tens + 1; temp_score <= temp_score - 10;
                   end else begin
                        units <= temp_score[3:0]; decomposition_done <= 0; state <= 0;
                   end
            endcase
        end
    end

    // --- Dekodiranje high score-a ---
    always @(posedge clk25) begin
        if (!game_running && !collision) begin
            hs_thousands <= 0; hs_hundreds <= 0; hs_tens <= 0; hs_units <= 0;
            hs_state <= 0; hs_decomposition_done <= 0; prev_high_score <= 0; 
        end else begin
            if (high_score != prev_high_score) begin
                prev_high_score <= high_score; hs_decomposition_done <= 0; 
            end
            case(hs_state)
                0: if (!hs_decomposition_done) begin
                        hs_thousands <= 0; hs_hundreds <= 0; hs_tens <= 0; hs_units <= 0;
                        temp_high_score <= high_score; hs_decomposition_done <= 1; hs_state <= 1;
                   end
                1: if (temp_high_score >= 1000) begin
                        hs_thousands <= hs_thousands + 1; temp_high_score <= temp_high_score - 1000;
                   end else hs_state <= 2;
                2: if (temp_high_score >= 100) begin
                        hs_hundreds <= hs_hundreds + 1; temp_high_score <= temp_high_score - 100;
                   end else hs_state <= 3;
                3: if (temp_high_score >= 10) begin
                        hs_tens <= hs_tens + 1; temp_high_score <= temp_high_score - 10;
                   end else begin
                        hs_units <= temp_high_score[3:0]; hs_state <= 0;
                   end
            endcase
        end
    end

    // --- Dino fizika ---
    always @(posedge clk25) begin
        //cactus_clkdiv <= cactus_clkdiv + 1;
        if (!game_running && start_button) begin
            dino_y <= GROUND_Y; dino_vy <= 0;
            is_jumping <= 0; is_ducking <= 0;
            duck_ready <= 1; jump_counter <= 0;
        end else if (!collision) begin
            if (dino_y == GROUND_Y) begin
                if (!duck_pressed) duck_ready <= 1;
                if (duck_pressed && duck_ready && !is_jumping)
                    is_ducking <= 1;
                else
                    is_ducking <= 0;
            end else begin
                duck_ready <= 0; is_ducking <= 0;
            end
            jump_counter <= jump_counter + 1;
            if (jump_counter == 0) begin
                dino_y_prev <= dino_y;
                if (is_jumping) begin
                    dino_vy <= dino_vy + GRAVITY;
                    dino_y <= dino_y + dino_vy;
                    if (dino_y_prev < GROUND_Y && dino_y >= GROUND_Y) begin
                        dino_y <= GROUND_Y; dino_vy <= 0; is_jumping <= 0;
                    end
                end else if (jump_pressed && dino_y == GROUND_Y && !is_ducking) begin
                    dino_vy <= JUMP_STRENGTH; is_jumping <= 1;
                end
            end
        end
    end

    // --- Hitbox izraèun ---
    wire [9:0] dino_hitbox_x     = DINO_X + HITBOX_MARGIN;
    wire [9:0] dino_hitbox_w     = (is_ducking ? DINO_W_DUCK : DINO_W) - 2*HITBOX_MARGIN;
    wire [9:0] dino_hitbox_y_top = dino_y - (is_ducking ? DINO_H_DUCK : DINO_H) + HITBOX_MARGIN;
    wire [9:0] dino_hitbox_y_bot = dino_y - HITBOX_MARGIN;

    wire [9:0] cactus_hitbox_x     = cactus_x + HITBOX_MARGIN;
    wire [9:0] cactus_hitbox_w     = CACTUS_W - 2*HITBOX_MARGIN;
    wire [9:0] cactus_hitbox_y_top = GROUND_Y - CACTUS_H + HITBOX_MARGIN;
    wire [9:0] cactus_hitbox_y_bot = GROUND_Y - HITBOX_MARGIN;

    wire [9:0] bird_hitbox_x     = bird_x + HITBOX_MARGIN;
    wire [9:0] bird_hitbox_w     = BIRD_W - 2*HITBOX_MARGIN;
    wire [9:0] bird_hitbox_y_top = bird_y + HITBOX_MARGIN;
    wire [9:0] bird_hitbox_y_bot = bird_y + BIRD_H - HITBOX_MARGIN;

    // --- LFSR generator ---
    always @(posedge clk25) begin
        if (!game_running)
            lfsr <= 26'h2ACE1;  
        else
            lfsr <= {lfsr[24:0], lfsr_bit};  
    end
	
	 always@(posedge clk25) begin

	  end

    // --- Glavna logika igre ---
    always @(posedge clk25) begin
        if (!game_running && !collision) begin
            cactus_x <= CACTUS_START_X; bird_x <= BIRD_START_X+50;
            spawn_delay_counter <= 0; bird_spawn_delay_counter <= 0;
            waiting_for_spawn <= 0; waiting_for_bird_spawn <= 0;
            bird_y <= BIRD_Y_HIGH;
				sprite_ver <= 0;
            if (start_button) game_running <= 1;
        end else if (game_running && !collision) begin
		  
		      if(cntr<2097152) begin
					cntr<=cntr+1;
			   end else begin
				   if(dino_y == GROUND_Y) begin
						animation_state <= animation_state + 1;
						case(animation_state)
						2'b00: sprite_ver <= 0;
						2'b01: sprite_ver <= 1;
						2'b10: sprite_ver <= 0;
						2'b11: sprite_ver <= 2;
						default: sprite_ver <= 0;
						endcase
							cntr <= 0;
						end
					  else sprite_ver <= 0;
			   end
            // Brojanje bodova
            if (sec_counter == 5_000_000) begin
                score <= score + 1; sec_counter <= 0;
            end else begin
                sec_counter <= sec_counter + 1;
            end

            // Cactus
            if (cactus_tick) begin
                if (!waiting_for_spawn) begin
                    cactus_x <= cactus_x - 1;
                    if ((cactus_x + CACTUS_W) < 0) begin
                        waiting_for_spawn <= 1;
                        spawn_delay_counter <= MIN_DELAY + lfsr[24:0];
                    end
                end
            end
            if (waiting_for_spawn) begin
                if (spawn_delay_counter > 0)
                    spawn_delay_counter <= spawn_delay_counter - 1;
                else begin
					     if(bird_x > 320 && bird_x < 640)
						  spawn_delay_counter <= 4_000_000;
						  else begin
                    cactus_x <= CACTUS_START_X; 
						  waiting_for_spawn <= 0;
						  end
                end
            end

            // Bird
            if (bird_tick) begin
                if (!waiting_for_bird_spawn)
                    bird_x <= bird_x - 1;
                if ((bird_x + BIRD_W) < 0) begin
                    waiting_for_bird_spawn <= 1;
                    bird_spawn_delay_counter <= MIN_BIRD_DELAY + lfsr[24:0];
                end
            end
            if (waiting_for_bird_spawn) begin
                if (bird_spawn_delay_counter > 0)
                    bird_spawn_delay_counter <= bird_spawn_delay_counter - 1;
                else begin
					     if( cactus_x > 320 && cactus_x < 640)
						  bird_spawn_delay_counter <= 2_000_000; 
						  else begin
                    case(lfsr[25:24])
                        2'b00: next_bird_y = BIRD_Y_LOW;
                        2'b01: next_bird_y = BIRD_Y_MED;
                        2'b10: next_bird_y = BIRD_Y_HIGH;
                        2'b11: next_bird_y = BIRD_Y_LOW;
                        default: next_bird_y = BIRD_Y_LOW;
                    endcase
                    bird_y <= next_bird_y;
                    bird_x <= BIRD_START_X;
                    waiting_for_bird_spawn <= 0;
						  end
                end
            end

            // Cloud
            if (cloud_tick) begin
                cloud_x <= cloud_x - 1;
                cloud2_x <= cloud2_x - 1;
            end

            // Ground
            if (ground_tick) ground_offset <= ground_offset + 1;
				
				if (score >= 9999) begin
				collision <= 1;
				end

            // Kolizija
            if ((cactus_hitbox_x + cactus_hitbox_w > dino_hitbox_x) && 
                (cactus_hitbox_x < dino_hitbox_x + dino_hitbox_w) &&
                (cactus_hitbox_y_bot > dino_hitbox_y_top) && 
                (cactus_hitbox_y_top < dino_hitbox_y_bot)) 
            begin
                collision <= 1; game_running <= 0;
            end else if ((bird_hitbox_x + bird_hitbox_w > dino_hitbox_x) && 
                         (bird_hitbox_x < dino_hitbox_x + dino_hitbox_w) &&
                         (bird_hitbox_y_bot > dino_hitbox_y_top) && 
                         (bird_hitbox_y_top < dino_hitbox_y_bot)) 
            begin
                collision <= 1; game_running <= 0;
            end
        end else if (collision) begin
		      sprite_ver <= 0;
            if (score > high_score) high_score <= score;
            if (start_button) begin
                collision <= 0;
                cactus_x <= CACTUS_START_X;
                bird_x <= BIRD_START_X+50;
					 sprite_ver <= 0;
                case(lfsr[25:24])
                    2'b00: bird_y <= BIRD_Y_LOW;
                    2'b01: bird_y <= BIRD_Y_MED;
                    2'b10: bird_y <= BIRD_Y_HIGH;
                    2'b11: bird_y <= BIRD_Y_LOW;
                    default: bird_y <= BIRD_Y_LOW;
                endcase
                game_running <= 1;
                score <= 0;
            end
        end
    end

endmodule
