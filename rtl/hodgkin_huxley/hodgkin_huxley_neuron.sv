`timescale 1ns/1ps

module hodgkin_huxley_neuron #(
    parameter integer MEM_WIDTH = 20,
    parameter integer THRESHOLD_MV = -20
) (
    input  logic clk,
    input  logic rst_n,
    input  logic en,
    input  logic signed [MEM_WIDTH-1:0] current_in,
    output logic spike_out,
    output logic signed [MEM_WIDTH-1:0] membrane_out
);

    // Reduced-order, synthesizable HH-inspired approximation.
    // v is integer mV; m, h, n are Q10 gating-state approximations.
    // Linearized kinetics replace the exponential HH equations.
    logic signed [MEM_WIDTH-1:0] v;
    logic [10:0] m, h, n;

    logic signed [63:0] vw, ina, ik, il, dv, vn;
    logic signed [31:0] mt, ht, nt, mn, hn, nn;

    always_comb begin
        vw = v;

        // Approximate steady-state gate targets and clamp to [0, 1024].
        mt = (vw + 60) * 16;
        if (mt < 0)    mt = 0;
        if (mt > 1024) mt = 1024;

        ht = 512 - ((vw + 40) * 12);
        if (ht < 0)    ht = 0;
        if (ht > 1024) ht = 1024;

        nt = (vw + 55) * 12;
        if (nt < 0)    nt = 0;
        if (nt > 1024) nt = 1024;

        // First-order relaxation toward the gate targets.
        mn = $signed({1'b0,m})
           + (($signed(mt) - $signed({1'b0,m})) >>> 3);

        hn = $signed({1'b0,h})
           + (($signed(ht) - $signed({1'b0,h})) >>> 4);

        nn = $signed({1'b0,n})
           + (($signed(nt) - $signed({1'b0,n})) >>> 4);

        // Simplified ionic-current terms.
        ina = (m * m * h * (vw - 50)) >>> 30;
        ik  = (n * n * (vw + 77)) >>> 20;
        il  = vw + 54;

        dv = $signed(current_in) - ina - ik - il;
        vn = vw + (dv >>> 3);
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v <= -65;
            m <= 55;
            h <= 630;
            n <= 60;
            spike_out <= 1'b0;
        end else begin
            spike_out <= 1'b0;

            if (en) begin
                v <= vn[MEM_WIDTH-1:0];

                m <= (mn < 0) ? 0 :
                     ((mn > 1024) ? 11'd1024 : mn[10:0]);

                h <= (hn < 0) ? 0 :
                     ((hn > 1024) ? 11'd1024 : hn[10:0]);

                n <= (nn < 0) ? 0 :
                     ((nn > 1024) ? 11'd1024 : nn[10:0]);

                if ((v < THRESHOLD_MV) && (vn >= THRESHOLD_MV))
                    spike_out <= 1'b1;
            end
        end
    end

    assign membrane_out = v;

endmodule
