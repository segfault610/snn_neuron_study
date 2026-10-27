`timescale 1ns/1ps

module tb_hodgkin_huxley_neuron;

    localparam integer W = 20;

    logic clk = 0;
    logic rst_n = 0;
    logic en = 0;
    logic signed [W-1:0] current_in = 0;

    logic spike_out;
    logic signed [W-1:0] membrane_out;

    hodgkin_huxley_neuron #(.MEM_WIDTH(W)) dut (.*);

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/waves/hodgkin_huxley_neuron.vcd");
        $dumpvars(0, tb_hodgkin_huxley_neuron);

        repeat (2) @(posedge clk);
        rst_n = 1;
        en = 1;
        current_in = 15;

        repeat (100) @(posedge clk);
        current_in = 25;

        repeat (100) @(posedge clk);
        current_in = 0;

        repeat (20) @(posedge clk);
        en = 0;

        $display("HH TB complete: v=%0d spike=%0b",
                 membrane_out, spike_out);
        $finish;
    end

endmodule
