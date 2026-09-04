`timescale 1ns / 1ps

module source_memory (
    input  wire [11:0] address,
    output wire [15:0] data_out
);

    reg [15:0] memory [0:4095];

    assign data_out = memory[address];

endmodule