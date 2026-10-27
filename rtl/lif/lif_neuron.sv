`timescale 1ns/1ps

module lif_neuron #(
    parameter integer MEM_WIDTH = 20,
    parameter integer THRESHOLD = 256
) (
    input  logic clk,
    input  logic rst_n,
    input  logic en,

    input  logic signed [MEM_WIDTH-1:0] current_in,

    output logic spike_out,
    output logic signed [MEM_WIDTH-1:0] membrane_out
);

    logic signed [MEM_WIDTH-1:0] membrane;

    // Extra bits reduce the risk of overflow in intermediate arithmetic.
    logic signed [MEM_WIDTH+1:0] v_extended;
    logic signed [MEM_WIDTH+1:0] current_extended;
    logic signed [MEM_WIDTH+1:0] v_calc;

    always_comb begin
        v_extended       = {{2{membrane[MEM_WIDTH-1]}}, membrane};
        current_extended = {{2{current_in[MEM_WIDTH-1]}}, current_in};

        // LIF update:
        // V_next = V - (V >>> 2) + I
        v_calc = v_extended
               - (v_extended >>> 2)
               + current_extended;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            membrane  <= '0;
            spike_out <= 1'b0;
        end else begin
            // Default: spikes last for one clock cycle.
            spike_out <= 1'b0;

            if (en) begin
                if (v_calc >= THRESHOLD) begin
                    membrane  <= '0;
                    spike_out <= 1'b1;
                end else begin
                    membrane <= v_calc[MEM_WIDTH-1:0];
                end
            end
        end
    end

    assign membrane_out = membrane;

endmodule
