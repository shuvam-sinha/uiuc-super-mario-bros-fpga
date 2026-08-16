`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/04/2026 03:07:53 PM
// Design Name: 
// Module Name: mushroom_core
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

module mushroom_core (
    input  logic [9:0]  DrawX, DrawY,
    input  logic [15:0] CameraX,
    input  logic [15:0] MushroomX,
    input  logic [9:0]  MushroomY,
    input  logic        active,
    input  logic        flip_h,      // 1 = mirror horizontally
    output logic [9:0]  rom_address,
    output logic        is_mushroom
);
    logic signed [16:0] screen_x_signed;
    logic [9:0]         screen_x;
    logic [4:0]         col_offset;

    assign screen_x_signed = {1'b0, MushroomX} - {1'b0, CameraX};
    assign screen_x = screen_x_signed[9:0];

    always_comb begin
        if (active &&
            screen_x_signed >= 17'sd0 && screen_x_signed < 17'sd640 &&
            DrawX >= screen_x && DrawX < screen_x + 10'd32 &&
            DrawY >= MushroomY && DrawY < MushroomY + 10'd32)
        begin
            is_mushroom = 1'b1;
            col_offset  = flip_h ? (5'd31 - (DrawX - screen_x)) : (DrawX - screen_x);
            rom_address = ((DrawY - MushroomY) * 10'd32) + col_offset;
        end
        else begin
            is_mushroom = 1'b0;
            rom_address = 10'h000;
        end
    end
endmodule