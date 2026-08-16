`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2026 02:50:45 PM
// Design Name: 
// Module Name: color_mapper
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


module color_mapper (
    input  logic        is_mario,
    input  logic [3:0]  sprite_color_idx,
    input  logic [9:0]  DrawX, DrawY,
    output logic [3:0]  Red, Green, Blue
);
    always_comb begin
        if (is_mario && sprite_color_idx != 4'h0) 
        begin
            case (sprite_color_idx)
                4'h1: {Red, Green, Blue} = 12'hF00; // Red
                4'h2: {Red, Green, Blue} = 12'h840; // Brown
                4'h3: {Red, Green, Blue} = 12'hFC9; // Skin tone
                default: {Red, Green, Blue} = 12'h000;
            endcase
        end 
        else 
        begin
            Red = 4'h5;
            Green = 4'hA;
            Blue = 4'hF;
        end
    end
endmodule
