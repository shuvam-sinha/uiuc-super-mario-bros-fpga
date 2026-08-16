`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: ECE-Illinois
// Engineer: Zuofu Cheng
// 
// Create Date: 06/08/2023 12:21:05 PM
// Design Name: 
// Module Name: hdmi_text_controller_v1_0_AXI
// Project Name: ECE 385 - hdmi_text_controller
// Target Devices: 
// Tool Versions: 
// Description: 
// This is a modified version of the Vivado template for an AXI4-Lite peripheral,
// rewritten into SystemVerilog for use with ECE 385.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.02 - File modified to be more consistent with generated template
// Revision 11/18 - Made comments less confusing
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module mario_controller_v1_0_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 14
)
(
    // Game register outputs
    output logic [15:0] CameraX,
    output logic [9:0]  MarioY,
    output logic [2:0]  sprite_id,      // bit[2]=flip_h, bits[1:0]=frame
    output logic [15:0] MushroomX[4:0],
    output logic [9:0]  MushroomY[4:0],
    output logic        MushroomActive[4:0],
    output logic        MushroomDir[4:0],
    output logic [15:0] Score,
    output logic [6:0] Progress,
    output logic [1:0] GameState,
    output logic [1:0] SfxTrigger,



    // Tile BRAM write port (address >= 0x100)
    output logic [13:0] tile_bram_wr_addr,
    output logic [7:0]  tile_bram_wr_data,
    output logic        tile_bram_wr_en,

    // Standard AXI4-Lite signals
    input  logic        S_AXI_ACLK,
    input  logic        S_AXI_ARESETN,
    input  logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  logic [2:0]  S_AXI_AWPROT,
    input  logic        S_AXI_AWVALID,
    output logic        S_AXI_AWREADY,
    input  logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  logic [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  logic        S_AXI_WVALID,
    output logic        S_AXI_WREADY,
    output logic [1:0]  S_AXI_BRESP,
    output logic        S_AXI_BVALID,
    input  logic        S_AXI_BREADY,
    input  logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  logic [2:0]  S_AXI_ARPROT,
    input  logic        S_AXI_ARVALID,
    output logic        S_AXI_ARREADY,
    output logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output logic [1:0]  S_AXI_RRESP,
    output logic        S_AXI_RVALID,
    input  logic        S_AXI_RREADY
);

    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr, axi_araddr;
    logic axi_awready, axi_wready, axi_bvalid, axi_arready, axi_rvalid;
    logic [1:0] axi_bresp, axi_rresp;
    logic [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    logic aw_en;

    localparam integer ADDR_LSB          = (C_S_AXI_DATA_WIDTH/32) + 1;  // = 2
    localparam integer OPT_MEM_ADDR_BITS = 5;

    logic [C_S_AXI_DATA_WIDTH-1:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3, slv_reg4, slv_reg5, slv_reg6,
                                    slv_reg7, slv_reg8, slv_reg9, slv_reg10, slv_reg11, slv_reg12,
                                    slv_reg13, slv_reg14, slv_reg15, slv_reg16, slv_reg17, slv_reg18,
                                    slv_reg19, slv_reg20, slv_reg21, slv_reg22, slv_reg23, slv_reg24, 
                                    slv_reg25, slv_reg26;
    logic slv_reg_wren;
    integer byte_index;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin axi_awready <= 0; aw_en <= 1; end
        else if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            begin axi_awready <= 1; aw_en <= 0; end
        else if (S_AXI_BREADY && axi_bvalid)
            begin aw_en <= 1; axi_awready <= 0; end
        else axi_awready <= 0;
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) axi_awaddr <= 0;
        else if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            axi_awaddr <= S_AXI_AWADDR;
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) axi_wready <= 0;
        else if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en)
            axi_wready <= 1;
        else axi_wready <= 0;
    end

    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin axi_bvalid <= 0; axi_bresp <= 0; end
        else if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
            begin axi_bvalid <= 1; axi_bresp <= 0; end
        else if (S_AXI_BREADY && axi_bvalid) axi_bvalid <= 0;
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin axi_arready <= 0; axi_araddr <= 0; end
        else if (~axi_arready && S_AXI_ARVALID)
            begin axi_arready <= 1; axi_araddr <= S_AXI_ARADDR; end
        else axi_arready <= 0;
    end

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin axi_rvalid <= 0; axi_rresp <= 0; end
        else if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
            begin axi_rvalid <= 1; axi_rresp <= 0; end
        else if (axi_rvalid && S_AXI_RREADY) axi_rvalid <= 0;
    end

    assign S_AXI_RDATA = (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h00) ? slv_reg0  :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h01) ? slv_reg1  :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h02) ? slv_reg2  :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h03) ? slv_reg3  :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h04) ? slv_reg4  :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h05) ? slv_reg5  :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h06) ? slv_reg6  :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h07) ? slv_reg7  :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h08) ? slv_reg8  :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h09) ? slv_reg9  :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h0a) ? slv_reg10 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h0b) ? slv_reg11 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h0c) ? slv_reg12 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h0d) ? slv_reg13 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h0e) ? slv_reg14 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h0f) ? slv_reg15 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h10) ? slv_reg16 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h11) ? slv_reg17 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h12) ? slv_reg18 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h13) ? slv_reg19 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h14) ? slv_reg20 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h15) ? slv_reg21 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h16) ? slv_reg22 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h17) ? slv_reg23 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h18) ? slv_reg24 :
                     (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 6'h19) ? slv_reg25 :
                     slv_reg26;

    
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            slv_reg0 <= 0; slv_reg1 <= 0;
            slv_reg2 <= 0; slv_reg3 <= 0;
            slv_reg4 <= 0; slv_reg5 <= 0;
            slv_reg6 <= 0;
            slv_reg7  <= 0; slv_reg8  <= 0; slv_reg9  <= 0; slv_reg10 <= 0;
            slv_reg11 <= 0; slv_reg12 <= 0; slv_reg13 <= 0; slv_reg14 <= 0;
            slv_reg15 <= 0; slv_reg16 <= 0; slv_reg17 <= 0; slv_reg18 <= 0;
            slv_reg19 <= 0; slv_reg20 <= 0; slv_reg21 <= 0; slv_reg22 <= 0;
            slv_reg23 <= 0;
            slv_reg24 <= 0;
            slv_reg25 <= 0;
            slv_reg26 <= 0;
            tile_bram_wr_en <= 0;
        end else begin
            tile_bram_wr_en <= 0;

            if (slv_reg_wren) begin
                if (axi_awaddr[13:10] == 4'h0) begin
                    case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                        6'h0: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                  if (S_AXI_WSTRB[byte_index])
                                      slv_reg0[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h1: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                  if (S_AXI_WSTRB[byte_index])
                                      slv_reg1[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h2: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                  if (S_AXI_WSTRB[byte_index])
                                      slv_reg2[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h3: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                  if (S_AXI_WSTRB[byte_index])
                                      slv_reg3[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h4: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                  if (S_AXI_WSTRB[byte_index])
                                      slv_reg4[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h5: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                  if (S_AXI_WSTRB[byte_index])
                                      slv_reg5[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h6: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                  if (S_AXI_WSTRB[byte_index])
                                      slv_reg6[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h7:  for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg7[byte_index*8+:8]  <= S_AXI_WDATA[byte_index*8+:8];
                        6'h8:  for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg8[byte_index*8+:8]  <= S_AXI_WDATA[byte_index*8+:8];
                        6'h9:  for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg9[byte_index*8+:8]  <= S_AXI_WDATA[byte_index*8+:8];
                        6'ha:  for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg10[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'hb:  for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg11[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'hc:  for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg12[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'hd:  for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg13[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'he:  for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg14[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'hf:  for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg15[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h10: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg16[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h11: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg17[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h12: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg18[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h13: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg19[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h14: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg20[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h15: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg21[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h16: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg22[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h17: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                   if (S_AXI_WSTRB[byte_index]) slv_reg23[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h18: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                    if (S_AXI_WSTRB[byte_index]) slv_reg24[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h19: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                    if (S_AXI_WSTRB[byte_index]) slv_reg25[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        6'h1A: for (byte_index=0; byte_index<=3; byte_index=byte_index+1)
                                    if (S_AXI_WSTRB[byte_index]) slv_reg26[byte_index*8+:8] <= S_AXI_WDATA[byte_index*8+:8];
                        default: ;
                    endcase
                end else begin
                    tile_bram_wr_addr <= (axi_awaddr[13:0] - 14'h400) >> 2;
                    tile_bram_wr_data <= S_AXI_WDATA[7:0];
                    tile_bram_wr_en   <= 1'b1;
                end
            end
        end
    end

    assign CameraX          = slv_reg0[15:0];
    assign MarioY           = slv_reg1[9:0];
    assign sprite_id        = slv_reg2[2:0];
    assign MushroomX[0]     = slv_reg3[15:0];
    assign MushroomY[0]     = slv_reg4[9:0];
    assign MushroomActive[0]= slv_reg5[0];
    assign MushroomDir[0]   = slv_reg6[0];
    assign MushroomX[1]     = slv_reg7[15:0];
    assign MushroomY[1]     = slv_reg8[9:0];
    assign MushroomActive[1]= slv_reg9[0];
    assign MushroomDir[1]   = slv_reg10[0];
    assign MushroomX[2]     = slv_reg11[15:0];
    assign MushroomY[2]     = slv_reg12[9:0];
    assign MushroomActive[2]= slv_reg13[0];
    assign MushroomDir[2]   = slv_reg14[0];
    assign MushroomX[3]     = slv_reg15[15:0];
    assign MushroomY[3]     = slv_reg16[9:0];
    assign MushroomActive[3]= slv_reg17[0];
    assign MushroomDir[3]   = slv_reg18[0];
    assign MushroomX[4]     = slv_reg19[15:0];
    assign MushroomY[4]     = slv_reg20[9:0];
    assign MushroomActive[4]= slv_reg21[0];
    assign MushroomDir[4]   = slv_reg22[0];
    assign Score = slv_reg23[15:0];
    assign Progress = slv_reg24[6:0];
    assign GameState = slv_reg25[1:0];
    assign SfxTrigger = slv_reg26[1:0];  // bit0=coin, bit1=stomp


    
endmodule