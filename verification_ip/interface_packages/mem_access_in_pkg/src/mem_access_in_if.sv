interface mem_access_in_if (
    input logic clock,
    input logic reset
);
    logic [1:0]  mem_state;
    logic        M_Control;
    logic [15:0] M_Data;
    logic [15:0] M_Addr;
    logic [15:0] Data_dout;

    modport DUT (
        input clock, reset, mem_state, M_Control, M_Data, M_Addr, Data_dout
    );

    modport MONITOR (
        input clock, reset, mem_state, M_Control, M_Data, M_Addr, Data_dout
    );
endinterface