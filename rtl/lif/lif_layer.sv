`timescale 1ns/1ps

module lif_layer #(
    parameter integer N = 16,
    parameter integer MEM_WIDTH = 20,
    parameter integer CURRENT_WIDTH = 20,
    parameter integer THRESHOLD = 256
) (
    input logic clk,
    input logic rst_n,
    input logic en,
    input logic [N*CURRENT_WIDTH-1:0] current_bus,
    output logic [N-1:0] spike_bus,
    output logic [N*MEM_WIDTH-1:0] membrane_bus
);

    genvar i;

    generate
        for (i = 0; i < N; i = i + 1) begin : GEN_LIF
            lif_neuron #(
                .MEM_WIDTH(MEM_WIDTH),
                .THRESHOLD(THRESHOLD)
            ) u_neuron (
                .clk(clk),
                .rst_n(rst_n),
                .en(en),
                .current_in(current_bus[i*CURRENT_WIDTH +: CURRENT_WIDTH]),
                .spike_out(spike_bus[i]),
                .membrane_out(membrane_bus[i*MEM_WIDTH +: MEM_WIDTH])
            );
        end
    endgenerate

endmodule
