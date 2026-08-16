`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/06/2026 03:39:40 PM
// Design Name: 
// Module Name: audio_player
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
module audio_player (
    input  logic clk,        // 25MHz
    input  logic reset,
    input  logic coin_trigger, 
    input  logic stomp_trigger,
    output logic audio_left,
    output logic audio_right
);
    // Note periods in 25MHz clock cycles
    // Period = 25,000,000 / (2 * frequency)
    localparam REST  = 32'd0;
    localparam C4    = 32'd47710;  // 262Hz
    localparam D4    = 32'd42553;  // 294Hz
    localparam E4    = 32'd37879;  // 330Hz
    localparam F4    = 32'd35714;  // 349Hz
    localparam G4    = 32'd31888;  // 392Hz
    localparam A4    = 32'd28409;  // 440Hz
    localparam B4    = 32'd25316;  // 494Hz
    localparam C5    = 32'd23810;  // 523Hz
    localparam D5    = 32'd21231;  // 587Hz
    localparam E5    = 32'd18939;  // 659Hz
    localparam F5    = 32'd17905;  // 698Hz
    localparam G5    = 32'd15944;  // 784Hz
    localparam A5    = 32'd14205;  // 880Hz

    // Note durations in samples at 25MHz
    // 120 BPM
    localparam Q  = 32'd12500000;  // quarter note
    localparam H  = 32'd25000000;  // half note
    localparam E  = 32'd6250000;   // eighth note
    localparam S  = 32'd3125000;   // sixteenth note

    localparam MELODY_LEN = 64;

    logic [31:0] cur_freq;
    logic [31:0] cur_dur;
    
    logic [5:0]  note_idx;     // current note index
    logic [31:0] dur_counter;  // counts down note duration
    logic [31:0] tone_counter; // square wave counter
    logic        tone_out;     // square wave output
    
    initial begin
        note_idx     = 6'd0;
        dur_counter  = E;
        tone_counter = 32'd0;
        tone_out     = 1'b0;
    end
    
    always_comb begin
        case (note_idx)
            6'd0:  begin cur_freq = E5; cur_dur = E; end
            6'd1:  begin cur_freq = E5; cur_dur = E; end
            6'd2:  begin cur_freq = REST; cur_dur = E; end
            6'd3:  begin cur_freq = E5; cur_dur = E; end
            6'd4:  begin cur_freq = REST; cur_dur = E; end
            6'd5:  begin cur_freq = C5; cur_dur = E; end
            6'd6:  begin cur_freq = E5; cur_dur = Q; end
            6'd7:  begin cur_freq = G5; cur_dur = Q; end
            6'd8:  begin cur_freq = REST; cur_dur = Q; end
            6'd9:  begin cur_freq = G4; cur_dur = Q; end
            6'd10: begin cur_freq = REST; cur_dur = Q; end
            6'd11: begin cur_freq = C5; cur_dur = Q; end
            6'd12: begin cur_freq = REST; cur_dur = E; end
            6'd13: begin cur_freq = G4; cur_dur = E; end
            6'd14: begin cur_freq = REST; cur_dur = E; end
            6'd15: begin cur_freq = E4; cur_dur = Q; end
            6'd16: begin cur_freq = REST; cur_dur = E; end
            6'd17: begin cur_freq = A4; cur_dur = E; end
            6'd18: begin cur_freq = REST; cur_dur = E; end
            6'd19: begin cur_freq = B4; cur_dur = E; end
            6'd20: begin cur_freq = REST; cur_dur = E; end
            6'd21: begin cur_freq = A4; cur_dur = E; end
            6'd22: begin cur_freq = A4; cur_dur = S; end
            6'd23: begin cur_freq = G4; cur_dur = S; end
            6'd24: begin cur_freq = E5; cur_dur = E; end
            6'd25: begin cur_freq = REST; cur_dur = S; end
            6'd26: begin cur_freq = G5; cur_dur = E; end
            6'd27: begin cur_freq = A5; cur_dur = E; end
            6'd28: begin cur_freq = F5; cur_dur = S; end
            6'd29: begin cur_freq = G5; cur_dur = S; end
            6'd30: begin cur_freq = REST; cur_dur = S; end
            6'd31: begin cur_freq = E5; cur_dur = E; end
            6'd32: begin cur_freq = REST; cur_dur = S; end
            6'd33: begin cur_freq = C5; cur_dur = S; end
            6'd34: begin cur_freq = D5; cur_dur = S; end
            6'd35: begin cur_freq = B4; cur_dur = E; end
            6'd36: begin cur_freq = REST; cur_dur = E; end
            6'd37: begin cur_freq = C5; cur_dur = Q; end
            6'd38: begin cur_freq = REST; cur_dur = E; end
            6'd39: begin cur_freq = G4; cur_dur = E; end
            6'd40: begin cur_freq = REST; cur_dur = E; end
            6'd41: begin cur_freq = E4; cur_dur = Q; end
            6'd42: begin cur_freq = REST; cur_dur = E; end
            6'd43: begin cur_freq = A4; cur_dur = E; end
            6'd44: begin cur_freq = REST; cur_dur = E; end
            6'd45: begin cur_freq = B4; cur_dur = E; end
            6'd46: begin cur_freq = REST; cur_dur = E; end
            6'd47: begin cur_freq = A4; cur_dur = E; end
            6'd48: begin cur_freq = A4; cur_dur = S; end
            6'd49: begin cur_freq = G4; cur_dur = S; end
            6'd50: begin cur_freq = E5; cur_dur = E; end
            6'd51: begin cur_freq = REST; cur_dur = S; end
            6'd52: begin cur_freq = G5; cur_dur = E; end
            6'd53: begin cur_freq = A5; cur_dur = E; end
            6'd54: begin cur_freq = F5; cur_dur = S; end
            6'd55: begin cur_freq = G5; cur_dur = S; end
            6'd56: begin cur_freq = REST; cur_dur = S; end
            6'd57: begin cur_freq = E5; cur_dur = E; end
            6'd58: begin cur_freq = REST; cur_dur = S; end
            6'd59: begin cur_freq = C5; cur_dur = S; end
            6'd60: begin cur_freq = D5; cur_dur = S; end
            6'd61: begin cur_freq = B4; cur_dur = E; end
            6'd62: begin cur_freq = REST; cur_dur = H; end
            default: begin cur_freq = REST; cur_dur = H; end
        endcase
    end

    

    always_ff @(posedge clk) begin
        if (reset) begin
            note_idx     <= 6'd0;
            dur_counter  <= E;
            tone_counter <= 32'd0;
            tone_out     <= 1'b0;
        end else begin
            if (dur_counter == 0) begin
                note_idx     <= (note_idx == MELODY_LEN-1) ? 6'd0 : note_idx + 1;
                dur_counter  <= cur_dur;
                tone_counter <= 32'd0;
            end else begin
                dur_counter <= dur_counter - 1;
            end
    
            if (cur_freq == REST) begin
                tone_out <= 1'b0;
            end else begin
                if (tone_counter >= cur_freq) begin
                    tone_counter <= 32'd0;
                    tone_out     <= ~tone_out;
                end else begin
                    tone_counter <= tone_counter + 1;
                end
            end
        end
    end
    
    localparam SFX_COIN_FREQ1  = 32'd15944;  // G5 - 784Hz
    localparam SFX_COIN_FREQ2  = 32'd11932;  // B5 - 988Hz  
    localparam SFX_STOMP_FREQ1 = 32'd56818;  // A3 - 220Hz
    localparam SFX_STOMP_FREQ2 = 32'd47710;  // C4 - 262Hz

    localparam SFX_NONE  = 2'd0;
    localparam SFX_COIN  = 2'd1;
    localparam SFX_STOMP = 2'd2;

    logic [1:0]  sfx_state;
    logic [31:0] sfx_dur_counter;
    logic [31:0] sfx_tone_counter;
    logic        sfx_phase;       // 0 = first note, 1 = second note
    logic        sfx_tone_out;
    logic [31:0] sfx_cur_freq;
    logic [31:0] sfx_cur_dur;

    localparam SFX_NOTE_DUR = 32'd3125000;  

    always_comb begin
        case (sfx_state)
            SFX_COIN: begin
                sfx_cur_freq = sfx_phase ? SFX_COIN_FREQ2  : SFX_COIN_FREQ1;
                sfx_cur_dur  = SFX_NOTE_DUR;
            end
            SFX_STOMP: begin
                sfx_cur_freq = sfx_phase ? SFX_STOMP_FREQ2 : SFX_STOMP_FREQ1;
                sfx_cur_dur  = SFX_NOTE_DUR;
            end
            default: begin
                sfx_cur_freq = REST;
                sfx_cur_dur  = SFX_NOTE_DUR;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            sfx_state        <= SFX_NONE;
            sfx_dur_counter  <= 32'd0;
            sfx_tone_counter <= 32'd0;
            sfx_phase        <= 1'b0;
            sfx_tone_out     <= 1'b0;
        end else begin
            if (coin_trigger) begin
                sfx_state        <= SFX_COIN;
                sfx_dur_counter  <= SFX_NOTE_DUR;
                sfx_tone_counter <= 32'd0;
                sfx_phase        <= 1'b0;
            end else if (stomp_trigger) begin
                sfx_state        <= SFX_STOMP;
                sfx_dur_counter  <= SFX_NOTE_DUR;
                sfx_tone_counter <= 32'd0;
                sfx_phase        <= 1'b0;
            end else if (sfx_state != SFX_NONE) begin
                if (sfx_dur_counter == 0) begin
                    if (sfx_phase == 1'b1) begin
                        sfx_state <= SFX_NONE;
                        sfx_phase <= 1'b0;
                    end else begin
                        sfx_phase        <= 1'b1;
                        sfx_dur_counter  <= SFX_NOTE_DUR;
                        sfx_tone_counter <= 32'd0;
                    end
                end else begin
                    sfx_dur_counter <= sfx_dur_counter - 1;
                end
            end

            // SFX tone generator
            if (sfx_cur_freq == REST || sfx_state == SFX_NONE) begin
                sfx_tone_out <= 1'b0;
            end else begin
                if (sfx_tone_counter >= sfx_cur_freq) begin
                    sfx_tone_counter <= 32'd0;
                    sfx_tone_out     <= ~sfx_tone_out;
                end else begin
                    sfx_tone_counter <= sfx_tone_counter + 1;
                end
            end
        end
    end

    // SFX takes priority over background music
    logic mixed_out;
    assign mixed_out   = (sfx_state != SFX_NONE) ? sfx_tone_out : tone_out;
    assign audio_left  = mixed_out;
    assign audio_right = mixed_out;

endmodule