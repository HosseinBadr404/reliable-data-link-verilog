`timescale 1ns / 1ps

module transmitter_receiver_tb;

    reg clk;
    reg reset;
    reg [11:0] source_start;
    reg [11:0] destination_start;

    reg source_test_mode;
    reg source_test_we;
    reg [11:0] source_test_address;
    reg [15:0] source_test_data;

    reg destination_test_mode;
    reg destination_test_we;
    reg [11:0] destination_test_address;
    reg [15:0] destination_test_data;

    wire [15:0] destination_test_q;

    wire [11:0] source_address;
    wire [11:0] destination_address;
    wire [15:0] source_memory_data;
    wire [15:0] transmitted_data;
    wire [15:0] received_data;
    wire parity;
    wire req;
    wire ack;
    wire full;
    wire done;
    wire error_state;
    wire parity_error;
    wire destination_write_enable;

    integer errors;
    integer retry_count;

    transmitter_receiver_top dut (
        .clk(clk),
        .reset(reset),
        .source_start(source_start),
        .destination_start(destination_start),

        .source_test_mode(source_test_mode),
        .source_test_we(source_test_we),
        .source_test_address(source_test_address),
        .source_test_data(source_test_data),

        .destination_test_mode(destination_test_mode),
        .destination_test_we(destination_test_we),
        .destination_test_address(destination_test_address),
        .destination_test_data(destination_test_data),

        .destination_test_q(destination_test_q),

        .source_address(source_address),
        .destination_address(destination_address),
        .source_memory_data(source_memory_data),
        .transmitted_data(transmitted_data),
        .received_data(received_data),
        .parity(parity),
        .req(req),
        .ack(ack),
        .full(full),
        .done(done),
        .error_state(error_state),
        .parity_error(parity_error),
        .destination_write_enable(destination_write_enable)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        #1;
        if (!reset && req && !ack && !full)
            retry_count = retry_count + 1;
    end

    task write_source_ram;
        input [11:0] address_value;
        input [15:0] data_value;
        begin
            @(negedge clk);
            #1;

            source_test_mode = 1'b1;
            source_test_we = 1'b1;
            source_test_address = address_value;
            source_test_data = data_value;

            @(posedge clk);
            #1;

            source_test_we = 1'b0;
        end
    endtask

    task write_destination_ram;
        input [11:0] address_value;
        input [15:0] data_value;
        begin
            @(negedge clk);
            #1;

            destination_test_mode = 1'b1;
            destination_test_we = 1'b1;
            destination_test_address = address_value;
            destination_test_data = data_value;

            @(posedge clk);
            #1;

            destination_test_we = 1'b0;
        end
    endtask

    task start_system;
        input [11:0] source_value;
        input [11:0] destination_value;
        begin
            source_start = source_value;
            destination_start = destination_value;

            source_test_we = 1'b0;
            destination_test_we = 1'b0;
            reset = 1'b1;

            @(negedge clk);
            #1;

            source_test_mode = 1'b0;
            destination_test_mode = 1'b0;

            @(posedge clk);
            #1;

            @(negedge clk);
            #1;

            reset = 1'b0;
        end
    endtask

    task stop_and_reset_system;
        begin
            @(negedge clk);
            #1;

            source_test_mode = 1'b1;
            destination_test_mode = 1'b1;
            source_test_we = 1'b0;
            destination_test_we = 1'b0;
            reset = 1'b1;
        end
    endtask

    task read_and_check_destination;
        input [11:0] address_value;
        input [15:0] expected_value;
        input [511:0] message;
        begin
            @(negedge clk);
            #1;

            destination_test_mode = 1'b1;
            destination_test_we = 1'b0;
            destination_test_address = address_value;

            @(posedge clk);
            #1;

            if (destination_test_q !== expected_value) begin
                $display(
                    "ERROR: %0s expected=%h actual=%h",
                    message,
                    expected_value,
                    destination_test_q
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS : %0s value=%h",
                    message,
                    destination_test_q
                );
            end
        end
    endtask

    task wait_for_done;
        integer cycle_count;
        begin
            cycle_count = 0;

            while ((done !== 1'b1) &&
                   (cycle_count < 200)) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
            end

            if (done !== 1'b1) begin
                $display("ERROR: Timeout while waiting for done");
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        source_start = 12'd0;
        destination_start = 12'd0;

        source_test_mode = 1'b1;
        source_test_we = 1'b0;
        source_test_address = 12'd0;
        source_test_data = 16'h0000;

        destination_test_mode = 1'b1;
        destination_test_we = 1'b0;
        destination_test_address = 12'd0;
        destination_test_data = 16'h0000;

        errors = 0;
        retry_count = 0;

        $display("");
        $display("========== TEST 1 ==========");

        write_source_ram(12'd10, 16'h1234);
        write_source_ram(12'd11, 16'hABCD);
        write_source_ram(12'd12, 16'h0055);
        write_source_ram(12'd13, 16'hFFFF);
        write_source_ram(12'd14, 16'h7777);

        write_destination_ram(12'd100, 16'h0000);
        write_destination_ram(12'd101, 16'h0000);
        write_destination_ram(12'd102, 16'h0000);
        write_destination_ram(12'd103, 16'h0000);
        write_destination_ram(12'd104, 16'hBEEF);

        retry_count = 0;

        start_system(12'd10, 12'd100);
        wait_for_done();
        stop_and_reset_system();

        read_and_check_destination(
            12'd100,
            16'h1234,
            "Destination address 100"
        );

        read_and_check_destination(
            12'd101,
            16'hABCD,
            "Destination address 101"
        );

        read_and_check_destination(
            12'd102,
            16'h0055,
            "Destination address 102"
        );

        read_and_check_destination(
            12'd103,
            16'hFFFF,
            "Destination address 103"
        );

        read_and_check_destination(
            12'd104,
            16'hBEEF,
            "Data after FFFF was not copied"
        );

        if (retry_count == 0) begin
            $display("ERROR: No retry was observed");
            errors = errors + 1;
        end
        else begin
            $display(
                "PASS : Retry behavior observed %0d time(s)",
                retry_count
            );
        end

        $display("");
        $display("========== TEST 2 ==========");

        write_source_ram(12'd4094, 16'h1111);
        write_source_ram(12'd4095, 16'h2222);

        write_destination_ram(12'd200, 16'h0000);
        write_destination_ram(12'd201, 16'h0000);
        write_destination_ram(12'd202, 16'hCAFE);

        retry_count = 0;

        start_system(12'd4094, 12'd200);
        wait_for_done();
        stop_and_reset_system();

        read_and_check_destination(
            12'd200,
            16'h1111,
            "Source address 4094 copied"
        );

        read_and_check_destination(
            12'd201,
            16'h2222,
            "Source address 4095 copied"
        );

        read_and_check_destination(
            12'd202,
            16'hCAFE,
            "Stopped after source address 4095"
        );

        $display("");
        $display("========== TEST 3 ==========");

        write_source_ram(12'd20, 16'hAAAA);
        write_source_ram(12'd21, 16'hBBBB);
        write_source_ram(12'd22, 16'hCCCC);

        write_destination_ram(12'd4094, 16'h0000);
        write_destination_ram(12'd4095, 16'h0000);

        retry_count = 0;

        start_system(12'd20, 12'd4094);
        wait_for_done();

        if (full !== 1'b1) begin
            $display("ERROR: Full flag was not asserted");
            errors = errors + 1;
        end
        else begin
            $display("PASS : Full flag asserted");
        end

        stop_and_reset_system();

        read_and_check_destination(
            12'd4094,
            16'hAAAA,
            "Destination address 4094"
        );

        read_and_check_destination(
            12'd4095,
            16'hBBBB,
            "Destination address 4095"
        );

        $display("");

        if (errors == 0)
            $display("ALL TESTS PASSED SUCCESSFULLY");
        else
            $display(
                "SIMULATION FINISHED WITH %0d ERROR(S)",
                errors
            );

        #20;
        $finish;
    end

endmodule