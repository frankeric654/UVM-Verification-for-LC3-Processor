module lc3_ta_probe(
    input logic clk,
    input logic rst
);

    covergroup lc3_ta_probe_cg @(posedge clk);
        option.per_instance = 1;

        cp_reset: coverpoint rst {
            bins asserted = {1'b1};
            bins released = {1'b0};
        }
    endgroup

    lc3_ta_probe_cg cg = new;

    initial begin
`ifndef LC3_TA_BIND_TEST
        $fatal(1, "TA extra vlog argument missing");
`endif
        $display("LC3_TA_BIND_PROBE: instantiated");
    end

endmodule

module lc3_ta_bind_top;

    bind hdl_top lc3_ta_probe ta_probe_i(
        .clk(clock),
        .rst(reset)
    );

endmodule
