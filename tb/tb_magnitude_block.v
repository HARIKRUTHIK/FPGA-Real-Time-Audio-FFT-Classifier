`timescale 1ns/1ps

module tb_magnitude_block;

    reg         clk;
    reg  [63:0] source_data;
    reg         source_valid;
    wire [31:0] magnitude;

    magnitude_block uut (
        .clk(clk),
        .source_data(source_data),
        .source_valid(source_valid),
        .magnitude(magnitude)
    );

    always #5 clk = ~clk;

    integer errors = 0;

    initial begin
        clk = 0;
        source_valid = 0;
        source_data = 0;
        #15;

        $display("=================================================================");
        $display("   MAGNITUDE BLOCK VERIFICATION");
        $display("=================================================================");

        // Test 1: Real dominant (|Real| = 1000, |Imag| = 200)
        source_valid = 1;
        source_data = {1'b0, 31'd1000, 1'b0, 31'd200};
        @(posedge clk); #1;
        if (magnitude !== 32'd1000) begin
            $display("[ERROR] Real-dominant test failed: Expected 1000, Got %0d", magnitude);
            errors = errors + 1;
        end

        // Test 2: Imag dominant (|Real| = 150, |Imag| = 4500)
        source_data = {1'b0, 31'd150, 1'b0, 31'd4500};
        @(posedge clk); #1;
        if (magnitude !== 32'd4500) begin
            $display("[ERROR] Imag-dominant test failed: Expected 4500, Got %0d", magnitude);
            errors = errors + 1;
        end

        // Test 3: Negative signed components (|Real| = -800, |Imag| = 300)
        source_data = {1'b1, 31'd800, 1'b0, 31'd300};
        @(posedge clk); #1;
        if (magnitude !== 32'd800) begin
            $display("[ERROR] Negative Real test failed: Expected 800, Got %0d", magnitude);
            errors = errors + 1;
        end

        source_valid = 0;
        #10;
        $display("-----------------------------------------------------------------");
        if (errors == 0)
            $display("[RESULT] ALL MAGNITUDE BLOCK TESTS PASSED");
        else
            $display("[RESULT] FAILED: %0d Discrepancies Detected", errors);
        $display("=================================================================");
        $finish;
    end

endmodule
