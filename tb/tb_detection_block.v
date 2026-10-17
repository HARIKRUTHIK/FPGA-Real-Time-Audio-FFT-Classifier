`timescale 1ns/1ps

module tb_detection_block;

    reg         clk;
    reg         reset_n;
    reg         valid;
    reg         sop;
    reg         eop;
    reg  [31:0] magnitude;
    wire [1:0]  final_sound;

    detection_block #(
        .THRESHOLD(64'd1000)
    ) uut (
        .clk(clk),
        .reset_n(reset_n),
        .valid(valid),
        .sop(sop),
        .eop(eop),
        .magnitude(magnitude),
        .final_sound(final_sound)
    );

    always #5 clk = ~clk;

    integer b;
    integer errors = 0;

    initial begin
        clk = 0;
        reset_n = 0;
        valid = 0;
        sop = 0;
        eop = 0;
        magnitude = 0;
        #20;
        reset_n = 1;
        #10;

        $display("=================================================================");
        $display("   DETECTION BLOCK ACOUSTIC CLASSIFIER VERIFICATION");
        $display("=================================================================");

        // Simulate Frame 1: Alarm Tone injected at bins 6-10 (800 Hz)
        @(posedge clk); #1 sop = 1; valid = 1; magnitude = 0;
        @(posedge clk); #1 sop = 0;

        for (b = 0; b < 512; b = b + 1) begin
            valid = 1;
            if (b >= 6 && b <= 10)
                magnitude = 32'd500; // Energy will be 5 * 500 = 2500 > THRESHOLD (1000)
            else
                magnitude = 32'd10;

            if (b == 511) eop = 1;
            else          eop = 0;
            @(posedge clk); #1;
        end
        valid = 0; eop = 0;
        #20;

        if (final_sound !== 2'b01) begin
            $display("[ERROR] Alarm Detection Failed: Expected 2'b01, Got %b", final_sound);
            errors = errors + 1;
        end else begin
            $display("[PASS] Alarm Sound Signature (800 Hz) correctly classified as 2'b01");
        end

        // Simulate Frame 2: Attention Tone injected at bins 29-35 (3 kHz)
        @(posedge clk); #1 sop = 1; valid = 1; magnitude = 0;
        @(posedge clk); #1 sop = 0;

        for (b = 0; b < 512; b = b + 1) begin
            valid = 1;
            if (b >= 29 && b <= 35)
                magnitude = 32'd600; // Energy will be 7 * 600 = 4200 > THRESHOLD
            else
                magnitude = 32'd5;

            if (b == 511) eop = 1;
            else          eop = 0;
            @(posedge clk); #1;
        end
        valid = 0; eop = 0;
        #20;

        if (final_sound !== 2'b11) begin
            $display("[ERROR] Attention Detection Failed: Expected 2'b11, Got %b", final_sound);
            errors = errors + 1;
        end else begin
            $display("[PASS] Attention Sound Signature (3 kHz) correctly classified as 2'b11");
        end

        $display("-----------------------------------------------------------------");
        if (errors == 0)
            $display("[RESULT] ALL DETECTION BLOCK TESTS PASSED");
        else
            $display("[RESULT] FAILED: %0d Discrepancies Detected", errors);
        $display("=================================================================");
        $finish;
    end

endmodule
