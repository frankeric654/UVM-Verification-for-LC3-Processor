class mem_access_in_coverage extends uvm_subscriber #(mem_access_in_transaction);
    `uvm_component_utils(mem_access_in_coverage)

    mem_access_in_transaction coverage_trans;
    bit [7:0] state_path;
    bit [1:0] prev_state;
    bit [1:0] prev_prev_state;
    bit [1:0] prev_prev_prev_state;
    bit sequence_started;

    covergroup cg_mem_access_in;
        option.per_instance = 1;
        cp_mem_state : coverpoint coverage_trans.mem_state {
            bins load_indirect = {2'd0};
            bins load_direct   = {2'd1};
            bins store         = {2'd2};
            bins idle          = {2'd3};
            illegal_bins invalid_state = default;
        }
        cp_m_control : coverpoint coverage_trans.M_Control {
            bins direct = {1'b0};
            bins indirect = {1'b1};
        }

        cp_m_addr : coverpoint coverage_trans.M_Addr {
            bins zero = {16'h0000};
            bins one = {16'h0001};
            bins low = {[16'h0002:16'h2FFF]};
            bins instruction_area = {[16'h3000:16'h3FFF]};
            bins mid = {[16'h4000:16'h7FFF]};
            bins high = {[16'h8000:16'hFFFE]};
            bins maximum = {16'hFFFF};
        }
        cp_m_data : coverpoint coverage_trans.M_Data {
            bins zero = {16'h0000};
            bins one = {16'h0001};
            bins two_to_positive = {[16'h0002:16'h7FFE]};
            bins max_positive = {16'h7FFF};
            bins min_negative = {16'h8000};
            bins negative_to_max = {[16'h8001:16'hFFFE]};
            bins all_ones = {16'hFFFF};
            bins pattern_5555 = {16'h5555};
            bins pattern_aaaa = {16'hAAAA};
            illegal_bins unknown_store = default;
        }
        cp_dmem_dout : coverpoint coverage_trans.Data_dout {
            bins zero = {16'h0000};
            bins one = {16'h0001};
            bins two_to_positive = {[16'h0002:16'h7FFE]};
            bins max_positive = {16'h7FFF};
            bins min_negative = {16'h8000};
            bins negative_to_max = {[16'h8001:16'hFFFE]};
            bins all_ones = {16'hFFFF};
            bins pattern_5555 = {16'h5555};
            bins pattern_aaaa = {16'hAAAA};
            illegal_bins unknown = default;
        }

        m_data_class : coverpoint coverage_trans.M_Data {
            bins zero = {16'h0000};
            bins positive = {[16'h0001:16'h7FFF]};
            bins negative = {[16'h8000:16'hFFFE]};
            bins all_ones = {16'hFFFF};
        }
        dmem_dout_class : coverpoint coverage_trans.Data_dout {
            bins zero = {16'h0000};
            bins positive = {[16'h0001:16'h7FFF]};
            bins negative = {[16'h8000:16'hFFFE]};
            bins all_ones = {16'hFFFF};
        }

        cx_state_mctrl : cross cp_mem_state, cp_m_control {
            bins ld_ldr = binsof(cp_mem_state.load_indirect) && binsof(cp_m_control.direct);
            bins ldi_second = binsof(cp_mem_state.load_indirect) && binsof(cp_m_control.indirect);
            bins pointer_read = binsof(cp_mem_state.load_direct) && binsof(cp_m_control.indirect);
            bins st_str = binsof(cp_mem_state.store) && binsof(cp_m_control.direct);
            bins sti = binsof(cp_mem_state.store) && binsof(cp_m_control.indirect);
            bins idle = binsof(cp_mem_state.idle);
            illegal_bins illegal_1_0 = binsof(cp_mem_state.load_direct) && binsof(cp_m_control.direct);
        }
        cx_state_m_data : cross cp_mem_state, m_data_class;
        cx_state_dmem_dout : cross cp_mem_state, dmem_dout_class;

        indirect_read_x : cross cp_mem_state, cp_m_control, cp_m_addr, cp_dmem_dout
                          iff (coverage_trans.mem_state == 2'd0);
        direct_load_x : cross cp_mem_state, cp_m_addr, cp_dmem_dout
                        iff (coverage_trans.mem_state == 2'd1);
        store_x : cross cp_mem_state, cp_m_control, cp_m_addr, cp_m_data
                  iff (coverage_trans.mem_state == 2'd2);

        cp_mem_state_trans : coverpoint coverage_trans.mem_state {
            bins idle_to_indirect = (2'd3 => 2'd0);
            bins idle_to_direct = (2'd3 => 2'd1);
            bins idle_to_store = (2'd3 => 2'd2);
            bins indirect_wait = (2'd0 => 2'd0);
            bins indirect_done = (2'd0 => 2'd3);
            bins indirect_to_direct = (2'd0 => 2'd1);
            bins indirect_to_store = (2'd0 => 2'd2);
            bins direct_wait = (2'd1 => 2'd1);
            bins direct_done = (2'd1 => 2'd3);
            bins store_wait = (2'd2 => 2'd2);
            bins store_done = (2'd2 => 2'd3);
            bins store_to_indirect = (2'd2 => 2'd0);
            bins store_to_direct = (2'd2 => 2'd1);
            bins idle_wait = (2'd3 => 2'd3);
            illegal_bins illegal_transitions =
                (2'd0 => 2'd1), (2'd0 => 2'd2),
                (2'd1 => 2'd3), (2'd2 => 2'd0), (2'd2 => 2'd1);
        }

        cp_mem_state_path : coverpoint state_path {
            bins ld_ldr = {8'b11_11_00_11};
            bins st_str = {8'b11_11_10_11};
            bins ldi = {8'b11_01_00_11};
            bins sti = {8'b11_01_10_11};
        }

        m_data_toggle_0 : coverpoint coverage_trans.M_Data[0] {
            bins r01 = (1'b0 => 1'b1); bins r10 = (1'b1 => 1'b0);
        }
        m_addr_toggle_0 : coverpoint coverage_trans.M_Addr[0] {
            bins r01 = (1'b0 => 1'b1); bins r10 = (1'b1 => 1'b0);
        }
        dmem_dout_toggle_0 : coverpoint coverage_trans.Data_dout[0] {
            bins r01 = (1'b0 => 1'b1); bins r10 = (1'b1 => 1'b0);
        }
        m_data_toggle_1 : coverpoint coverage_trans.M_Data[1] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_2 : coverpoint coverage_trans.M_Data[2] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_3 : coverpoint coverage_trans.M_Data[3] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_4 : coverpoint coverage_trans.M_Data[4] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_5 : coverpoint coverage_trans.M_Data[5] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_6 : coverpoint coverage_trans.M_Data[6] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_7 : coverpoint coverage_trans.M_Data[7] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_8 : coverpoint coverage_trans.M_Data[8] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_9 : coverpoint coverage_trans.M_Data[9] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_10 : coverpoint coverage_trans.M_Data[10] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_11 : coverpoint coverage_trans.M_Data[11] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_12 : coverpoint coverage_trans.M_Data[12] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_13 : coverpoint coverage_trans.M_Data[13] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_14 : coverpoint coverage_trans.M_Data[14] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_data_toggle_15 : coverpoint coverage_trans.M_Data[15] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }

        m_addr_toggle_1 : coverpoint coverage_trans.M_Addr[1] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_2 : coverpoint coverage_trans.M_Addr[2] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_3 : coverpoint coverage_trans.M_Addr[3] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_4 : coverpoint coverage_trans.M_Addr[4] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_5 : coverpoint coverage_trans.M_Addr[5] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_6 : coverpoint coverage_trans.M_Addr[6] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_7 : coverpoint coverage_trans.M_Addr[7] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_8 : coverpoint coverage_trans.M_Addr[8] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_9 : coverpoint coverage_trans.M_Addr[9] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_10 : coverpoint coverage_trans.M_Addr[10] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_11 : coverpoint coverage_trans.M_Addr[11] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_12 : coverpoint coverage_trans.M_Addr[12] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_13 : coverpoint coverage_trans.M_Addr[13] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_14 : coverpoint coverage_trans.M_Addr[14] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        m_addr_toggle_15 : coverpoint coverage_trans.M_Addr[15] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }

        dmem_dout_toggle_1 : coverpoint coverage_trans.Data_dout[1] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_2 : coverpoint coverage_trans.Data_dout[2] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_3 : coverpoint coverage_trans.Data_dout[3] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_4 : coverpoint coverage_trans.Data_dout[4] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_5 : coverpoint coverage_trans.Data_dout[5] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_6 : coverpoint coverage_trans.Data_dout[6] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_7 : coverpoint coverage_trans.Data_dout[7] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_8 : coverpoint coverage_trans.Data_dout[8] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_9 : coverpoint coverage_trans.Data_dout[9] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_10 : coverpoint coverage_trans.Data_dout[10] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_11 : coverpoint coverage_trans.Data_dout[11] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_12 : coverpoint coverage_trans.Data_dout[12] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_13 : coverpoint coverage_trans.Data_dout[13] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_14 : coverpoint coverage_trans.Data_dout[14] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
        dmem_dout_toggle_15 : coverpoint coverage_trans.Data_dout[15] { bins r01=(1'b0=>1'b1); bins r10=(1'b1=>1'b0); }
    endgroup

    function new(string name = "mem_access_in_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_mem_access_in = new();
    endfunction

    virtual function void write(mem_access_in_transaction t);
        coverage_trans = t;
        if (sequence_started) begin
            state_path = {prev_prev_prev_state, prev_prev_state, prev_state, t.mem_state};
        end
        prev_prev_prev_state = prev_prev_state;
        prev_prev_state = prev_state;
        prev_state = t.mem_state;
        sequence_started = 1;
        cg_mem_access_in.sample();
    endfunction
endclass : mem_access_in_coverage
