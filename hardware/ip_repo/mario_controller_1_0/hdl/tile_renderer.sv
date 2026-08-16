`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2026 04:04:59 PM
// Design Name: 
// Module Name: tile_renderer
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
module tile_renderer (
    input  logic        clk,
    input  logic [9:0]  DrawX,
    input  logic [9:0]  DrawY,
    input  logic [15:0] CameraX,
    output logic [13:0] bram_rd_addr,
    input  logic [7:0]  bram_rd_data,
    output logic [3:0]  Red, Green, Blue
);
    // Latch CameraX at end of each frame
    logic [15:0] CameraX_latched;
    always_ff @(posedge clk) begin
        if (DrawX == 10'd0 && DrawY == 10'd479)
            CameraX_latched <= CameraX;
    end
 
    logic [12:0] world_x;
    logic [9:0]  world_y;
    assign world_x = {3'b0, DrawX} + CameraX_latched[12:0];
    assign world_y = DrawY;
 
    logic [7:0] tile_col;
    logic [3:0] tile_row;
    logic [4:0] sub_col;
    logic [4:0] sub_row;
    assign tile_col = world_x[12:5];
    assign tile_row = world_y[8:5];
    assign sub_col  = world_x[4:0];
    assign sub_row  = world_y[4:0];
 
    // First tile info for scanline prefetch
    logic [7:0] first_tile_col;
    assign first_tile_col = CameraX_latched[12:5] - 1'd1;
 
    logic [9:0]  next_draw_y;
    logic [3:0]  first_tile_row;
    assign next_draw_y    = DrawY + 10'd1;
    assign first_tile_row = (DrawY < 10'd479) ? next_draw_y[8:5] : tile_row;
 
    logic [3:0] tile_id_reg;
    always_ff @(posedge clk) begin
        if (DrawX == 10'd0 && DrawY < 10'd480 && CameraX_latched[4:0] < 5'd29)
            tile_id_reg <= bram_rd_data[3:0];
        else if (sub_col == 5'd30 && DrawX < 10'd640 && DrawY < 10'd480)
            tile_id_reg <= bram_rd_data[3:0];
    end
 
    logic [12:0] next_world_x;
    logic [4:0]  next_sub_col;
    logic [7:0]  next_tile_col;
    assign next_world_x  = world_x + 13'd1;
    assign next_sub_col  = next_world_x[4:0];
    assign next_tile_col = next_world_x[12:5];
 
    logic [13:0] tilemap_prefetch;
    assign tilemap_prefetch = {2'b0, tile_row, next_tile_col};
 
    logic [14:0] tilesheet_next;
    assign tilesheet_next = 15'd3840
                          + {tile_id_reg, 10'b0}
                          + {sub_row,     5'b0}
                          + {8'b0, next_sub_col};
 
    assign bram_rd_addr = (DrawX == 10'd799) ?
                          {2'b0, first_tile_row, first_tile_col} :
                      (sub_col == 5'd29 && DrawX < 10'd640) ?
                          tilemap_prefetch :
                          tilesheet_next[13:0];
 
    logic [3:0] last_Red, last_Green, last_Blue;
    logic prefetch_cycle;
    always_ff @(posedge clk) begin
        prefetch_cycle <= (sub_col == 5'd29 && DrawX < 10'd640);
        last_Red   <= Red;
        last_Green <= Green;
        last_Blue  <= Blue;
    end
 
    always_comb begin
        if (prefetch_cycle)
            begin Red = last_Red; Green = last_Green; Blue = last_Blue; end
        else
            case (bram_rd_data[2:0])
                3'h0: begin Red = 4'h5; Green = 4'hD; Blue = 4'hF; end  // sky blue
                3'h1: begin Red = 4'hF; Green = 4'hF; Blue = 4'hF; end  // white
                3'h2: begin Red = 4'h8; Green = 4'h4; Blue = 4'h0; end  // brown
                3'h3: begin Red = 4'h0; Green = 4'h0; Blue = 4'h0; end  // black
                3'h4: begin Red = 4'hF; Green = 4'hD; Blue = 4'h0; end  // yellow
                3'h5: begin Red = 4'h0; Green = 4'hA; Blue = 4'h0; end  // green
                default: begin Red = 4'h5; Green = 4'hD; Blue = 4'hF; end
            endcase
    end
endmodule