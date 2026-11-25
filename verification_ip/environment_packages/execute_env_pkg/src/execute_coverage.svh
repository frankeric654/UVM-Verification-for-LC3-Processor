
class execute_coverage extends uvm_subscriber #(execute_in_transaction);

  `uvm_component_utils(execute_coverage)

  // Latest observed Execute input transaction.
  execute_in_types_pkg::execute_in_transfer_t sample;

  // Number of transactions received and sampled.
  int unsigned sample_count;
  logic [1:0] effective_address_wrap;

  function automatic logic [1:0] calculate_address_wrap();
    int signed base_address;
    int signed signed_offset;
    int signed full_address;
    case (sample.IR[15:12])
      4'h6, 4'h7: begin
        if (sample.bypass_alu_1)
          return 2'b11;
        base_address = sample.bypass_mem_1
          ? int'($unsigned(sample.Mem_Bypass_Val))
          : int'($unsigned(sample.VSR1));
        signed_offset = $signed(sample.IR[5:0]);
      end
      4'h2, 4'h3, 4'hA, 4'hB, 4'hE: begin
        base_address = int'($unsigned(sample.npc));
        signed_offset = $signed(sample.IR[8:0]);
      end
      default: return 2'b11;
    endcase
    full_address = base_address + signed_offset;
    if (full_address < 0)
      return 2'b10;
    if (full_address > 16'hFFFF)
      return 2'b01;
    return 2'b00;
  endfunction

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

    cp_base_register_value: coverpoint sample.VSR1 iff (
      !sample.reset && sample.enable_execute &&
      (sample.IR[15:12] inside {4'h6,4'h7})
    ) {
      bins zero = {16'h0000};
      bins one = {16'h0001};
      bins max_positive = {16'h7FFF};
      bins min_negative = {16'h8000};
      bins all_ones = {16'hFFFF};
      bins code_region = {16'h3000};
      bins other = default;
    }

    cp_base_opcode: coverpoint sample.IR[15:12] iff (
      !sample.reset && sample.enable_execute &&
      (sample.IR[15:12] inside {4'h6,4'h7})
    ) {
      bins ldr = {4'h6};
      bins str = {4'h7};
    }
    cx_opcode_base_value: cross cp_base_opcode, cp_base_register_value;

    cp_ea_opcode: coverpoint sample.IR[15:12] iff (
      !sample.reset && sample.enable_execute &&
      (sample.IR[15:12] inside {4'h2,4'h3,4'h6,4'h7,4'hA,4'hB,4'hE}) &&
      !sample.bypass_alu_1
    ) {
      bins memory_address_ops[] = {4'h2,4'h3,4'h6,4'h7,4'hA,4'hB,4'hE};
    }
    cp_effective_address_wrap: coverpoint effective_address_wrap iff (
      !sample.reset && sample.enable_execute &&
      (sample.IR[15:12] inside {4'h2,4'h3,4'h6,4'h7,4'hA,4'hB,4'hE}) &&
      !sample.bypass_alu_1
    ) {
      bins no_wrap = {2'b00};
      bins wrap_high = {2'b01};
      bins wrap_low = {2'b10};
      ignore_bins unavailable = {2'b11};
    }
    cx_opcode_ea_wrap: cross cp_ea_opcode, cp_effective_address_wrap;

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
    effective_address_wrap = calculate_address_wrap();

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

