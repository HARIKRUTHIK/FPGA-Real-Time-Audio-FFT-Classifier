// =============================================================================
// Module: fft_block
// Description: Avalon-ST Streaming Wrapper for 512-Point Intel/Altera FFT IP
// =============================================================================

`timescale 1ns/1ps

module fft_block (
    input  wire        clk,
    input  wire        reset_n,
    // Sink Interface (Input)
    input  wire        sink_valid,
    output wire        sink_ready,
    input  wire [31:0] sink_data,
    input  wire        sink_sop,
    input  wire        sink_eop,
    // Source Interface (Output)
    output wire        source_valid,
    input  wire        source_ready,
    output wire [63:0] source_data,
    output wire        source_sop,
    output wire        source_eop
);
    // Instantiate Intel/Altera FFT MegaCore instance
    // [63:32] = Real Part (IEEE-754 / Fixed Point), [31:0] = Imaginary Part
    audio_fft fft_inst (
        .clk          (clk),
        .reset_n      (reset_n),
        .sink_valid   (sink_valid),
        .sink_ready   (sink_ready),
        .sink_data    (sink_data),
        .sink_sop     (sink_sop),
        .sink_eop     (sink_eop),
        .source_valid (source_valid),
        .source_ready (source_ready),
        .source_data  (source_data),
        .source_sop   (source_sop),
        .source_eop   (source_eop)
    );

endmodule
