// =============================================================================
// Module: sample_gen
// Description: Deterministic synthetic audio frame generator for Intel FFT IP
//              Generates 512-sample frames with valid/ready Avalon-ST protocol
//              Outputs SOP (sample 0) and EOP (sample 511)
// =============================================================================

`timescale 1ns/1ps

module sample_gen (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        ready,
    output reg         valid,
    output reg  [31:0] data,
    output reg         sop,
    output reg         eop
);
    reg [8:0] count;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            count <= 9'd0;
            valid <= 1'b0;
        end else if (ready) begin
            valid <= 1'b1;
            if (count == 9'd511)
                count <= 9'd0;
            else
                count <= count + 1'b1;
        end
    end

    always @(posedge clk) begin
        sop  <= (count == 9'd0);
        eop  <= (count == 9'd511);
        // Deterministic synthetic ramp test signal (upper 16 bits active)
        data <= count << 16;
    end

endmodule
