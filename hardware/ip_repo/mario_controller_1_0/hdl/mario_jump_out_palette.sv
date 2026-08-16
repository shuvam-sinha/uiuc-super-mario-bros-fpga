module mario_jump_out_palette (
	input logic [3:0] index,
	output logic [3:0] red, green, blue
);

localparam [0:15][11:0] palette = {
    12'h5DF, // Index 0: BACKGROUND (mushroom)
    12'h5DF, // Index 1: BACKGROUND (mario)
    12'hFCA, // Index 2: SKIN 
    12'hF00, // Index 3: RED 
    12'h000, // Index 4: BLACK (mushroom)
    12'hFFF, // Index 5: WHITE (mushroom)
    12'h840, // Index 6: BROWN (mario & mushroom)
    12'hFFF, // Index 7: Unused
    
    12'hF0F, 12'hF0F, 12'hF0F, 12'hF0F, 12'hF0F, 12'hF0F, 12'hF0F, 12'hF0F
};

assign {red, green, blue} = palette[index];

endmodule
