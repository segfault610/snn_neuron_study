`timescale 1ns/1ps

module izhikevich_neuron #(
    parameter integer MEM_WIDTH = 20,
    parameter integer THRESHOLD_MV = 30
) (
    input  logic clk,
    input  logic rst_n,
    input  logic en,
    input  logic signed [MEM_WIDTH-1:0] current_in,
    output logic spike_out,
    output logic signed [MEM_WIDTH-1:0] membrane_out
);

    // Reduced-order integer-mV approximation of the Izhikevich model.
    // Intended for architecture comparison, not precision simulation.
    logic signed [MEM_WIDTH-1:0] v, u;
    logic signed [63:0] vw, uw, iw, dv, du, vn, un;

    always_comb begin
        vw = v;
        uw = u;
        iw = current_in;

        // Approximate dv/dt = 0.04*v^2 + 5*v + 140 - u + I
        // with a coarse Euler step.
        dv = ((4 * vw * vw) / 100) + (5 * vw) + 140 - uw + iw;
        vn = vw + (dv / 10);

        // Approximate du/dt = 0.02*(0.2*v-u).
        du = ((vw / 5) - uw) / 50;
        un = uw + du;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v <= -65;
            u <= -13;
            spike_out <= 1'b0;
        end else begin
            spike_out <= 1'b0;

            if (en) begin
                if (vn >= THRESHOLD_MV) begin
                    v <= -65;
                    u <= un + 8;
                    spike_out <= 1'b1;
                end else begin
                    v <= vn[MEM_WIDTH-1:0];
                    u <= un[MEM_WIDTH-1:0];
                end
            end
        end
    end

    assign membrane_out = v;

endmodule
