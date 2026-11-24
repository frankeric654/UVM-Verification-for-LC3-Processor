`timescale 1ns/1ps

module mem_access_assertions (
    input logic clock,
    input logic reset,
    input logic complete_data,
    input logic [1:0] mem_state,
    input logic M_Control,
    input logic [15:0] M_Data,
    input logic [15:0] M_Addr,
    input logic [15:0] Data_dout,
    input logic [15:0] Data_addr,
    input logic [15:0] Data_din,
    input logic Data_rd,
    input logic [15:0] memout
);

    property mem_state_reset;
        @(posedge clock) reset |-> mem_state == 2'd3;
    endproperty
    assert property (mem_state_reset)
        else $error("MemAccess: mem_state did not return to idle after reset");

    property wait_in_active_state;
        @(posedge clock) disable iff (reset)
            (!complete_data && mem_state inside {2'd0,2'd1,2'd2})
            |=> mem_state inside {2'd0,2'd1,2'd2};
    endproperty
    assert property (wait_in_active_state)
        else $error("MemAccess: active mem_state changed before complete_data");

    property legal_state_transition;
        @(posedge clock) disable iff (reset)
            mem_state == 2'd3 |=> mem_state inside {2'd0,2'd1,2'd2,2'd3}
    endproperty
    assert property (legal_state_transition)
        else $error("MemAccess: illegal idle-state transition");

    property dmem_rd_by_state;
        @(posedge clock) disable iff (reset)
            (mem_state == 2'd0 || mem_state == 2'd1) |-> Data_rd === 1'b1;
    endproperty
    assert property (dmem_rd_by_state)
        else $error("MemAccess: Data_rd must be 1 in read states");

    property dmem_rd_write;
        @(posedge clock) disable iff (reset)
            mem_state == 2'd2 |-> Data_rd === 1'b0;
    endproperty
    assert property (dmem_rd_write)
        else $error("MemAccess: Data_rd must be 0 in write state");

    property idle_tristate;
        @(posedge clock) disable iff (reset)
            mem_state == 2'd3 |-> (Data_addr === 16'hzzzz &&
                                   Data_din === 16'hzzzz &&
                                   Data_rd === 1'bz);
    endproperty
    assert property (idle_tristate)
        else $error("MemAccess: idle outputs are not high impedance");

    property dmem_din_by_state;
        @(posedge clock) disable iff (reset)
            (mem_state == 2'd0 || mem_state == 2'd1) |->
                (Data_din === 16'h0000);
    endproperty
    assert property (dmem_din_by_state)
        else $error("MemAccess: DMem_din must be zero in read states");

    property dmem_din_write;
        @(posedge clock) disable iff (reset)
            mem_state == 2'd2 |-> Data_din === M_Data;
    endproperty
    assert property (dmem_din_write)
        else $error("MemAccess: DMem_din does not equal M_Data in write state");

    property dmem_addr_direct;
        @(posedge clock) disable iff (reset)
            ((mem_state == 2'd1) ||
             (mem_state == 2'd0 && M_Control == 1'b0) ||
             (mem_state == 2'd2 && M_Control == 1'b0))
            |-> Data_addr === M_Addr;
    endproperty
    assert property (dmem_addr_direct)
        else $error("MemAccess: direct address source mismatch");

    property dmem_addr_indirect;
        @(posedge clock) disable iff (reset)
            ((mem_state == 2'd0 || mem_state == 2'd2) &&
             M_Control == 1'b1)
            |-> Data_addr === Data_dout;
    endproperty
    assert property (dmem_addr_indirect)
        else $error("MemAccess: indirect address source mismatch");

    property memout_follows_dmem_dout;
        @(posedge clock) memout === Data_dout;
    endproperty
    assert property (memout_follows_dmem_dout)
        else $error("MemAccess: memout does not follow DMem_dout");

endmodule
