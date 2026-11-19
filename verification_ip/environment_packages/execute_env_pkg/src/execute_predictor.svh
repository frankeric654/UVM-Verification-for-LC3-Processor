
class execute_predictor extends uvm_component;

  `uvm_component_utils(execute_predictor)

  // Receive observed Execute input transactions.
  /*imp:實際處理  export:只轉交*/
  uvm_analysis_imp #(execute_in_transaction, execute_predictor)
    analysis_imp;

  // Send predicted Execute output transactions.
  uvm_analysis_port #(execute_out_transaction)
    expected_ap;

  // Keep the previous ALU result for bypass prediction.
  bit [15:0] previous_aluout;

  // Store the expected output for the next clock cycle.
  execute_out_transaction previous_expected_tx;

  function new(string name = "execute_predictor",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    analysis_imp = new("analysis_imp", this);
    expected_ap = new("expected_ap", this);

    previous_aluout = '0;

    previous_expected_tx =
      execute_out_transaction::type_id::create("previous_expected_tx");

    previous_expected_tx.sample = '0;
  endfunction

  virtual function void write(execute_in_transaction tx);

    execute_out_transaction expected_tx;
    execute_out_transaction output_tx;
    bit model_status;

    // Operands after applying ALU or memory bypass.
    bit [15:0] predicted_alu1;
    bit [15:0] predicted_alu2;

    expected_tx =
      execute_out_transaction::type_id::create("expected_tx");

    output_tx =
      execute_out_transaction::type_id::create("output_tx");

    // Publish the output predicted from the previous clock cycle.
    output_tx.sample = previous_expected_tx.sample;

    // sr1 and sr2 are combinational outputs derived from IR.
    // They must reflect the current instruction, not the previous cycle.
    // Decode source registers using the same opcode rules as execute_model().
    case (tx.sample.IR[15:12])

      4'b0001, 4'b0101: begin
        // ADD and AND.
        output_tx.sample.sr1 = tx.sample.IR[8:6];
        output_tx.sample.sr2 = tx.sample.IR[2:0];
      end

      4'b1001: begin
        // NOT.
        output_tx.sample.sr1 = tx.sample.IR[8:6];
        output_tx.sample.sr2 = tx.sample.IR[2:0];
      end

      4'b0010, 4'b0110, 4'b1010, 4'b1110: begin
        // LD, LDR, LDI, LEA.
        output_tx.sample.sr1 = tx.sample.IR[8:6];
        output_tx.sample.sr2 = '0;
      end

      4'b0011, 4'b0111, 4'b1011: begin
        // ST, STR, STI.
        output_tx.sample.sr1 = tx.sample.IR[8:6];
        output_tx.sample.sr2 = tx.sample.IR[11:9];
      end

      4'b0000, 4'b1100: begin
        // BR and JMP.
        output_tx.sample.sr1 = tx.sample.IR[8:6];
        output_tx.sample.sr2 = '0;
      end

      default: begin
        output_tx.sample.sr1 = '0;
        output_tx.sample.sr2 = '0;
      end

    endcase

    expected_ap.write(output_tx);

    // The reference model does not accept reset.
    //reset==1 return
    if (tx.sample.reset) begin
      previous_aluout = '0;
      previous_expected_tx.sample = '0;
      return;
    end

    // Avoid predicting unspecified outputs when disabled.
    //enable==0 return
    if (!tx.sample.enable_execute) begin
      previous_expected_tx.sample.NZP = '0;
      return;
    end

    /*
    // The model uses aluout as both an input for bypass
    // and an output for the newly calculated result.
    expected_tx.sample.aluout = previous_aluout;
    */

    model_status = lc3_prediction_pkg::execute_model(
      tx.sample.E_Control,
      tx.sample.bypass_alu_1,
      tx.sample.bypass_alu_2,
      tx.sample.bypass_mem_1,
      tx.sample.bypass_mem_2,
      tx.sample.enable_execute,
      tx.sample.IR,
      tx.sample.npc,
      tx.sample.Mem_Control_in,
      tx.sample.W_Control_in,
      tx.sample.Mem_Bypass_Val,
      tx.sample.VSR1,
      tx.sample.VSR2,

      expected_tx.sample.aluout,
      expected_tx.sample.W_Control_out,
      expected_tx.sample.Mem_Control_out,
      expected_tx.sample.M_Data,
      expected_tx.sample.dr,
      expected_tx.sample.sr1,
      expected_tx.sample.sr2,
      expected_tx.sample.IR_Exec,
      expected_tx.sample.NZP,
      expected_tx.sample.pcout
    );

    if (model_status != 0) begin
      `uvm_error("EXE_PRED", "execute_model() returned failure")
      return;
    end

    // Determine operand 1 after bypass selection.
    case ({tx.sample.bypass_mem_1, tx.sample.bypass_alu_1})
      2'b00: predicted_alu1 = tx.sample.VSR1;
      2'b01: predicted_alu1 = previous_aluout;
      2'b10: predicted_alu1 = tx.sample.Mem_Bypass_Val;
      default: predicted_alu1 = '0;
    endcase

    // Determine operand 2 after bypass selection.
    case ({tx.sample.bypass_mem_2, tx.sample.bypass_alu_2})
      2'b00: begin
        predicted_alu2 = tx.sample.E_Control[0]
          ? tx.sample.VSR2
          : {{11{tx.sample.IR[4]}}, tx.sample.IR[4:0]};
      end

      2'b01: predicted_alu2 = previous_aluout;
      2'b10: predicted_alu2 = tx.sample.Mem_Bypass_Val;
      default: predicted_alu2 = '0;
    endcase

    // Correct the ALU result when a bypass is enabled.
    if (tx.sample.bypass_alu_1 ||
        tx.sample.bypass_alu_2 ||
        tx.sample.bypass_mem_1 ||
        tx.sample.bypass_mem_2) begin

      if (tx.sample.IR[15:12] inside {
        4'h1, 4'h5, 4'h9
      }) begin

        case (tx.sample.E_Control[5:4])

          2'b00:
            expected_tx.sample.aluout =
              predicted_alu1 + predicted_alu2;

          2'b01:
            expected_tx.sample.aluout =
              predicted_alu1 & predicted_alu2;

          2'b10:
            expected_tx.sample.aluout =
              ~predicted_alu1;

          default:
            expected_tx.sample.aluout = '0;

        endcase

        expected_tx.sample.pcout =
          expected_tx.sample.aluout;

        // M_Data follows the reference model's operand-2 bypass rule.
        if (tx.sample.bypass_alu_2)
          expected_tx.sample.M_Data = predicted_alu2;

      end

    end

    previous_aluout = expected_tx.sample.aluout;

    // Save the newly predicted output for the next cycle.
    previous_expected_tx.sample = expected_tx.sample;

  endfunction

endclass
/*尚未細讀*/
