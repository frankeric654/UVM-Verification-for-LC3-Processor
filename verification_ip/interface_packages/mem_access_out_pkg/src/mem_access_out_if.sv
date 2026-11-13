interface mem_access_out_if (
    input logic clock,
    input logic reset
);
    logic [15:0] Data_addr;
    logic [15:0] Data_din;
    logic        Data_rd;
    logic [15:0] memout;

    modport DUT (
        input clock, reset,
        output Data_addr, Data_din, Data_rd, memout
    );

    modport MONITOR (
        input clock, reset, Data_addr, Data_din, Data_rd, memout
    );
endinterface
