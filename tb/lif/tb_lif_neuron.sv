`timescale 1ns/1ps

module tb_lif_neuron;

    localparam integer W = 20;

    logic clk = 0;
    logic rst_n = 0;
    logic en = 0;
    logic signed [W-1:0] current_in = 0;

    logic spike_out;
    logic signed [W-1:0] membrane_out;

    lif_neuron #(
        .MEM_WIDTH(W),
        .THRESHOLD(256)
    ) dut (.*);

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/waves/lif_neuron.vcd");
        $dumpvars(0, tb_lif_neuron);

        repeat (2) @(posedge clk);
        rst_n = 1;
        en = 1;
        current_in = 80;

        repeat (8) @(posedge clk);
        current_in = 300;

        repeat (4) @(posedge clk);
        current_in = 0;

        repeat (4) @(posedge clk);
        en = 0;

        repeat (2) @(posedge clk);
        $display("LIF TB complete: v=%0d spike=%0b",
                 membrane_out, spike_out);
        $finish;
    end

endmodule
