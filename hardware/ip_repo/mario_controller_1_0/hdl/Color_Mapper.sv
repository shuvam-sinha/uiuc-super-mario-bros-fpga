//-------------------------------------------------------------------------
//    Color_Mapper.sv                                                    --
//    Stephen Kempf                                                      --
//    3-1-06                                                             --
//                                                                       --
//    Modified by David Kesler  07-16-2008                               --
//    Translated by Joe Meng    07-07-2013                               --
//    Modified by Zuofu Cheng   08-19-2023                               --
//                                                                       --
//    Fall 2023 Distribution                                             --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module color_mapper (
    input  logic [3:0] mario_rom_idx,
    input  logic [3:0] mush_rom_idx,
    input  logic       is_mario_delayed,
    input  logic       is_mushroom_delayed,
    input  logic       is_score_delayed,
    input  logic [3:0] score_red, score_green, score_blue,
    input  logic       is_overlay_delayed,
    input  logic [3:0] overlay_red, overlay_green, overlay_blue,
    input  logic [3:0] tile_red, tile_green, tile_blue,
    output logic [3:0] Red, Green, Blue
);
    logic [3:0] m_red, m_green, m_blue;
    logic [3:0] mush_red, mush_green, mush_blue;

    mario_jump_out_palette palette_mario (
        .index(mario_rom_idx),
        .red(m_red), .green(m_green), .blue(m_blue)
    );
    mario_jump_out_palette palette_mush (
        .index(mush_rom_idx),
        .red(mush_red), .green(mush_green), .blue(mush_blue)
    );

    always_comb begin
        if (is_overlay_delayed) begin
            Red = overlay_red; Green = overlay_green; Blue = overlay_blue;
        end else if (is_score_delayed) begin
            Red = score_red; Green = score_green; Blue = score_blue;
        end else if (is_mario_delayed && mario_rom_idx != 4'h1) begin
            Red = m_red; Green = m_green; Blue = m_blue;
        end else if (is_mushroom_delayed && mush_rom_idx != 4'h0) begin
            Red = mush_red; Green = mush_green; Blue = mush_blue;
        end else begin
            Red = tile_red; Green = tile_green; Blue = tile_blue;
        end
    end
endmodule