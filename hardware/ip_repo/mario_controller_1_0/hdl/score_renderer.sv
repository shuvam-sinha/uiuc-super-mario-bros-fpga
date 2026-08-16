`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/05/2026 05:23:45 PM
// Design Name: 
// Module Name: score_renderer
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


`timescale 1ns / 1ps
module score_renderer (
    input  logic [9:0]  DrawX, DrawY,
    input  logic [15:0] score,
    input  logic [6:0]  progress,
    output logic        is_score,
    output logic [3:0]  Red, Green, Blue
);
    logic [4:0] digit_bitmap [0:9][0:6];
    initial begin
        digit_bitmap[0] = '{5'b01110, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b01110};
        digit_bitmap[1] = '{5'b00100, 5'b01100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b01110};
        digit_bitmap[2] = '{5'b01110, 5'b10001, 5'b00001, 5'b00110, 5'b01000, 5'b10000, 5'b11111};
        digit_bitmap[3] = '{5'b11111, 5'b00001, 5'b00010, 5'b00110, 5'b00001, 5'b10001, 5'b01110};
        digit_bitmap[4] = '{5'b00010, 5'b00110, 5'b01010, 5'b10010, 5'b11111, 5'b00010, 5'b00010};
        digit_bitmap[5] = '{5'b11111, 5'b10000, 5'b10000, 5'b11110, 5'b00001, 5'b10001, 5'b01110};
        digit_bitmap[6] = '{5'b01110, 5'b10000, 5'b10000, 5'b11110, 5'b10001, 5'b10001, 5'b01110};
        digit_bitmap[7] = '{5'b11111, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b01000, 5'b01000};
        digit_bitmap[8] = '{5'b01110, 5'b10001, 5'b10001, 5'b01110, 5'b10001, 5'b10001, 5'b01110};
        digit_bitmap[9] = '{5'b01110, 5'b10001, 5'b10001, 5'b01111, 5'b00001, 5'b00001, 5'b01110};
    end

    logic [3:0] d3, d2, d1, d0;
    assign d3 = (score / 1000) % 10;
    assign d2 = (score / 100)  % 10;
    assign d1 = (score / 10)   % 10;
    assign d0 =  score         % 10;

    logic in_score_region;
    assign in_score_region = (DrawX >= 4 && DrawX < 52) && (DrawY >= 2 && DrawY < 16);

    logic in_progress_region;
    assign in_progress_region = (DrawX >= 4 && DrawX < 108) && (DrawY >= 18 && DrawY < 22);

    logic [3:0] digit_val;
    logic [3:0] digit_col;
    logic [3:0] digit_row_idx;
    logic [3:0] digit_index;
    logic       pixel_on;

    always_comb begin
        is_score  = 1'b0;
        Red       = 4'h0;
        Green     = 4'h0;
        Blue      = 4'h0;
        pixel_on  = 1'b0;
        digit_val = 4'h0;

        if (in_score_region) begin
            is_score     = 1'b1;
            digit_index  = (DrawX - 4) / 12;
            digit_col    = ((DrawX - 4) % 12) / 2;
            digit_row_idx = (DrawY - 2) / 2;
        
            case (digit_index)
                0: digit_val = d3;
                1: digit_val = d2;
                2: digit_val = d1;
                3: digit_val = d0;
                default: digit_val = 0;
            endcase
        
            if (digit_col < 5 && digit_row_idx < 7) begin
                pixel_on = digit_bitmap[digit_val][digit_row_idx][4 - digit_col];
                if (pixel_on)
                    begin Red = 4'hF; Green = 4'hF; Blue = 4'hF; end  // white
                else
                    begin Red = 4'h0; Green = 4'h0; Blue = 4'h2; end  // dark bg
            end else begin
                is_score = 1'b0;
            end
        end
        if (in_progress_region) begin
            is_score = 1'b1;
            if (DrawX - 4 <= {2'b0, progress}) begin
                Red = 4'h0; Green = 4'hA; Blue = 4'h0;
            end else begin
                Red = 4'h0; Green = 4'h2; Blue = 4'h0;
            end
        end
    end
endmodule