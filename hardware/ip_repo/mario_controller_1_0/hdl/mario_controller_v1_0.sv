//Provided HDMI_Text_controller_v1_0 for HDMI AXI4 IP 
//Fall 2024 Distribution

//Modified 3/10/24 by Zuofu
//Updated 11/18/24 by Zuofu


`timescale 1 ns / 1 ps

module mario_controller_v1_0 #
(
    parameter integer C_AXI_DATA_WIDTH = 32,
    parameter integer C_AXI_ADDR_WIDTH = 14 
)
(
    output logic hdmi_clk_n, hdmi_clk_p,
    output logic [2:0] hdmi_tx_n, hdmi_tx_p,
    
    output logic audio_left,
    output logic audio_right,


    input logic  axi_aclk, axi_aresetn,
    input logic [C_AXI_ADDR_WIDTH-1 : 0] axi_awaddr,
    input logic  axi_awvalid,
    output logic axi_awready,
    input logic [C_AXI_DATA_WIDTH-1 : 0] axi_wdata,
    input logic [(C_AXI_DATA_WIDTH/8)-1 : 0] axi_wstrb,
    input logic  axi_wvalid,
    output logic axi_wready,
    output logic [1 : 0] axi_bresp,
    output logic  axi_bvalid,
    input logic  axi_bready,
    input logic [C_AXI_ADDR_WIDTH-1 : 0] axi_araddr,
    input logic  axi_arvalid,
    output logic axi_arready,
    output logic [C_AXI_DATA_WIDTH-1 : 0] axi_rdata,
    output logic [1 : 0] axi_rresp,
    output logic  axi_rvalid,
    input logic  axi_rready
);

    logic clk_25MHz, clk_125MHz, locked;
    logic [9:0] drawX, drawY;
    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;
    logic reset_ah = ~axi_aresetn;

    logic [15:0] CameraX;
    logic [9:0]  MarioY;
    logic [2:0]  sprite_id;
    
    logic [15:0] MushroomX[4:0];
    logic [9:0]  MushroomY[4:0];
    logic        MushroomActive[4:0];
    logic        MushroomDir[4:0];

    logic [11:0] mario_rom_address;
    logic [3:0]  rom_idx;
    logic        is_mario, is_mario_delayed;
        
    logic [9:0]  mush_rom_address[4:0];
    logic        is_mushroom[4:0];
    logic        is_any_mushroom;
    logic [9:0]  mush_addr_mux;
    logic [3:0]  mush_rom_idx;
    logic        is_mushroom_delayed[4:0];
    logic        is_any_mushroom_delayed;
    
    logic [15:0] Score;
    logic        is_score, is_score_delayed;
    logic [3:0]  score_red, score_green, score_blue;
    
    logic [6:0] Progress;
    
    logic [1:0] GameState;
    logic       is_overlay, is_overlay_delayed;
    logic [3:0] overlay_red, overlay_green, overlay_blue;

    logic coin_trigger, stomp_trigger;
    logic [1:0] SfxTrigger;
    
    logic [13:0] tile_bram_wr_addr;
    logic [7:0]  tile_bram_wr_data;
    logic        tile_bram_wr_en;
    logic [13:0] tile_bram_rd_addr;
    logic [7:0]  tile_bram_rd_data;
    
    logic [3:0] tile_red, tile_green, tile_blue;


    clk_wiz_0 clk_wiz (.clk_out1(clk_25MHz), .clk_out2(clk_125MHz), .reset(reset_ah), .locked(locked), .clk_in1(axi_aclk));

    vga_controller vga (.pixel_clk(clk_25MHz), .reset(reset_ah), .hs(hsync), .vs(vsync), .active_nblank(vde), .drawX(drawX), .drawY(drawY));    

    mario_controller_v1_0_AXI # ( 
        .C_S_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH)
    ) axi_inst (
        .S_AXI_ACLK(axi_aclk), .S_AXI_ARESETN(axi_aresetn),
        .S_AXI_AWADDR(axi_awaddr), .S_AXI_AWVALID(axi_awvalid), .S_AXI_AWREADY(axi_awready),
        .S_AXI_WDATA(axi_wdata), .S_AXI_WSTRB(axi_wstrb), .S_AXI_WVALID(axi_wvalid), .S_AXI_WREADY(axi_wready),
        .S_AXI_BRESP(axi_bresp), .S_AXI_BVALID(axi_bvalid), .S_AXI_BREADY(axi_bready),
        .S_AXI_ARADDR(axi_araddr), .S_AXI_ARVALID(axi_arvalid), .S_AXI_ARREADY(axi_arready),
        .S_AXI_RDATA(axi_rdata), .S_AXI_RRESP(axi_rresp), .S_AXI_RVALID(axi_rvalid), .S_AXI_RREADY(axi_rready),
        .CameraX(CameraX), .MarioY(MarioY), .sprite_id(sprite_id),
        .MushroomX(MushroomX), .MushroomY(MushroomY), .MushroomActive(MushroomActive),
        .MushroomDir(MushroomDir),
        .Score(Score),
        .Progress(Progress),
        .GameState(GameState),
        .SfxTrigger(SfxTrigger),
        .tile_bram_wr_addr(tile_bram_wr_addr),
        .tile_bram_wr_data(tile_bram_wr_data),
        .tile_bram_wr_en  (tile_bram_wr_en)
    );

    mario_core mario_logic (
        .DrawX(drawX), .DrawY(drawY), .CameraX(CameraX), .MarioY(MarioY), .sprite_id(sprite_id),
        .rom_address(mario_rom_address), .is_mario(is_mario)
    );

    genvar m;
    generate
    for (m = 0; m < 5; m++) begin : mush_gen
        mushroom_core mush_logic (
            .DrawX(drawX), .DrawY(drawY), .CameraX(CameraX),
            .MushroomX(MushroomX[m]), .MushroomY(MushroomY[m]),
            .active(MushroomActive[m]), .flip_h(MushroomDir[m]),
            .rom_address(mush_rom_address[m]),
            .is_mushroom(is_mushroom[m])
        );
    end
    endgenerate
    
    always_comb begin
    mush_addr_mux   = 10'h0;
        is_any_mushroom = 1'b0;
        for (int i = 0; i < 5; i++) begin
            if (is_mushroom[i] && !is_any_mushroom) begin
                mush_addr_mux   = mush_rom_address[i];
                is_any_mushroom = 1'b1;
            end
        end
    end
    
    blk_mem_gen_0 sprite_bram (
        .clka(clk_25MHz),
        .addra(mario_rom_address),
        .ena(1'b1),
        .douta(rom_idx)
    );
    
    always_ff @(posedge clk_25MHz) 
    begin
        is_mario_delayed    <= is_mario;
        is_any_mushroom_delayed <= is_any_mushroom;
        is_score_delayed        <= is_score;
        is_overlay_delayed <= is_overlay;
    end
    

    
    blk_mem_gen_1 tile_bram (
        .clka  (axi_aclk),
        .ena   (1'b1),
        .wea   (tile_bram_wr_en),
        .addra (tile_bram_wr_addr),
        .dina  (tile_bram_wr_data),
        .clkb  (clk_25MHz),
        .enb   (1'b1),
        .web   (1'b0),
        .addrb (tile_bram_rd_addr),
        .doutb (tile_bram_rd_data)
    );
    
    blk_mem_gen_2 mushroom_bram (
        .clka(clk_25MHz),
        .addra(mush_addr_mux),
        .ena(1'b1),
        .douta(mush_rom_idx)
    );
    
    tile_renderer tile_render (
        .clk          (clk_25MHz),
        .DrawX        (drawX),
        .DrawY        (drawY),
        .CameraX      (CameraX),
        .bram_rd_addr (tile_bram_rd_addr),
        .bram_rd_data (tile_bram_rd_data),
        .Red          (tile_red),
        .Green        (tile_green),
        .Blue         (tile_blue)
    );
    
    score_renderer score_disp (
        .DrawX(drawX), .DrawY(drawY),
        .score(Score),
        .progress(Progress),
        .is_score(is_score),
        .Red(score_red), .Green(score_green), .Blue(score_blue)
    );
    
    overlay_renderer overlay_disp (
        .DrawX(drawX), .DrawY(drawY),
        .game_state(GameState),
        .is_overlay(is_overlay),
        .Red(overlay_red), .Green(overlay_green), .Blue(overlay_blue)
    );
    

    color_mapper colors (
        .mario_rom_idx        (rom_idx),
        .mush_rom_idx         (mush_rom_idx),
        .is_mario_delayed     (is_mario_delayed),
        .is_mushroom_delayed  (is_any_mushroom_delayed),
        .is_score_delayed     (is_score_delayed),
        .score_red            (score_red),
        .score_green          (score_green),
        .score_blue           (score_blue),
        .is_overlay_delayed (is_overlay_delayed),
        .overlay_red(overlay_red), .overlay_green(overlay_green), .overlay_blue(overlay_blue),
        .tile_red             (tile_red),
        .tile_green           (tile_green),
        .tile_blue            (tile_blue),
        .Red(red), .Green(green), .Blue(blue)
    );
    
    assign coin_trigger  = SfxTrigger[0];
    assign stomp_trigger = SfxTrigger[1];
    
    audio_player audio (
        .clk(clk_25MHz),
        .reset(reset_ah),
        .coin_trigger(coin_trigger),
        .stomp_trigger(stomp_trigger),
        .audio_left(audio_left),
        .audio_right(audio_right)
    );

    hdmi_tx_0 vga_to_hdmi (
        .pix_clk(clk_25MHz), .pix_clkx5(clk_125MHz), .pix_clk_locked(locked), .rst(reset_ah),
        .red(red), .green(green), .blue(blue), .hsync(hsync), .vsync(vsync), .vde(vde),
        .TMDS_CLK_P(hdmi_clk_p), .TMDS_CLK_N(hdmi_clk_n), .TMDS_DATA_P(hdmi_tx_p), .TMDS_DATA_N(hdmi_tx_n)
    );

endmodule
