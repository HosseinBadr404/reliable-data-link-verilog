`timescale 1ns / 1ps

module receiver (
    input  wire        clk,
    input  wire        reset,
    input  wire [11:0] destination_start,
    input  wire [15:0] data_in,
    input  wire        parity_in,
    input  wire        req,

    output reg         ack,
    output reg         full,
    output reg  [11:0] destination_address,
    output wire        write_enable,
    output wire        parity_error
);

    wire parity_ok;

    assign parity_ok =
        (^{data_in, parity_in} == 1'b0);

    assign parity_error =
        req && !parity_ok;

    assign write_enable =
        req && parity_ok && !full;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ack                 <= 1'b0;
            full                <= 1'b0;
            destination_address <= destination_start;
        end
        else begin
            ack <= 1'b0;

            if (req && !full && parity_ok) begin
                ack <= 1'b1;

                if (destination_address == 12'hFFF)
                    full <= 1'b1;
                else
                    destination_address <=
                        destination_address + 1'b1;
            end
        end
    end

endmodule