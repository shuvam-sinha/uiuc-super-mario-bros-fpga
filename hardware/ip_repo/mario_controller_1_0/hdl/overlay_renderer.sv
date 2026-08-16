`timescale 1ns / 1ps
module overlay_renderer (
    input  logic [9:0]  DrawX, DrawY,
    input  logic [1:0]  game_state,
    output logic        is_overlay,
    output logic [3:0]  Red, Green, Blue
);
    localparam CHAR_W = 8;
    localparam CHAR_H = 8;
    localparam SCALE  = 3;
    localparam SCALED_W = CHAR_W * SCALE;
    localparam SCALED_H = CHAR_H * SCALE;
    localparam MENU_TITLE_LEN   = 16;
    localparam MENU_PLAY_LEN    = 15;
    localparam MENU_RESTART_LEN = 16;

    logic [7:0] font [0:26][0:7];
    initial begin
        font[0]  = '{8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
        font[1]  = '{8'h18,8'h3C,8'h66,8'h7E,8'h66,8'h66,8'h66,8'h00};
        font[2]  = '{8'h7C,8'h66,8'h66,8'h7C,8'h66,8'h66,8'h7C,8'h00};
        font[3]  = '{8'h3C,8'h66,8'h60,8'h60,8'h60,8'h66,8'h3C,8'h00};
        font[4]  = '{8'h78,8'h6C,8'h66,8'h66,8'h66,8'h6C,8'h78,8'h00};
        font[5]  = '{8'h7E,8'h60,8'h60,8'h78,8'h60,8'h60,8'h7E,8'h00};
        font[6]  = '{8'h7E,8'h60,8'h60,8'h78,8'h60,8'h60,8'h60,8'h00};
        font[7]  = '{8'h3C,8'h66,8'h60,8'h6E,8'h66,8'h66,8'h3C,8'h00};
        font[8]  = '{8'h66,8'h66,8'h66,8'h7E,8'h66,8'h66,8'h66,8'h00};
        font[9]  = '{8'h3C,8'h18,8'h18,8'h18,8'h18,8'h18,8'h3C,8'h00};
        font[10] = '{8'h1E,8'h0C,8'h0C,8'h0C,8'h0C,8'h6C,8'h38,8'h00};
        font[11] = '{8'h66,8'h6C,8'h78,8'h70,8'h78,8'h6C,8'h66,8'h00};
        font[12] = '{8'h60,8'h60,8'h60,8'h60,8'h60,8'h60,8'h7E,8'h00};
        font[13] = '{8'h63,8'h77,8'h7F,8'h6B,8'h63,8'h63,8'h63,8'h00};
        font[14] = '{8'h66,8'h76,8'h7E,8'h7E,8'h6E,8'h66,8'h66,8'h00};
        font[15] = '{8'h3C,8'h66,8'h66,8'h66,8'h66,8'h66,8'h3C,8'h00};
        font[16] = '{8'h7C,8'h66,8'h66,8'h7C,8'h60,8'h60,8'h60,8'h00};
        font[17] = '{8'h3C,8'h66,8'h66,8'h66,8'h6E,8'h3C,8'h0E,8'h00};
        font[18] = '{8'h7C,8'h66,8'h66,8'h7C,8'h6C,8'h66,8'h66,8'h00};
        font[19] = '{8'h3C,8'h66,8'h60,8'h3C,8'h06,8'h66,8'h3C,8'h00};
        font[20] = '{8'h7E,8'h18,8'h18,8'h18,8'h18,8'h18,8'h18,8'h00};
        font[21] = '{8'h66,8'h66,8'h66,8'h66,8'h66,8'h66,8'h3C,8'h00};
        font[22] = '{8'h66,8'h66,8'h66,8'h66,8'h66,8'h3C,8'h18,8'h00};
        font[23] = '{8'h63,8'h63,8'h63,8'h6B,8'h7F,8'h77,8'h63,8'h00};
        font[24] = '{8'h66,8'h66,8'h3C,8'h18,8'h3C,8'h66,8'h66,8'h00};
        font[25] = '{8'h66,8'h66,8'h66,8'h3C,8'h18,8'h18,8'h18,8'h00};
        font[26] = '{8'h7E,8'h06,8'h0C,8'h18,8'h30,8'h60,8'h7E,8'h00};
    end

    localparam FAILED_LEN   = 12;
    localparam COMPLETE_LEN = 15;

    logic [4:0] failed_str   [0:11];
    logic [4:0] complete_str [0:14];

    initial begin
        failed_str[0]=12; failed_str[1]=5;  failed_str[2]=22;
        failed_str[3]=5;  failed_str[4]=12; failed_str[5]=0;
        failed_str[6]=6;  failed_str[7]=1;  failed_str[8]=9;
        failed_str[9]=12; failed_str[10]=5; failed_str[11]=4;

        complete_str[0]=12; complete_str[1]=5;  complete_str[2]=22;
        complete_str[3]=5;  complete_str[4]=12; complete_str[5]=0;
        complete_str[6]=3;  complete_str[7]=15; complete_str[8]=13;
        complete_str[9]=16; complete_str[10]=12; complete_str[11]=5;
        complete_str[12]=20; complete_str[13]=5; complete_str[14]=4;
    end
    
    logic [4:0] menu_title_str   [0:15];
    logic [4:0] menu_play_str    [0:14];
    logic [4:0] menu_restart_str [0:15];
    
    initial begin
        // S  U  P  E  R  _  M  A  R  I  O  _  B  R  O  S
        menu_title_str[0]  = 19; menu_title_str[1]  = 21; menu_title_str[2]  = 16;
        menu_title_str[3]  = 5;  menu_title_str[4]  = 18; menu_title_str[5]  = 0;
        menu_title_str[6]  = 13; menu_title_str[7]  = 1;  menu_title_str[8]  = 18;
        menu_title_str[9]  = 9;  menu_title_str[10] = 15; menu_title_str[11] = 0;
        menu_title_str[12] = 2;  menu_title_str[13] = 18; menu_title_str[14] = 15;
        menu_title_str[15] = 19;
        // P  R  E  S  S  _  P  _  T  O  _  P  L  A  Y
        menu_play_str[0]  = 16; menu_play_str[1]  = 18; menu_play_str[2]  = 5;
        menu_play_str[3]  = 19; menu_play_str[4]  = 19; menu_play_str[5]  = 0;
        menu_play_str[6]  = 16; menu_play_str[7]  = 0;  menu_play_str[8]  = 20;
        menu_play_str[9]  = 15; menu_play_str[10] = 0;  menu_play_str[11] = 16;
        menu_play_str[12] = 12; menu_play_str[13] = 1;  menu_play_str[14] = 25;
        // P  R  E  S  S  _  R  _  T  O  _  R  E  S  E  T
        menu_restart_str[0]  = 16; menu_restart_str[1]  = 18; menu_restart_str[2]  = 5;
        menu_restart_str[3]  = 19; menu_restart_str[4]  = 19; menu_restart_str[5]  = 0;
        menu_restart_str[6]  = 18; menu_restart_str[7]  = 0;  menu_restart_str[8]  = 20;
        menu_restart_str[9]  = 15; menu_restart_str[10] = 0;  menu_restart_str[11] = 18;
        menu_restart_str[12] = 5;  menu_restart_str[13] = 19; menu_restart_str[14] = 5;
        menu_restart_str[15] = 20;
    end

    logic [9:0] text_y_start;
    logic [9:0] text_x_start;
    logic [9:0] text_width;
    logic [9:0] str_len;
    logic [9:0] rel_x;
    logic [9:0] char_idx;
    logic [9:0] char_col;
    logic [9:0] char_row;
    logic [4:0] font_idx;
    logic        pixel_on;

    assign text_y_start = 10'd228;

    always_comb begin
        is_overlay   = 1'b0;
        Red          = 4'h0;
        Green        = 4'h0;
        Blue         = 4'h0;
        str_len      = '0;
        text_width   = '0;
        text_x_start = '0;
        rel_x        = '0;
        char_idx     = '0;
        char_col     = '0;
        char_row     = '0;
        font_idx     = '0;
        pixel_on     = 1'b0;

        if (game_state == 2'b11) begin
            is_overlay = 1'b1;
            Red = 4'h0; Green = 4'h0; Blue = 4'h0;

            if (DrawY >= 180 && DrawY < 212) begin
                text_width   = MENU_TITLE_LEN * 32; 
                text_x_start = (640 - text_width) / 2;
                if (DrawX >= text_x_start && DrawX < text_x_start + text_width) begin
                    rel_x    = DrawX - text_x_start;
                    char_idx = rel_x / 32;
                    char_col = (rel_x % 32) / 4;
                    char_row = (DrawY - 180) / 4;
                    font_idx = menu_title_str[char_idx];
                    pixel_on = font[font_idx][char_row][7 - char_col];
                    if (pixel_on) begin
                        Red = 4'hF; Green = 4'hF; Blue = 4'h0;  
                    end
                end
            end

            if (DrawY >= 260 && DrawY < 276) begin
                text_width   = MENU_PLAY_LEN * 16;  
                text_x_start = (640 - text_width) / 2;
                if (DrawX >= text_x_start && DrawX < text_x_start + text_width) begin
                    rel_x    = DrawX - text_x_start;
                    char_idx = rel_x / 16;
                    char_col = (rel_x % 16) / 2;
                    char_row = (DrawY - 260) / 2;
                    font_idx = menu_play_str[char_idx];
                    pixel_on = font[font_idx][char_row][7 - char_col];
                    if (pixel_on) begin
                        Red = 4'hF; Green = 4'hF; Blue = 4'hF;  
                    end
                end
            end

            if (DrawY >= 295 && DrawY < 311) begin
                text_width   = MENU_RESTART_LEN * 16;
                text_x_start = (640 - text_width) / 2;
                if (DrawX >= text_x_start && DrawX < text_x_start + text_width) begin
                    rel_x    = DrawX - text_x_start;
                    char_idx = rel_x / 16;
                    char_col = (rel_x % 16) / 2;
                    char_row = (DrawY - 295) / 2;
                    font_idx = menu_restart_str[char_idx];
                    pixel_on = font[font_idx][char_row][7 - char_col];
                    if (pixel_on) begin
                        Red = 4'hF; Green = 4'hF; Blue = 4'hF;  // white
                    end
                end
            end
        end 
        else if (game_state != 2'b00 &&
            DrawY >= text_y_start && DrawY < text_y_start + SCALED_H) begin

            if (game_state == 2'b01) begin
                str_len    = FAILED_LEN;
                text_width = FAILED_LEN * SCALED_W;
            end else begin
                str_len    = COMPLETE_LEN;
                text_width = COMPLETE_LEN * SCALED_W;
            end

            text_x_start = (640 - text_width) / 2;

            if (DrawX >= text_x_start && DrawX < text_x_start + text_width) begin
                rel_x    = DrawX - text_x_start;
                char_idx = rel_x / SCALED_W;
                char_col = (rel_x % SCALED_W) / SCALE;
                char_row = (DrawY - text_y_start) / SCALE;

                if (game_state == 2'b01)
                    font_idx = failed_str[char_idx];
                else
                    font_idx = complete_str[char_idx];

                pixel_on = font[font_idx][char_row][7 - char_col];

                if (pixel_on) begin
                    is_overlay = 1'b1;
                    if (game_state == 2'b01) begin
                        Red = 4'hF; Green = 4'h0; Blue = 4'h0;
                    end else begin
                        Red = 4'h0; Green = 4'hF; Blue = 4'h0;
                    end
                end
            end
        end
    end
endmodule