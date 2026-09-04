`timescale 1ns / 1ps

module transmitter_receiver_top (
    input  wire        clk,
    input  wire        reset,
    input  wire [11:0] source_start,
    input  wire [11:0] destination_start,

    input  wire        source_test_mode,
    input  wire        source_test_we,
    input  wire [11:0] source_test_address,
    input  wire [15:0] source_test_data,

    input  wire        destination_test_mode,
    input  wire        destination_test_we,
    input  wire [11:0] destination_test_address,
    input  wire [15:0] destination_test_data,

    output wire [15:0] destination_test_q,

    output wire [11:0] source_address,
    output wire [11:0] destination_address,
    output wire [15:0] source_memory_data,
    output wire [15:0] transmitted_data,
    output wire [15:0] received_data,
    output wire        parity,
    output wire        req,
    output wire        ack,
    output wire        full,
    output wire        done,
    output wire        error_state,
    output wire        parity_error,
    output wire        destination_write_enable
);

    wire [11:0] source_ram_address;
    wire [15:0] source_ram_input;
    wire        source_ram_we;

    wire [11:0] destination_ram_address;
    wire [15:0] destination_ram_input;
    wire [15:0] destination_ram_output;
    wire        destination_ram_we;

    wire corrupted_d15;

    assign source_ram_address =
        source_test_mode ?
        source_test_address :
        source_address;

    assign source_ram_input = source_test_data;

    assign source_ram_we =
        source_test_mode && source_test_we;

    assign destination_ram_address =
        destination_test_mode ?
        destination_test_address :
        destination_address;

    assign destination_ram_input =
        destination_test_mode ?
        destination_test_data :
        received_data;

    assign destination_ram_we =
        destination_test_mode ?
        destination_test_we :
        destination_write_enable;

    assign destination_test_q =
        destination_ram_output;

    RAM_Block_4096x16 source_ram (
        .Clk      (clk),
        .Rst      (1'b0),
        .WE       (source_ram_we),
        .Address  (source_ram_address),
        .Data_In  (source_ram_input),
        .Data_Out (source_memory_data)
    );

    transmitter tx (
        .clk            (clk),
        .reset          (reset),
        .source_start   (source_start),
        .source_data    (source_memory_data),
        .ack            (ack),
        .full           (full),
        .source_address (source_address),
        .data_out       (transmitted_data),
        .parity_out     (parity),
        .req            (req),
        .done           (done)
    );

    error_injector error_block (
        .clk         (clk),
        .reset       (reset),
        .bit_in      (transmitted_data[15]),
        .bit_out     (corrupted_d15),
        .error_state (error_state)
    );

    assign received_data = {
        corrupted_d15,
        transmitted_data[14:0]
    };

    receiver rx (
        .clk                 (clk),
        .reset               (reset),
        .destination_start   (destination_start),
        .data_in             (received_data),
        .parity_in           (parity),
        .req                 (req),
        .ack                 (ack),
        .full                (full),
        .destination_address (destination_address),
        .write_enable        (destination_write_enable),
        .parity_error        (parity_error)
    );

    RAM_Block_4096x16 destination_ram (
        .Clk      (clk),
        .Rst      (1'b0),
        .WE       (destination_ram_we),
        .Address  (destination_ram_address),
        .Data_In  (destination_ram_input),
        .Data_Out (destination_ram_output)
    );

endmodule