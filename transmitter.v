`timescale 1ns / 1ps

module transmitter (
    input  wire        clk,
    input  wire        reset,
    input  wire [11:0] source_start,
    input  wire [15:0] source_data,
    input  wire        ack,
    input  wire        full,

    output reg  [11:0] source_address,
    output reg  [15:0] data_out,
    output reg         parity_out,
    output reg         req,
    output reg         done
);

    reg stop_after_ack;

    always @(negedge clk or posedge reset) begin
        if (reset) begin
            source_address <= source_start;
            data_out        <= 16'h0000;
            parity_out      <= 1'b0;
            req             <= 1'b0;
            done            <= 1'b0;
            stop_after_ack  <= 1'b0;
        end
        else if (!done) begin

            if (full) begin
                req  <= 1'b0;
                done <= 1'b1;
            end

            else if (!req) begin
                data_out   <= source_data;
                parity_out <= ^source_data;
                req        <= 1'b1;

                stop_after_ack <=
                    (source_data == 16'hFFFF) ||
                    (source_address == 12'hFFF);
            end

            else if (ack) begin
                req <= 1'b0;

                if (stop_after_ack) begin
                    done <= 1'b1;
                end
                else begin
                    source_address <= source_address + 1'b1;
                end
            end
        end
        else begin
            req <= 1'b0;
        end
    end

endmodule