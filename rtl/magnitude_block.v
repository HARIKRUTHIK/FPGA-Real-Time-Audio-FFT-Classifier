// =============================================================================
// Module: magnitude_block
// Description: Hardware-efficient magnitude estimator for complex FFT output
//              Approximates magnitude = max(|Real|, |Imag|) avoiding floating-point sqrt
// =============================================================================

`timescale 1ns/1ps

module magnitude_block (
    input  wire        clk,
    input  wire [63:0] source_data,
    input  wire        source_valid,
    output reg  [31:0] magnitude
);
    // FFT output layout:
    // [63:32] = Real part
    // [31:0]  = Imag part
    // Bit 63 / 31 are sign bits; bits [62:32] and [30:0] represent absolute magnitude
    wire [30:0] abs_real = source_data[62:32];
    wire [30:0] abs_imag = source_data[30:0];

    always @(posedge clk) begin
        if (source_valid) begin
            if (abs_real > abs_imag)
                magnitude <= {1'b0, abs_real};
            else
                magnitude <= {1'b0, abs_imag};
        end
    end

endmodule
