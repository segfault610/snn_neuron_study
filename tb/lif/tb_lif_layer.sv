`timescale 1ns/1ps

module tb_lif_layer;
    localparam N = 4;
    localparam W = 20;

    logic clk = 0;
    logic rst_n = 0;
    logic en = 0;
    logic [N*W-1:0] current_bus = '0;

    logic [N-1:0] spike_bus;
    logic [N*W-1:0] membrane_bus;

    lif_layer #(.N(N), .MEM_WIDTH(W), .CURRENT_WIDTH(W)) dut (
        .clk(clk), .rst_n(rst_n), .en(en),
        .current_bus(current_bus),
        .spike_bus(spike_bus),
        .membrane_bus(membrane_bus)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/waves/lif_layer.vcd");
        $dumpvars(0, tb_lif_layer);

        repeat (2) @(negedge clk);
        rst_n = 1;
        en = 1;

        current_bus[0*W +: W] = 20'sd80;
        current_bus[1*W +: W] = 20'sd120;
        current_bus[2*W +: W] = 20'sd200;
        current_bus[3*W +: W] = 20'sd300;

        repeat (12) @(negedge clk);

        $display("LIF layer: spikes=%b", spike_bus);
        $display("LIF layer: v0=%0d v1=%0d v2=%0d v3=%0d",
            $signed(membrane_bus[0*W +: W]),
            $signed(membrane_bus[1*W +: W]),
            $signed(membrane_bus[2*W +: W]),
            $signed(membrane_bus[3*W +: W]));

        $finish;
    end
endmodule
