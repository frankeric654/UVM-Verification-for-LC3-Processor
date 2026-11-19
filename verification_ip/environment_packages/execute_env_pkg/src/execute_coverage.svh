
class execute_coverage extends uvm_subscriber #(execute_in_transaction);

  `uvm_component_utils(execute_coverage)

  // Latest observed Execute input transaction.
  execute_in_types_pkg::execute_in_transfer_t sample;

  // Number of transactions received and sampled.
  int unsigned sample_count;

  // Functional coverage for Execute stage inputs.
  covergroup execute_cg;

    option.per_instance = 1;

    // LC3 instruction opcode.
    cp_opcode: coverpoint sample.IR[15:12] iff (
      !sample.reset && sample.enable_execute
    ) {
      bins br   = {4'h0};
      bins add  = {4'h1};
      bins ld   = {4'h2};
      bins st   = {4'h3};
      bins jsr  = {4'h4};
      bins and_op = {4'h5};
      bins ldr  = {4'h6};
      bins str  = {4'h7};
      bins not_op = {4'h9};
      bins ldi  = {4'hA};
      bins sti  = {4'hB};
      bins jmp  = {4'hC};
      bins lea  = {4'hE};
      bins trap = {4'hF};
      illegal_bins reserved = {4'h8, 4'hD};
    }

    // ALU operation selected by E_Control[5:4].
    cp_alu_operation: coverpoint sample.E_Control[5:4] iff (
      !sample.reset &&
      sample.enable_execute &&
      (sample.IR[15:12] inside {4'h1, 4'h5, 4'h9})
    ) {
      bins add_op = {2'b00};
      bins and_op = {2'b01};
      bins not_op = {2'b10};
      illegal_bins other = {2'b11};
    }

    // Operand 2 selection for ADD and AND instructions.
    // E_Control[0] = 0: Immediate
    // E_Control[0] = 1: Register
    cp_operand_type: coverpoint sample.E_Control[0] iff (
      !sample.reset &&
      sample.enable_execute &&
      (sample.IR[15:12] inside {4'h1, 4'h5})
    ) {
      bins immediate = {1'b0};
      bins register_operand = {1'b1};
    }

    // ALU bypass selection.
    cp_bypass_alu_1: coverpoint sample.bypass_alu_1 iff (
      !sample.reset && sample.enable_execute
    ) {
      bins disabled = {0};
      bins enabled = {1};
    }

    cp_bypass_alu_2: coverpoint sample.bypass_alu_2 iff (
      !sample.reset && sample.enable_execute
    ) {
      bins disabled = {0};
      bins enabled = {1};
    }

    // Memory bypass selection.
    cp_bypass_mem_1: coverpoint sample.bypass_mem_1 iff (
      !sample.reset && sample.enable_execute
    ) {
      bins disabled = {0};
      bins enabled = {1};
    }

    cp_bypass_mem_2: coverpoint sample.bypass_mem_2 iff (
      !sample.reset && sample.enable_execute
    ) {
      bins disabled = {0};
      bins enabled = {1};
    }

    // Execute pipeline enable.
    cp_enable: coverpoint sample.enable_execute {
      bins disabled = {0};
      bins enabled = {1};
    }

    // Execute reset.
    cp_reset: coverpoint sample.reset {
      bins asserted = {1};
      bins deasserted = {0};
    }

    // Opcode and operand type combinations for ADD and AND.
    cp_alu_opcode: coverpoint sample.IR[15:12] iff (
      !sample.reset &&
      sample.enable_execute &&
      (sample.IR[15:12] inside {4'h1, 4'h5})
    ) {
      bins add_op = {4'h1};
      bins and_op = {4'h5};
    }

    cross_alu_operand: cross cp_alu_opcode, cp_operand_type;

  endgroup

  function new(
    string name = "execute_coverage",
    uvm_component parent = null
  );
    super.new(name, parent);

    execute_cg = new();
    sample_count = 0;
  endfunction

  // Called when the input monitor broadcasts a transaction.
  virtual function void write(execute_in_transaction t);

    if (t == null) begin
      `uvm_warning("EXE_COV", "Received null transaction")
      return;
    end

    sample = t.sample;

    execute_cg.sample();

    sample_count++;

  endfunction

  // Report coverage at the end of simulation.
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("EXE_COV",
      $sformatf(
        "Samples=%0d Functional Coverage=%0.2f%%",
        sample_count,
        execute_cg.get_inst_coverage()
      ),
      UVM_LOW)

  endfunction

endclass
/*尚未細讀*/

