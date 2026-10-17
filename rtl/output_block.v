// =============================================================================
// Module: output_block
// Description: Drives 8-Bit Red LEDs (LEDR) and dual Seven-Segment Displays (HEX0/HEX1)
//              Encoding: 'A'=Alarm, 'd'=Doorbell, 't'=Attention, 'n'=None/Silence
// =============================================================================

`timescale 1ns/1ps

module output_block (
    input  wire       clk,
    input  wire [1:0] sound,
    output reg  [7:0] led,
    output reg  [6:0] HEX0,
    output reg  [6:0] HEX1
);
    // LED Output Mapping
    always @(posedge clk) begin
        case (sound)
            2'b01:   led <= 8'b00000001; // ALARM     -> LED0
            2'b10:   led <= 8'b00000010; // DOORBELL  -> LED1
            2'b11:   led <= 8'b00000100; // ATTENTION -> LED2
            default: led <= 8'b00000000;
        endcase
    end

    // Seven-Segment Active-Low Display Encoding
    always @(posedge clk) begin
        case (sound)
            2'b01: begin // 'A' - ALARM
                HEX1 <= 7'b0001000;
                HEX0 <= 7'b0001000;
            end
            2'b10: begin // 'd' - DOORBELL
                HEX1 <= 7'b0100001;
                HEX0 <= 7'b0100001;
            end
            2'b11: begin // 't' - ATTENTION
                HEX1 <= 7'b0000111;
                HEX0 <= 7'b0000111;
            end
            default: begin // 'n' - NONE / SILENCE
                HEX1 <= 7'b0101011;
                HEX0 <= 7'b0101011;
            end
        endcase
    end

endmodule
