`timescale 1ns / 1ps

module error_injector (
    input  wire clk,
    input  wire reset,
    input  wire bit_in,
    output wire bit_out,
    output wire error_state
);

    reg flip_state;

    always @(posedge clk or posedge reset) begin
        if (reset)
            flip_state <= 1'b0;
        else
            flip_state <= ~flip_state;
    end

    assign bit_out = bit_in ^ flip_state;
    assign error_state = flip_state;

endmodule