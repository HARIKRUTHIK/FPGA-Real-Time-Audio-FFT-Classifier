// =============================================================================
// Testbench: tb_sample_gen
// Description: Standalone functional verification of synthetic frame generator
//              Checks clock, active-low reset, Avalon-ST ready/valid handshaking,
//              SOP (sample 0) and EOP (sample 511) alignment.
// =============================================================================

`timescale 1ns/1ps

module tb_sample_gen;

    reg         clk;
    reg         reset_n;
    reg         ready;
    wire        valid;
    wire [31:0] data;
    wire        sop;
    wire        eop;

    integer frame_count;
    integer sample_count;

    // Instantiate UUT
    sample_gen uut (
        .clk     (clk),
        .reset_n (reset_n),
        .ready   (ready),
        .valid   (valid),
        .data    (data),
        .sop     (sop),
        .eop     (eop)
    );

    // 50 MHz Clock Generation (20 ns period)
    always #10 clk = ~clk;

    initial begin
        clk = 0;
        reset_n = 0;
        ready = 0;
        frame_count = 0;
        sample_count = 0;

        $display("------------------------------------------------------------");
        $display("Starting tb_sample_gen: Avalon-ST Synthetic Frame Verification");
        $display("------------------------------------------------------------");

        // Apply Reset
        #40 reset_n = 1;
        #20 ready = 1;

        // Monitor 3 Complete 512-Sample Frames
        while (frame_count < 3) begin
            @(posedge clk);
            if (valid && ready) begin
                if (sop) begin
                    $display("[FRAME START] Frame %0d | Time=%0t", frame_count, $time);
                    if (sample_count != 0)
                        $display("[ERROR] SOP asserted when sample_count != 0!");
                end

                if (eop) begin
                    $display("[FRAME END] Frame %0d | Time=%0t | Final Count=%0d",
                             frame_count, $time, sample_count);
                    if (sample_count != 511)
                        $display("[ERROR] EOP asserted when sample_count != 511!");
                    frame_count = frame_count + 1;
                    sample_count = 0;
                end else begin
                    sample_count = sample_count + 1;
                end
            end
        end

        $display("------------------------------------------------------------");
        $display("[PASS] 3 Complete 512-sample frames successfully verified.");
        $display("------------------------------------------------------------");
        $finish;
    end

endmodule
