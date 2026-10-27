`timescale 1ns/1ps

module tb_lif_neuron;

    localparam integer MEM_WIDTH = 20;
    localparam integer THRESHOLD = 256;

    logic clk;
    logic rst_n;
    logic en;
    logic signed [MEM_WIDTH-1:0] current_in;

    logic spike_out;
    logic signed [MEM_WIDTH-1:0] membrane_out;

    integer errors;

    lif_neuron #(
        .MEM_WIDTH(MEM_WIDTH),
        .THRESHOLD(THRESHOLD)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .current_in(current_in),
        .spike_out(spike_out),
        .membrane_out(membrane_out)
    );

    // 100 MHz clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic check_state(
        input logic expected_spike,
        input integer expected_membrane,
        input string test_name
    );
        begin
            if ((spike_out !== expected_spike) ||
                (membrane_out !== expected_membrane)) begin

                $error(
                    "%s FAILED: spike=%b membrane=%0d; expected spike=%b membrane=%0d",
                    test_name,
                    spike_out,
                    membrane_out,
                    expected_spike,
                    expected_membrane
                );

                errors = errors + 1;
            end else begin
                $display(
                    "%s PASSED: spike=%b membrane=%0d",
                    test_name,
                    spike_out,
                    membrane_out
                );
            end
        end
    endtask

    initial begin
        $dumpfile("lif_neuron.vcd");
        $dumpvars(0, tb_lif_neuron);

        errors     = 0;
        rst_n      = 1'b0;
        en         = 1'b0;
        current_in = '0;

        // Allow reset to take effect.
        repeat (2) @(negedge clk);
        check_state(1'b0, 0, "Reset");

        // Release reset.
        rst_n = 1'b1;
        en    = 1'b1;

        // Test 1: First update, V = 0 - 0 + 100 = 100.
        current_in = 100;
        @(posedge clk);
        #1;
        check_state(1'b0, 100, "Update 1");

        // Test 2: V = 100 - (100 >>> 2) + 100 = 175.
        @(posedge clk);
        #1;
        check_state(1'b0, 175, "Update 2");

        // Test 3: V = 175 - (175 >>> 2) + 100 = 232.
        // Arithmetic right shift rounds negative values downward;
        // for positive 175, 175 >>> 2 = 43.
        // Therefore the expected value is 232.
        @(posedge clk);
        #1;
        check_state(1'b0, 232, "Update 3");

        // Test 4: V = 232 - (232 >>> 2) + 100 = 274.
        // This crosses the threshold, so the neuron spikes and resets.
        @(posedge clk);
        #1;
        check_state(1'b1, 0, "Threshold crossing");

        // Test 5: Spike must return low after one cycle.
        current_in = 0;
        @(posedge clk);
        #1;
        check_state(1'b0, 0, "Spike pulse width");

        // Test 6: With en=0, membrane must hold its state.
        current_in = 100;
        @(posedge clk);
        #1;
        check_state(1'b0, 100, "Enable test setup");

        en = 1'b0;
        current_in = 50;
        @(posedge clk);
        #1;
        check_state(1'b0, 100, "Enable hold");

        if (errors == 0)
            $display("\nALL LIF NEURON TESTS PASSED");
        else
            $fatal(1, "\nLIF NEURON TEST FAILED: %0d errors", errors);

        $finish;
    end

endmodule
