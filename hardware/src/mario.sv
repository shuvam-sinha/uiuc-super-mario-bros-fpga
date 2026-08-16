`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/15/2026 02:50:45 PM
// Design Name: 
// Module Name: mario
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


module mario (
    input  logic [9:0]  MarioX, MarioY, DrawX, DrawY,
    output logic [7:0]  rom_address, 
    output logic        is_mario
);
    always_comb begin
        if ((DrawX >= MarioX) && (DrawX < MarioX + 16) &&
            (DrawY >= MarioY) && (DrawY < MarioY + 16)) 
        begin
            is_mario = 1'b1;
            rom_address = (DrawX - MarioX) + ((DrawY - MarioY) * 16);
        end 
        else 
        begin
            is_mario = 1'b0;
            rom_address = 8'd0;
        end
    end
endmodule
