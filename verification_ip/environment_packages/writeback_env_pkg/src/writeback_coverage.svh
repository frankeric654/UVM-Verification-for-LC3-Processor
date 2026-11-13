// WB functional coverage supplements the team's instruction coverage.
class writeback_coverage extends uvm_subscriber #(writeback_in_transaction);
  `uvm_component_utils(writeback_coverage)
  covergroup wb_cg with function sample(writeback_in_transfer_t s, logic [15:0] value);
    option.per_instance = 1;
    reset_cp: coverpoint s.reset;
    enable_cp: coverpoint s.enable_writeback iff (s.reset === 1'b0);
    source_cp: coverpoint s.W_Control iff (s.reset === 1'b0 && s.enable_writeback === 1'b1) {
      bins alu = {0}; bins memory = {1}; bins pc = {2};
      ignore_bins unsupported = {3};
    }
    dest_cp: coverpoint s.dr iff (s.reset === 1'b0 && s.enable_writeback === 1'b1) {
      bins registers[] = {[0:7]};
    }
    sr1_cp: coverpoint s.sr1 iff (s.reset === 1'b0) { bins registers[] = {[0:7]}; }
    sr2_cp: coverpoint s.sr2 iff (s.reset === 1'b0) { bins registers[] = {[0:7]}; }
    value_cp: coverpoint value iff (s.reset === 1'b0 && s.enable_writeback === 1'b1 &&
                                   s.W_Control inside {0,1,2}) {
      bins zero = {16'h0000}; bins positive = {[16'h0001:16'h7ffe]};
      bins max_positive = {16'h7fff}; bins min_negative = {16'h8000};
      bins negative = {[16'h8001:16'hfffe]}; bins minus_one = {16'hffff};
    }
    same_read_write_cp: coverpoint (s.sr1 == s.dr) iff
      (s.reset === 1'b0 && s.enable_writeback === 1'b1);
    source_dest: cross source_cp, dest_cp;
    source_value: cross source_cp, value_cp;
  endgroup
  function new(string name, uvm_component parent);
    super.new(name, parent);
    wb_cg = new();
  endfunction
  function void write(writeback_in_transaction t);
    logic [15:0] value;
    case (t.sample.W_Control)
      0: value = t.sample.aluout;
      1: value = t.sample.memout;
      2: value = t.sample.pcout;
      default: value = 'x;
    endcase
    wb_cg.sample(t.sample, value);
  endfunction
endclass
