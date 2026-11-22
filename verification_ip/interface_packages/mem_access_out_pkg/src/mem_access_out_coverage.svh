class mem_access_out_coverage extends uvm_subscriber #(mem_access_out_transaction);
    `uvm_component_utils(mem_access_out_coverage)

    mem_access_out_transaction coverage_trans;

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
            bins low = {[16'h0001:16'h2FFF]};
            bins instruction_area = {[16'h3000:16'h3FFF]};
            bins data_area = {[16'h4000:16'hFFFE]};
            bins maximum = {16'hFFFF};
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
        }

        read_address_x : cross read_cp, data_addr_cp;
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

    function new(string name = "mem_access_out_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_mem_access_out = new();
    endfunction

    virtual function void write(mem_access_out_transaction t);
        coverage_trans = t;
        cg_mem_access_out.sample();
    endfunction
endclass : mem_access_out_coverage
