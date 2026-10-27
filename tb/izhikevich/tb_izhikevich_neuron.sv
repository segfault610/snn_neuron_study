`timescale 1ns/1ps

module tb_izhikevich_neuron;

    localparam integer W = 20;

    logic clk = 0;
    logic rst_n = 0;
    logic en = 0;
    logic signed [W-1:0] current_in = 0;

    logic spike_out;
    logic signed [W-1:0] membrane_out;

    izhikevich_neuron #(.MEM_WIDTH(W)) dut (.*);

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/waves/izhikevich_neuron.vcd");
        $dumpvars(0, tb_izhikevich_neuron);

        repeat (2) @(posedge clk);
        rst_n = 1;
        en = 1;
        current_in = 10;

        repeat (100) @(posedge clk);
        current_in = 20;

        repeat (100) @(posedge clk);
        current_in = 0;

        repeat (20) @(posedge clk);
        en = 0;

        $display("Izhikevich TB complete: v=%0d spike=%0b",
                 membrane_out, spike_out);
        $finish;
    end

endmodule
