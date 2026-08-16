`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2026 04:03:24 PM
// Design Name: 
// Module Name: mario_core
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


module mario_core (
    input  logic [9:0]  DrawX, DrawY,
    input  logic [15:0] CameraX,
    input  logic [9:0]  MarioY,
    input  logic [2:0]  sprite_id,       // bit[2]=flip_h, bits[1:0]=frame
    output logic [11:0] rom_address,
    output logic        is_mario
);
    logic [11:0] row_offset;
    logic [11:0] col_offset;
    logic        flip_h;
    logic [1:0]  frame;

    assign flip_h = sprite_id[2];        // 1 = mirror horizontally
    assign frame  = sprite_id[1:0];

    always_comb begin
        if ((DrawX >= 320) && (DrawX < 350) && (DrawY >= MarioY) && (DrawY < MarioY + 32)) 
            begin
            is_mario   = 1'b1;
            row_offset = (DrawY - MarioY);
            col_offset = flip_h ? (12'd29 - (DrawX - 320))
                                : (DrawX - 320);

            rom_address = (12'(frame) * 12'd960)
                        + (row_offset * 12'd30)
                        + col_offset;
        end 
        else 
        begin
            is_mario    = 1'b0;
            rom_address = 12'h000;
        end
    end
endmodule