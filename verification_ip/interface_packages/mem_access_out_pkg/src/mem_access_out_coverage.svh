class mem_access_out_coverage extends uvm_subscriber #(mem_access_out_transaction);
    `uvm_component_utils(mem_access_out_coverage)

    mem_access_out_transaction coverage_trans;
    logic [15:0] previous_address;
    logic [15:0] previous_write_data;
    logic previous_read;
    bit previous_access_valid;
    bit previous_access_active;

    covergroup cg_mem_access_out;
        option.per_instance = 1;
        read_cp : coverpoint coverage_trans.Data_rd {
            bins read = {1'b1};
            bins write = {1'b0};
            bins x_value = {1'bx};
            bins z_value = {1'bz};
            illegal_bins other = default;
        }
        data_addr_cp : coverpoint coverage_trans.Data_addr {
            bins zero = {16'h0000};
            bins one = {16'h0001};
            bins low = {[16'h0002:16'h2FFF]};
            bins instruction_area = {[16'h3000:16'h3FFF]};
            bins mid = {[16'h4000:16'h7FFF]};
            bins high = {[16'h8000:16'hFFFE]};
            bins maximum = {16'hFFFF};
            bins z_value = {16'hzzzz};
        }
        data_din_cp : coverpoint coverage_trans.Data_din {
            bins zero = {16'h0000};
            bins negative = {[16'h8000:16'hFFFF]};
            bins positive = {[16'h0001:16'h7FFF]};
            bins x_value = {16'hxxxx};
            bins z_value = {16'hzzzz};
            illegal_bins unknown = default;
        }
        memout_cp : coverpoint coverage_trans.memout {
            bins zero = {16'h0000};
            bins negative = {[16'h8000:16'hFFFF]};
            bins positive = {[16'h0001:16'h7FFF]};
            bins x_value = {16'hxxxx};
            bins z_value = {16'hzzzz};
        }

        read_address_x : cross read_cp, data_addr_cp
                         iff (coverage_trans.Data_rd inside {1'b0,1'b1});
        read_memout_x : cross read_cp, memout_cp iff (coverage_trans.Data_rd == 1'b1);
        write_data_x : cross read_cp, data_addr_cp, data_din_cp
                       iff (coverage_trans.Data_rd == 1'b0);

        output_transition : coverpoint coverage_trans.Data_rd {
            bins read_to_write = (1'b1 => 1'b0);
            bins write_to_read = (1'b0 => 1'b1);
            bins repeated_read = (1'b1 => 1'b1);
            bins repeated_write = (1'b0 => 1'b0);
        }
    endgroup

    covergroup access_order_cg with function sample(
        int unsigned access_order, bit same_address, int unsigned readback
    );
        option.per_instance = 1;
        cp_access_order: coverpoint access_order {
            bins read_read = {0};
            bins read_write = {1};
            bins write_read = {2};
            bins write_write = {3};
        }
        cp_same_address: coverpoint same_address {
            bins different = {0};
            bins same = {1};
        }
        cx_order_address: cross cp_access_order, cp_same_address {
            bins read_after_write_same_address =
                binsof(cp_access_order.write_read) && binsof(cp_same_address.same);
            bins write_after_write_same_address =
                binsof(cp_access_order.write_write) && binsof(cp_same_address.same);
            bins write_after_read_same_address =
                binsof(cp_access_order.read_write) && binsof(cp_same_address.same);
        }
        cp_readback: coverpoint readback iff (access_order == 2 && same_address) {
            bins data_matches = {0};
            bins data_mismatches = {1};
            bins unknown_data = {2};
        }
    endgroup

    function new(string name = "mem_access_out_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_mem_access_out = new();
        access_order_cg = new();
    endfunction

    virtual function void write(mem_access_out_transaction t);
        int unsigned access_order;
        int unsigned readback;
        bit same_address;

        coverage_trans = t;
        cg_mem_access_out.sample();

        if (!(t.Data_rd inside {1'b0, 1'b1}) || $isunknown(t.Data_addr)) begin
            previous_access_active = 0;
            return;
        end

        if (previous_access_active &&
            t.Data_rd === previous_read &&
            t.Data_addr === previous_address)
            return;

        if (previous_access_valid) begin
            if (previous_read)
                access_order = t.Data_rd ? 0 : 1;
            else
                access_order = t.Data_rd ? 2 : 3;
            same_address = (t.Data_addr === previous_address);
            readback = 2;
            if (access_order == 2 && same_address &&
                !$isunknown(t.memout)) begin
                readback = (t.memout === previous_write_data) ? 0 : 1;
            end
            access_order_cg.sample(access_order, same_address, readback);
        end

        previous_read = t.Data_rd;
        previous_address = t.Data_addr;
        previous_write_data = t.Data_din;
        previous_access_valid = 1;
        previous_access_active = 1;
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("MEM_ACCESS_OUT_COV",
            $sformatf("MemAccess outputs functional coverage=%0.2f%%, access ordering=%0.2f%%",
                      cg_mem_access_out.get_inst_coverage(),
                      access_order_cg.get_inst_coverage()),
            UVM_LOW)
    endfunction
endclass : mem_access_out_coverage
