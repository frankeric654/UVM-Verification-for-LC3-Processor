/*hdl_top：例化 DUT、Interfaces、Monitor BFMs。
  hvl_top：將BFM的Virtual Interface傳給UVM並啟動run_test()
  execute_test：建立 Execute Environment，後續負責測試控制*/
module hdl_top;

  timeunit 1ns;
  timeprecision 1ps;

  // Clock
  logic clock = 0;

  always #5 clock = ~clock;

  // Execute DUT inputs
  logic        reset;
  logic        enable_execute;
  logic [5:0]  E_Control;

  logic        bypass_alu_1;
  logic        bypass_alu_2;
  logic        bypass_mem_1;
  logic        bypass_mem_2;

  logic [15:0] IR;
  logic [15:0] npc;

  logic        Mem_Control_in;
  logic [1:0]  W_Control_in;

  logic [15:0] Mem_Bypass_Val;
  logic [15:0] VSR1;
  logic [15:0] VSR2;

  // Execute DUT outputs
  wire [15:0] aluout;
  wire [15:0] pcout;

  wire [1:0]  W_Control_out;
  wire        Mem_Control_out;

  wire [2:0]  NZP;
  wire [15:0] IR_Exec;

  wire [2:0]  sr1;
  wire [2:0]  sr2;
  wire [2:0]  dr;

  wire [15:0] M_Data;

  // DUT
  Execute dut (
    .clock(clock),
    .reset(reset),
    .enable_execute(enable_execute),
    .E_Control(E_Control),

    .bypass_alu_1(bypass_alu_1),
    .bypass_alu_2(bypass_alu_2),
    .bypass_mem_1(bypass_mem_1),
    .bypass_mem_2(bypass_mem_2),

    .IR(IR),
    .npc(npc),

    .W_Control_in(W_Control_in),
    .Mem_Control_in(Mem_Control_in),

    .VSR1(VSR1),
    .VSR2(VSR2),
    .Mem_Bypass_Val(Mem_Bypass_Val),

    .W_Control_out(W_Control_out),
    .Mem_Control_out(Mem_Control_out),

    .NZP(NZP),
    .IR_Exec(IR_Exec),

    .aluout(aluout),
    .pcout(pcout),

    .sr1(sr1),
    .sr2(sr2),
    .dr(dr),

    .M_Data(M_Data)
  );

  // Input interface
  execute_in_if in_if (
    .clock(clock),
    .reset(reset),
    .enable_execute(enable_execute),
    .E_Control(E_Control),

    .bypass_alu_1(bypass_alu_1),
    .bypass_alu_2(bypass_alu_2),
    .bypass_mem_1(bypass_mem_1),
    .bypass_mem_2(bypass_mem_2),

    .IR(IR),
    .npc(npc),

    .Mem_Control_in(Mem_Control_in),
    .W_Control_in(W_Control_in),

    .Mem_Bypass_Val(Mem_Bypass_Val),
    .VSR1(VSR1),
    .VSR2(VSR2)
  );

  // Output interface
  execute_out_if out_if (
    .clock(clock),

    .aluout(aluout),
    .pcout(pcout),

    .W_Control_out(W_Control_out),
    .Mem_Control_out(Mem_Control_out),

    .NZP(NZP),
    .IR_Exec(IR_Exec),

    .sr1(sr1),
    .sr2(sr2),
    .dr(dr),

    .M_Data(M_Data)
  );

  // Monitor BFMs
  execute_in_monitor_bfm in_monitor_bfm(in_if);
  execute_out_monitor_bfm out_monitor_bfm(out_if);

  // Apply an Execute input transaction at a falling clock edge.
  task automatic apply_execute(
    input logic [15:0] instruction,
    input logic [5:0]  control,
    input logic [15:0] operand1,
    input logic [15:0] operand2
  );

    @(negedge clock);

    IR = instruction;
    E_Control = control;

    VSR1 = operand1;
    VSR2 = operand2;

    enable_execute = 1;

    bypass_alu_1 = 0;
    bypass_alu_2 = 0;
    bypass_mem_1 = 0;
    bypass_mem_2 = 0;

  endtask

  // Initialize DUT inputs
  initial begin
    reset = 1;
    enable_execute = 0;

    E_Control = '0;

    bypass_alu_1 = 0;
    bypass_alu_2 = 0;
    bypass_mem_1 = 0;
    bypass_mem_2 = 0;

    IR = '0;
    npc = '0;

    Mem_Control_in = 0;
    W_Control_in = '0;

    Mem_Bypass_Val = '0;
    VSR1 = '0;
    VSR2 = '0;

    // Hold reset for two clock cycles.
    repeat (2) @(negedge clock);

    // Release reset and configure ADD operation.
    reset = 0;

    IR = 16'h1282;       // ADD R1, R2, R2
    E_Control = 6'b000001;

    VSR1 = 16'd5;
    VSR2 = 16'd3;

    // No bypass for this initial test.
    bypass_alu_1 = 0;
    bypass_alu_2 = 0;
    bypass_mem_1 = 0;
    bypass_mem_2 = 0;

    enable_execute = 1;

    // Observe several execute cycles.
    repeat (2) @(negedge clock);

    // Switch to AND register operation.
    IR = 16'h5282;       // AND R1, R2, R2
    E_Control = 6'b010001;

    VSR1 = 16'd12;
    VSR2 = 16'd5;

    repeat (3) @(negedge clock);

    // Switch to NOT operation.
    IR = 16'h92BF;       // NOT R1, R2
    E_Control = 6'b100000;

    VSR1 = 16'h0005;
    VSR2 = '0;

    repeat (4) @(negedge clock);

    // Switch to ADD immediate operation.
    IR = 16'h12A5;       // ADD R1, R2, #5
    E_Control = 6'b000000;

    VSR1 = 16'd5;
    VSR2 = 16'd100;

    repeat (4) @(negedge clock);

    // Additional AND immediate test.
    apply_execute(
      16'h52A5,          // AND R1, R2, #5
      6'b010000,
      16'h000F,
      16'h1234
    );

    // Randomized arithmetic stimulus.
    // Keep opcode/control combinations valid.
    repeat (20) begin
      apply_execute(
        16'h1282,        // ADD R1, R2, R2
        6'b000001,
        $urandom,
        $urandom
      );
    end

    repeat (20) begin
      apply_execute(
        16'h5282,        // AND R1, R2, R2
        6'b010001,
        $urandom,
        $urandom
      );
    end

    // Random ADD immediate values in the signed imm5 range.
    repeat (20) begin
      logic [4:0] imm5;

      imm5 = $urandom_range(0, 31);

      apply_execute(
        {4'h1, 3'd1, 3'd2, 1'b1, imm5},
        6'b000000,
        $urandom,
        16'h0000
      );
    end

    @(negedge clock);
    enable_execute = 0;

    // Allow time to observe held outputs.
    repeat (2) @(negedge clock);

    // Directed ALU bypass timing experiment.
    // First produce a known ALU result: 5 + 3 = 8.
    apply_execute(
      16'h1282,
      6'b000001,
      16'd5,
      16'd3
    );

    // Observe the registered ALU result after the active clock edge.
    @(posedge clock);
    #1;
    $display(
      "[EXE_BYPASS] STEP1 no bypass: aluout=%h expected=0008",
      aluout
    );

    // Forward the previous ALU result to operand 1.
    @(negedge clock);
    IR = 16'h1282;
    E_Control = 6'b000001;
    VSR1 = 16'd100;
    VSR2 = 16'd2;

    bypass_alu_1 = 1;
    bypass_alu_2 = 0;
    bypass_mem_1 = 0;
    bypass_mem_2 = 0;

    @(posedge clock);
    #1;
    $display(
      "[EXE_BYPASS] STEP2 ALU bypass operand1: aluout=%h expected=000a",
      aluout
    );

    // Disable bypass and verify the normal ALU path again.
    @(negedge clock);
    bypass_alu_1 = 0;
    VSR1 = 16'd4;
    VSR2 = 16'd13;

    @(posedge clock);
    #1;
    $display(
      "[EXE_BYPASS] STEP3 no bypass: aluout=%h expected=0011",
      aluout
    );

    // Forward a known memory value to operand 1.
    @(negedge clock);
    IR = 16'h1282;
    E_Control = 6'b000001;

    VSR1 = 16'd100;
    VSR2 = 16'd7;
    Mem_Bypass_Val = 16'd25;

    bypass_alu_1 = 0;
    bypass_alu_2 = 0;
    bypass_mem_1 = 1;
    bypass_mem_2 = 0;

    @(posedge clock);
    #1;
    $display(
      "[EXE_BYPASS] STEP4 memory bypass operand1: aluout=%h expected=0020",
      aluout
    );

    // Prepare a known ALU result for operand-2 forwarding.
    @(negedge clock);
    bypass_alu_1 = 0;
    bypass_alu_2 = 0;
    bypass_mem_1 = 0;
    bypass_mem_2 = 0;

    VSR1 = 16'd5;
    VSR2 = 16'd3;

    @(posedge clock);
    #1;
    $display(
      "[EXE_BYPASS] STEP5 prepare ALU result: aluout=%h expected=0008",
      aluout
    );

    // Forward the previous ALU result to operand 2.
    @(negedge clock);
    VSR1 = 16'd4;
    VSR2 = 16'd100;

    bypass_alu_1 = 0;
    bypass_alu_2 = 1;
    bypass_mem_1 = 0;
    bypass_mem_2 = 0;

    @(posedge clock);
    #1;
    $display(
      "[EXE_BYPASS] STEP6 ALU bypass operand2: aluout=%h expected=000c M_Data=%h expected_M_Data=0008",
      aluout,
      M_Data
    );

    // Forward a known memory value to operand 2.
    @(negedge clock);
    VSR1 = 16'd6;
    VSR2 = 16'd100;
    Mem_Bypass_Val = 16'd20;

    bypass_alu_1 = 0;
    bypass_alu_2 = 0;
    bypass_mem_1 = 0;
    bypass_mem_2 = 1;

    @(posedge clock);
    #1;
    $display(
      "[EXE_BYPASS] STEP7 memory bypass operand2: aluout=%h expected=001a M_Data=%h expected_M_Data=0064",
      aluout,
      M_Data
    );

    @(negedge clock);
    bypass_mem_2 = 0;
    enable_execute = 0;

    // Directed BR test with positive PC-relative offset.
    // The E_Control setting is provisional until verified against the DUT.
    apply_execute(
      16'h0E05,          // BRnzp with offset +5
      6'b000110,         // E_Control[3:1] = 3'b011
      16'h0000,
      16'h0000
    );

    npc = 16'h3001;

    @(posedge clock);
    #1;

    $display(
      "[EXE_BR] BRnzp +5: pcout=%h expected=3005 aluout=%h expected=3005 NZP=%b expected=111",
      pcout,
      aluout,
      NZP
    );

    if (pcout !== 16'h3005 ||
        aluout !== 16'h3005 ||
        NZP !== 3'b111) begin
      $error(
        "[EXE_BR] BR directed test failed: pcout=%h aluout=%h NZP=%b",
        pcout,
        aluout,
        NZP
      );
    end

    @(negedge clock);
    enable_execute = 0;

    // Directed BR test with negative PC-relative offset.
    // BRnzp offset9=-1 checks sign extension and branch target calculation.
    // The provided Execute reference model uses npc - 1 + signed offset,
    // so npc=3001 and offset=-1 produce 2FFF (not the architectural 3000).
    // Confirm the NPC convention when integrating the full LC-3 pipeline.
    apply_execute(
      16'h0FFF,          // BRnzp with offset -1
      6'b000110,         // E_Control[3:1] = 3'b011
      16'h0000,
      16'h0000
    );

    npc = 16'h3001;

    @(posedge clock);
    #1;

    $display(
      "[EXE_BR_NEG] BRnzp -1: pcout=%h expected=2fff aluout=%h expected=2fff NZP=%b expected=111",
      pcout,
      aluout,
      NZP
    );

    if (pcout !== 16'h2FFF ||
        aluout !== 16'h2FFF ||
        NZP !== 3'b111) begin
      $error(
        "[EXE_BR_NEG] BR negative offset test failed: pcout=%h aluout=%h NZP=%b",
        pcout,
        aluout,
        NZP
      );
    end

    @(negedge clock);
    enable_execute = 0;

    // Directed LD test with positive PC-relative offset.
    // Expected address follows the provided Execute reference model.
    apply_execute(
      16'h2203,          // LD R1, #3
      6'b000110,         // E_Control[3:1] = 3'b011
      16'h0000,
      16'h0000
    );
    npc = 16'h3001;

    @(posedge clock);
    #1;
    $display(
      "[EXE_LD] LD +3: pcout=%h expected=3003 aluout=%h expected=3003 dr=%b expected=001",
      pcout, aluout, dr
    );
    if (pcout !== 16'h3003 ||
        aluout !== 16'h3003 ||
        dr !== 3'b001) begin
      $error(
        "[EXE_LD] LD directed test failed: pcout=%h aluout=%h dr=%b",
        pcout, aluout, dr
      );
    end

    @(negedge clock);
    enable_execute = 0;

    // Directed ST test with positive PC-relative offset.
    // Expected address follows the provided Execute reference model.
    // Store data must be forwarded from VSR2 to M_Data.
    apply_execute(
      16'h3403,          // ST R2, #3
      6'b000110,         // E_Control[3:1] = 3'b011
      16'h0000,
      16'h1234
    );
    npc = 16'h3001;

    @(posedge clock);
    #1;
    $display(
      "[EXE_ST] ST +3: pcout=%h expected=3003 aluout=%h expected=3003 M_Data=%h expected=1234 sr2=%b expected=010",
      pcout, aluout, M_Data, sr2
    );
    if (pcout !== 16'h3003 ||
        aluout !== 16'h3003 ||
        M_Data !== 16'h1234 ||
        sr2 !== 3'b010) begin
      $error(
        "[EXE_ST] ST directed test failed: pcout=%h aluout=%h M_Data=%h sr2=%b",
        pcout, aluout, M_Data, sr2
      );
    end

    @(negedge clock);
    enable_execute = 0;

    // Directed LDR test with positive base-relative offset.
    // LDR R1, R2, #3 uses BaseR=R2 and offset6=+3.
    // E_Control[3:1] = 3'b100 selects VSR1 + sign-extended offset6.
    apply_execute(
      16'h6283,          // LDR R1, R2, #3
      6'b001000,         // E_Control[3:1] = 3'b100
      16'h4000,          // VSR1 (BaseR value)
      16'h0000
    );

    @(posedge clock);
    #1;
    $display(
      "[EXE_LDR] LDR +3: pcout=%h expected=4003 aluout=%h expected=4003 dr=%b expected=001 sr1=%b expected=010",
      pcout, aluout, dr, sr1
    );
    if (pcout !== 16'h4003 ||
        aluout !== 16'h4003 ||
        dr !== 3'b001 ||
        sr1 !== 3'b010) begin
      $error(
        "[EXE_LDR] LDR directed test failed: pcout=%h aluout=%h dr=%b sr1=%b",
        pcout, aluout, dr, sr1
      );
    end

    @(negedge clock);
    enable_execute = 0;

    // Directed STR test with positive base-relative offset.
    // STR R3, R2, #3 uses BaseR=R2 and offset6=+3.
    // E_Control[3:1] = 3'b100 selects VSR1 + sign-extended offset6.
    // Store data must be forwarded from VSR2 to M_Data.
    apply_execute(
      16'h7683,          // STR R3, R2, #3
      6'b001000,         // E_Control[3:1] = 3'b100
      16'h4000,          // VSR1 (BaseR value)
      16'h5678           // VSR2 (Store data)
    );

    @(posedge clock);
    #1;
    $display(
      "[EXE_STR] STR +3: pcout=%h expected=4003 aluout=%h expected=4003 M_Data=%h expected=5678 sr1=%b expected=010 sr2=%b expected=011",
      pcout, aluout, M_Data, sr1, sr2
    );
    if (pcout !== 16'h4003 ||
        aluout !== 16'h4003 ||
        M_Data !== 16'h5678 ||
        sr1 !== 3'b010 ||
        sr2 !== 3'b011) begin
      $error(
        "[EXE_STR] STR directed test failed: pcout=%h aluout=%h M_Data=%h sr1=%b sr2=%b",
        pcout, aluout, M_Data, sr1, sr2
      );
    end

    @(negedge clock);
    enable_execute = 0;

    // Directed LDI test with positive PC-relative offset.
    // LDI R1, #3 computes the address for the first indirect memory read.
    // Expected address follows the provided Execute reference model.
    apply_execute(
      16'hA203,          // LDI R1, #3
      6'b000110,         // E_Control[3:1] = 3'b011
      16'h0000,
      16'h0000
    );
    npc = 16'h3001;

    @(posedge clock);
    #1;
    $display(
      "[EXE_LDI] LDI +3: pcout=%h expected=3003 aluout=%h expected=3003 dr=%b expected=001",
      pcout, aluout, dr
    );
    if (pcout !== 16'h3003 ||
        aluout !== 16'h3003 ||
        dr !== 3'b001) begin
      $error(
        "[EXE_LDI] LDI directed test failed: pcout=%h aluout=%h dr=%b",
        pcout, aluout, dr
      );
    end

    @(negedge clock);
    enable_execute = 0;

    // Directed STI test with positive PC-relative offset.
    // STI R3, #3 computes the address for the first indirect memory access.
    // Expected address follows the provided Execute reference model.
    // Store data must be forwarded from VSR2 to M_Data.
    apply_execute(
      16'hB603,          // STI R3, #3
      6'b000110,         // E_Control[3:1] = 3'b011
      16'h0000,
      16'h5678           // VSR2 (Store data)
    );
    npc = 16'h3001;

    @(posedge clock);
    #1;
    $display(
      "[EXE_STI] STI +3: pcout=%h expected=3003 aluout=%h expected=3003 M_Data=%h expected=5678 sr2=%b expected=011",
      pcout, aluout, M_Data, sr2
    );
    if (pcout !== 16'h3003 ||
        aluout !== 16'h3003 ||
        M_Data !== 16'h5678 ||
        sr2 !== 3'b011) begin
      $error(
        "[EXE_STI] STI directed test failed: pcout=%h aluout=%h M_Data=%h sr2=%b",
        pcout, aluout, M_Data, sr2
      );
    end

    @(negedge clock);
    enable_execute = 0;

    // Directed LEA test with positive PC-relative offset.
    // LEA R1, #3 computes an effective address without reading memory.
    // Expected address follows the provided Execute reference model.
    apply_execute(
      16'hE203,          // LEA R1, #3
      6'b000110,         // E_Control[3:1] = 3'b011
      16'h0000,
      16'h0000
    );
    npc = 16'h3001;

    @(posedge clock);
    #1;
    $display(
      "[EXE_LEA] LEA +3: pcout=%h expected=3003 aluout=%h expected=3003 dr=%b expected=001",
      pcout, aluout, dr
    );
    if (pcout !== 16'h3003 ||
        aluout !== 16'h3003 ||
        dr !== 3'b001) begin
      $error(
        "[EXE_LEA] LEA directed test failed: pcout=%h aluout=%h dr=%b",
        pcout, aluout, dr
      );
    end

    @(negedge clock);
    enable_execute = 0;

    // Directed JMP test using a base register target address.
    // JMP R2 uses BaseR=R2 and selects VSR1 directly as the target.
    // E_Control[3:1] = 3'b110 selects alu1 without an offset.
    apply_execute(
      16'hC080,          // JMP R2
      6'b001100,         // E_Control[3:1] = 3'b110
      16'h4000,          // VSR1 (BaseR value)
      16'h0000
    );

    @(posedge clock);
    #1;
    $display(
      "[EXE_JMP] JMP R2: pcout=%h expected=4000 aluout=%h expected=4000 sr1=%b expected=010 NZP=%b expected=111",
      pcout, aluout, sr1, NZP
    );
    if (pcout !== 16'h4000 ||
        aluout !== 16'h4000 ||
        sr1 !== 3'b010 ||
        NZP !== 3'b111) begin
      $error(
        "[EXE_JMP] JMP directed test failed: pcout=%h aluout=%h sr1=%b NZP=%b",
        pcout, aluout, sr1, NZP
      );
    end

    @(negedge clock);
    enable_execute = 0;

    // Directed JSR test with positive PC-relative offset.
    // The provided Execute reference model selects alu1 + offset10
    // when E_Control[3:1] = 3'b000; use VSR1 as the address base.
    apply_execute(
      16'h4803,          // JSR #3
      6'b000000,         // E_Control[3:1] = 3'b000
      16'h3000,          // VSR1 (reference-model address base)
      16'h0000
    );

    @(posedge clock);
    #1;
    $display(
      "[EXE_JSR] JSR +3: pcout=%h expected=3003 aluout=%h expected=3003",
      pcout, aluout
    );
    if (pcout !== 16'h3003 ||
        aluout !== 16'h3003) begin
      $error(
        "[EXE_JSR] JSR directed test failed: pcout=%h aluout=%h",
        pcout, aluout
      );
    end

    @(negedge clock);
    enable_execute = 0;

    // Directed TRAP test for the Execute stage.
    // TRAP x25 is identified by opcode 4'hF and vector x25.
    // E_Control[3:1] = 3'b111 selects npc - 1 in the reference model.
    // Trap-vector memory lookup and PC redirection are outside this test.
    apply_execute(
      16'hF025,          // TRAP x25
      6'b001110,         // E_Control[3:1] = 3'b111
      16'h0000,
      16'h0000
    );
    npc = 16'h3001;

    @(posedge clock);
    #1;
    $display(
      "[EXE_TRAP] TRAP x25: pcout=%h expected=3000 aluout=%h expected=3000 dr=%b expected=000",
      pcout, aluout, dr
    );
    if (pcout !== 16'h3000 ||
        aluout !== 16'h3000 ||
        dr !== 3'b000) begin
      $error(
        "[EXE_TRAP] TRAP directed test failed: pcout=%h aluout=%h dr=%b",
        pcout, aluout, dr
      );
    end

    @(negedge clock);
    enable_execute = 0;
  end

  // Temporary timing observation.
  always @(negedge clock) begin
    $display(
      "[EXE_DUT] time=%0t reset=%0b enable=%0b IR=%h VSR1=%h VSR2=%h aluout=%h pcout=%h",
      $time,
      reset,
      enable_execute,
      IR,
      VSR1,
      VSR2,
      aluout,
      pcout
    );
  end

endmodule
/*尚未細讀*/
