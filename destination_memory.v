`timescale 1ns / 1ps

module destination_memory (
    input  wire        clk,
    input  wire        write_enable,
    input  wire [11:0] address,
    input  wire [15:0] data_in
);

    reg [15:0] memory [0:4095];

    always @(posedge clk) begin
        if (write_enable)
            memory[address] <= data_in;
    end

endmodule