// =============================================================================
// Module: detection_block
// Description: Multi-band acoustic energy accumulator & sound classification
//              Fs = 48 kHz, N = 512 pt FFT -> df = 93.75 Hz/bin
//              - Alarm (~800 Hz)     -> Bins 6 to 10
//              - Doorbell (~1 kHz)   -> Bins 8 to 12
//              - Attention (~3 kHz)  -> Bins 29 to 35
// =============================================================================

`timescale 1ns/1ps

module detection_block #(
    parameter THRESHOLD = 64'd5000
)(
    input  wire        clk,
    input  wire        reset_n,
    input  wire        valid,
    input  wire        sop,
    input  wire        eop,
    input  wire [31:0] magnitude,
    output reg  [1:0]  final_sound // 00=Silence/None, 01=Alarm, 10=Doorbell, 11=Attention
);
    reg [8:0]  bin;
    reg [63:0] energy_alarm;
    reg [63:0] energy_doorbell;
    reg [63:0] energy_attention;

    // ---------------------------------------------------------
    // 1. Bin Counter Tracking
    // ---------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            bin <= 9'd0;
        else if (valid) begin
            if (eop) bin <= 9'd0;
            else     bin <= bin + 1'b1;
        end
    end

    // ---------------------------------------------------------
    // 2. Band Energy Accumulation
    // ---------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            energy_alarm     <= 64'd0;
            energy_doorbell  <= 64'd0;
            energy_attention <= 64'd0;
        end else if (sop) begin
            // Reset at frame start
            energy_alarm     <= 64'd0;
            energy_doorbell  <= 64'd0;
            energy_attention <= 64'd0;
        end else if (valid) begin
            if (bin >= 9'd6  && bin <= 9'd10)
                energy_alarm <= energy_alarm + magnitude;
            if (bin >= 9'd8  && bin <= 9'd12)
                energy_doorbell <= energy_doorbell + magnitude;
            if (bin >= 9'd29 && bin <= 9'd35)
                energy_attention <= energy_attention + magnitude;
        end
    end

    // ---------------------------------------------------------
    // 3. Frame Classification with Race-Condition Prevention
    // ---------------------------------------------------------
    reg eop_d;
    always @(posedge clk) eop_d <= eop;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            final_sound <= 2'b00;
        end else if (eop_d) begin
            if (energy_attention > energy_doorbell &&
                energy_attention > energy_alarm    &&
                energy_attention > THRESHOLD)
                final_sound <= 2'b11; // Attention / Alert
            else if (energy_doorbell > energy_alarm &&
                     energy_doorbell > THRESHOLD)
                final_sound <= 2'b10; // Doorbell
            else if (energy_alarm > THRESHOLD)
                final_sound <= 2'b01; // Alarm
            else
                final_sound <= 2'b00; // Silence / Unclassified
        end
    end

endmodule
