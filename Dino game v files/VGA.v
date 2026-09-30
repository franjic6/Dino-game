`timescale 1ns / 1ps
module t_rex_game(
    input wire CLK,
    input wire JUMP,
    output VGA_HSYNC, VGA_VSYNC,
    output [2:0] VGA_RGB
);

    // VGA Timing Parameters
    parameter h_display = 640;
    parameter h_frontporch = 16;
    parameter h_syncwidth = 96;
    parameter h_backporch = 48;
    parameter h_total = 800;
    
    parameter v_display = 480;
    parameter v_frontporch = 10;
    parameter v_syncwidth = 2;
    parameter v_backporch = 33;
    parameter v_total = 525;

    reg [9:0] h_counter = 0;
    reg [9:0] v_counter = 0;
    reg hsync, vsync;
    wire game_clk;
    
    // Game Parameters
    reg [9:0] dino_y = 400;
    reg [9:0] dino_vy = 0;
    reg [3:0] jump_counter = 0;
    reg [9:0] obstacle_x = 640;
    reg [2:0] game_state = 0; // 0:playing, 1:game over
    reg [15:0] score = 0;
    
    // Clock Divider (4Hz game clock)
    reg [23:0] clk_div = 0;
    always @(posedge CLK) clk_div <= clk_div + 1;
    assign game_clk = clk_div[19];

    // Dino Jump Physics
    localparam GRAVITY = 2;
    localparam JUMP_FORCE = 12;
    
    always @(posedge game_clk) begin
        if(game_state == 0) begin
            // Jump handling
            if(JUMP && dino_y >= 400) begin
                dino_vy <= -JUMP_FORCE;
                jump_counter <= 0;
            end
            
            // Gravity application
            if(dino_y < 400 || dino_vy != 0) begin
                dino_y <= dino_y + dino_vy;
                dino_vy <= dino_vy + GRAVITY;
            end
            
            // Ground collision
            if(dino_y >= 400) begin
                dino_y <= 400;
                dino_vy <= 0;
            end
            
            // Obstacle movement
            obstacle_x <= (obstacle_x == 0) ? 640 : obstacle_x - 4;
            score <= score + 1;
            
            // Obstacle respawn
            if(obstacle_x == 0 && score[4:0] == 0)
                obstacle_x <= 640;
                
            // Collision detection
            if((obstacle_x >= 50 && obstacle_x <= 80) && 
               (dino_y >= 360 && dino_y <= 400))
                game_state <= 1;
        end
    end

    // VGA Timing Generation
    always @(posedge CLK) begin
        h_counter <= (h_counter == h_total-1) ? 0 : h_counter + 1;
        if(h_counter == h_total-1)
            v_counter <= (v_counter == v_total-1) ? 0 : v_counter + 1;
            
        hsync <= ~((h_counter >= h_display+h_frontporch) && 
                  (h_counter < h_display+h_frontporch+h_syncwidth));
        vsync <= ~((v_counter >= v_display+v_frontporch) && 
                  (v_counter < v_display+v_frontporch+v_syncwidth));
    end

    // Render Pipeline
    wire visible = (h_counter < h_display) && (v_counter < v_display);
    wire ground = (v_counter >= 400);
    wire dino = (h_counter >= 50 && h_counter <= 80) && 
                (v_counter >= dino_y-40 && v_counter <= dino_y);
    wire obstacle = (h_counter >= obstacle_x && h_counter <= obstacle_x+30) && 
                   (v_counter >= 370 && v_counter <= 400);
    wire game_over = (h_counter >= 200 && h_counter <= 440) &&
                    (v_counter >= 200 && v_counter <= 280);

    // Color Generation
    reg [2:0] rgb;
    always @(*) begin
        if(!visible) rgb = 0;
        else if(game_over) rgb = 3'b100;
        else if(ground) rgb = 3'b110;
        else if(dino) rgb = 3'b010;
        else if(obstacle) rgb = 3'b011;
        else rgb = 3'b111;
    end

    assign VGA_HSYNC = hsync;
    assign VGA_VSYNC = vsync;
    assign VGA_RGB = rgb;

endmodule
