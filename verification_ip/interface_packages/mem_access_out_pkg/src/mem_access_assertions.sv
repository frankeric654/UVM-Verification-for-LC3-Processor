`timescale 1ns/1ps

module mem_access_assertions (
    input logic clock,
    input logic reset,
    input logic complete_data,
    input logic [1:0] mem_state,
    input logic [15:0] IR_Exec,
    input logic M_Control,
    input logic [15:0] M_Data,
    input logic [15:0] M_Addr,
    input logic [15:0] Data_dout,
    input logic [15:0] Data_addr,
    input logic [15:0] Data_din,
    input logic Data_rd,
    input logic [15:0] memout,
    input logic enable_updatePC,
    input logic enable_fetch,
    input logic enable_decode,
    input logic enable_execute,
    input logic enable_writeback,
    input logic bypass_alu_1,
    input logic bypass_alu_2,
    input logic bypass_mem_1,
    input logic bypass_mem_2
);

    logic [1:0] previous_mem_state = 2'd3;
    logic previous_complete_data = 1'b0;
    bit state_history_valid = 1'b0;

    property mem_state_reset;
        @(posedge clock) reset |=> (mem_state == 2'd3 &&
                                    !enable_updatePC &&
                                    !enable_decode &&
                                    !enable_execute &&
                                    !enable_writeback &&
                                    !bypass_alu_1 &&
                                    !bypass_alu_2 &&
                                    !bypass_mem_1 &&
                                    !bypass_mem_2);
    endproperty
    assert property (mem_state_reset)
        else $error("MemAccess: mem_state did not return to idle after reset");

    // Allow one sampled-cycle delay between the memory completion pulse and
    // the controller's state update.
    always @(posedge clock) begin
        #1step;
        if (reset) begin
            previous_mem_state = mem_state;
            previous_complete_data = complete_data;
            state_history_valid = 1'b1;
        end else begin
            if (state_history_valid) begin
                bit legal_transition;
                legal_transition = mem_state inside {2'd0,2'd1,2'd2,2'd3};
                if (previous_mem_state inside {2'd0,2'd1,2'd2} &&
                    mem_state != previous_mem_state)
                    legal_transition &= (complete_data || previous_complete_data);

                assert (legal_transition)
                    else $error("MemAccess: invalid or uncompleted transition %0d -> %0d (complete_data=%b previous=%b)",
                                previous_mem_state, mem_state, complete_data,
                                previous_complete_data);
            end
            previous_mem_state = mem_state;
            previous_complete_data = complete_data;
        end
    end

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

    property no_x_on_active_outputs;
        @(posedge clock) disable iff (reset)
            mem_state != 2'd3 |->
                (!$isunknown(Data_addr) &&
                 !$isunknown(Data_din) &&
                 !$isunknown(Data_rd));
    endproperty
    assert property (no_x_on_active_outputs)
        else $error("MemAccess: active outputs contain X");

    property m_control_is_indirect_opcode;
        @(posedge clock) disable iff (reset)
            M_Control |-> (IR_Exec[15:12] inside {4'hA,4'hB});
    endproperty
    assert property (m_control_is_indirect_opcode)
        else $error("MemAccess: M_Control asserted for a non-LDI/STI instruction");

    property state_requires_memory_opcode;
        @(posedge clock) disable iff (reset)
            mem_state != 2'd3 |->
                (IR_Exec[15:12] inside {4'h2,4'h3,4'h6,4'h7,4'hA,4'hB});
    endproperty
    assert property (state_requires_memory_opcode)
        else $error("MemAccess: active memory state without a memory instruction");

    property pipeline_stalls_during_memory;
        @(posedge clock) disable iff (reset)
            mem_state != 2'd3 |->
                (!enable_updatePC && !enable_fetch && !enable_decode &&
                 !enable_execute && !enable_writeback);
    endproperty
    assert property (pipeline_stalls_during_memory)
        else $error("Controller: pipeline enable asserted during memory access");

    property stores_do_not_write_registers;
        @(posedge clock) disable iff (reset)
            (IR_Exec[15:12] inside {4'h3,4'h7,4'hB}) |->
                !enable_writeback;
    endproperty
    assert property (stores_do_not_write_registers)
        else $error("Controller: writeback enabled for a store instruction");

endmodule
