// =============================================================================
// Module: top
// Description: Top-level integration of the Real-Time Audio Captioning / FFT Classifier
//              Synthesizable on Altera Cyclone IV E (EP4CE115F29C7)
// =============================================================================

`timescale 1ns/1ps

module top (
    input  wire       clk,
    input  wire       reset_n,
    output wire [7:0] LEDR,
    output wire [6:0] HEX0,
    output wire [6:0] HEX1
);
    // Avalon-ST Sink Interface (Synthetic Gen -> FFT)
    wire        sink_valid, sink_ready;
    wire [31:0] sink_data;
    wire        sink_sop,   sink_eop;

    // Avalon-ST Source Interface (FFT -> Magnitude)
    wire        source_valid, source_ready;
    wire [63:0] source_data;
    wire        source_sop,   source_eop;

    wire [31:0] magnitude;
    wire [1:0]  final_sound;

    // Always ready to consume FFT output to prevent backpressure stalls
    assign source_ready = 1'b1;

    // 1. Synthetic Sample Frame Generator
    sample_gen u_sample_gen (
        .clk     (clk),
        .reset_n (reset_n),
        .ready   (sink_ready),
        .valid   (sink_valid),
        .data    (sink_data),
        .sop     (sink_sop),
        .eop     (sink_eop)
    );

    // 2. 512-Point Intel FFT Streaming IP Wrapper
    fft_block u_fft (
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

    // 3. Hardware Magnitude Estimator
    magnitude_block u_magnitude (
        .clk         (clk),
        .source_data (source_data),
        .source_valid(source_valid),
        .magnitude   (magnitude)
    );

    // 4. Acoustic Spectral Energy Classifier
    detection_block u_detection (
        .clk        (clk),
        .reset_n    (reset_n),
        .valid      (source_valid),
        .sop        (source_sop),
        .eop        (source_eop),
        .magnitude  (magnitude),
        .final_sound(final_sound)
    );

    // 5. LED & 7-Segment Output Driver
    output_block u_output (
        .clk   (clk),
        .sound (final_sound),
        .led   (LEDR),
        .HEX0  (HEX0),
        .HEX1  (HEX1)
    );

endmodule
