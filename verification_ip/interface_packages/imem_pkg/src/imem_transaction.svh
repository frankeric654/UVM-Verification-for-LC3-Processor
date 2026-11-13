//----------------------------------------------------------------------
// Created with uvmf_gen version 2021.3
//----------------------------------------------------------------------
// pragma uvmf custom header begin
// pragma uvmf custom header end
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//     
// DESCRIPTION: This class defines the variables required for an imem
//    transaction.  Class variables to be displayed in waveform transaction
//    viewing are added to the transaction viewing stream in the add_to_wave
//    function.
//
//----------------------------------------------------------------------
//----------------------------------------------------------------------
//
class imem_transaction  extends uvmf_transaction_base;

  `uvm_object_utils( imem_transaction )

  // PC of the fetch request (filled in from the bus)
  bit [15:0] addr ;
  // Instruction word returned for that request
  rand bit [15:0] instr ;

  //Constraints for the transaction variables:
  constraint legal_opcode_c { instr[15:12] inside { IMEM_BR, IMEM_ADD, IMEM_LD, IMEM_ST, IMEM_AND, IMEM_LDR, IMEM_STR, IMEM_NOT, IMEM_LDI, IMEM_STI, IMEM_JMP, IMEM_LEA }; }
  constraint legal_fixed_bits_c { if ((instr[15:12] inside { IMEM_ADD, IMEM_AND }) && (instr[5] == 1'b0)) instr[4:3] == 2'b00; if (instr[15:12] == IMEM_NOT) instr[5:0] == 6'b111111; if (instr[15:12] == IMEM_JMP) { instr[11:9] == 3'b000; instr[5:0] == 6'b000000; } }

  // pragma uvmf custom class_item_additional begin
  // ---------------------------------------------------------------------------
  // LC3 field helpers. One bit range means different things per opcode:
  //   [11:9] DR (ADD/AND/NOT/LD/LDI/LDR/LEA), SR (ST/STI/STR), nzp (BR)
  //   [8:6]  SR1 (ADD/AND), SR (NOT), BaseR (LDR/STR/JMP)
  function imem_opcode_e opcode();    return imem_opcode_e'(instr[15:12]); endfunction
  function bit [2:0]     f_11_9();    return instr[11:9]; endfunction
  function bit [2:0]     f_8_6();     return instr[8:6];  endfunction
  function bit           imm_flag();  return instr[5];    endfunction
  function bit [2:0]     sr2();       return instr[2:0];  endfunction
  function bit [4:0]     imm5();      return instr[4:0];  endfunction
  function bit [5:0]     offset6();   return instr[5:0];  endfunction
  function bit [8:0]     pcoffset9(); return instr[8:0];  endfunction

  // Same rules as legal_opcode_c + legal_fixed_bits_c, evaluated without the
  // constraint solver.
  static function bit is_legal(bit [15:0] w);
    case (w[15:12])
      IMEM_BR, IMEM_LD, IMEM_ST, IMEM_LDR, IMEM_STR, IMEM_LDI, IMEM_STI, IMEM_LEA:
                          return 1'b1;
      IMEM_ADD, IMEM_AND: return w[5] || (w[4:3] == 2'b00);
      IMEM_NOT:           return (w[5:0] == 6'b111111);
      IMEM_JMP:           return (w[11:9] == 3'b000) && (w[5:0] == 6'b000000);
      default:            return 1'b0;   // JSR, RTI, TRAP, 1101
    endcase
  endfunction

  // Stimulus scope used by imem_responder_sequence to build its no-repeat pool.
  // It must accept exactly the words this class's constraints accept: here
  // legal_opcode_c + legal_fixed_bits_c. Every extension that adds constraints
  // overrides it the same way. A plain function is used instead of calling
  // randomize(null) on all 65,536 words, because tools print a warning for
  // each failed randomize() and most of those checks would fail. The sequence
  // cross-checks the function against the constraints in both directions.
  virtual function bit in_scope(bit [15:0] w);
    return is_legal(w);
  endfunction

  // Short disassembly for log messages.
  static function string disasm(bit [15:0] w);
    string r1, r2;
    r1 = $sformatf("R%0d", w[11:9]);
    r2 = $sformatf("R%0d", w[8:6]);
    case (w[15:12])
      IMEM_ADD: return w[5] ? $sformatf("ADD %s, %s, #%0d", r1, r2, $signed(w[4:0]))
                            : $sformatf("ADD %s, %s, R%0d", r1, r2, w[2:0]);
      IMEM_AND: return w[5] ? $sformatf("AND %s, %s, #%0d", r1, r2, $signed(w[4:0]))
                            : $sformatf("AND %s, %s, R%0d", r1, r2, w[2:0]);
      IMEM_NOT: return $sformatf("NOT %s, %s", r1, r2);
      IMEM_BR:  return $sformatf("BR%s%s%s #%0d", w[11] ? "n" : "", w[10] ? "z" : "", w[9] ? "p" : "",
                                 $signed(w[8:0]));
      IMEM_JMP: return $sformatf("JMP %s", r2);
      IMEM_LD:  return $sformatf("LD %s, #%0d",  r1, $signed(w[8:0]));
      IMEM_LDI: return $sformatf("LDI %s, #%0d", r1, $signed(w[8:0]));
      IMEM_LEA: return $sformatf("LEA %s, #%0d", r1, $signed(w[8:0]));
      IMEM_ST:  return $sformatf("ST %s, #%0d",  r1, $signed(w[8:0]));
      IMEM_STI: return $sformatf("STI %s, #%0d", r1, $signed(w[8:0]));
      IMEM_LDR: return $sformatf("LDR %s, %s, #%0d", r1, r2, $signed(w[5:0]));
      IMEM_STR: return $sformatf("STR %s, %s, #%0d", r1, r2, $signed(w[5:0]));
      default:  return "UNSUPPORTED";
    endcase
  endfunction
  // pragma uvmf custom class_item_additional end

  //*******************************************************************
  //*******************************************************************
  // Macros that define structs and associated functions are
  // located in imem_macros.svh

  //*******************************************************************
  // Monitor macro used by imem_monitor and imem_monitor_bfm
  // This struct is defined in imem_macros.svh
  `imem_MONITOR_STRUCT
    imem_monitor_s imem_monitor_struct;
  //*******************************************************************
  // FUNCTION: to_monitor_struct()
  // This function packs transaction variables into a imem_monitor_s
  // structure.  The function returns the handle to the imem_monitor_struct.
  // This function is defined in imem_macros.svh
  `imem_TO_MONITOR_STRUCT_FUNCTION 
  //*******************************************************************
  // FUNCTION: from_monitor_struct()
  // This function unpacks the struct provided as an argument into transaction 
  // variables of this class.
  // This function is defined in imem_macros.svh
  `imem_FROM_MONITOR_STRUCT_FUNCTION 

  //*******************************************************************
  // Initiator macro used by imem_driver and imem_driver_bfm
  // to communicate initiator driven data to imem_driver_bfm.
  // This struct is defined in imem_macros.svh
  `imem_INITIATOR_STRUCT
    imem_initiator_s imem_initiator_struct;
  //*******************************************************************
  // FUNCTION: to_initiator_struct()
  // This function packs transaction variables into a imem_initiator_s
  // structure.  The function returns the handle to the imem_initiator_struct.
  // This function is defined in imem_macros.svh
  `imem_TO_INITIATOR_STRUCT_FUNCTION  
  //*******************************************************************
  // FUNCTION: from_initiator_struct()
  // This function unpacks the struct provided as an argument into transaction 
  // variables of this class.
  // This function is defined in imem_macros.svh
  `imem_FROM_INITIATOR_STRUCT_FUNCTION 

  //*******************************************************************
  // Responder macro used by imem_driver and imem_driver_bfm
  // to communicate Responder driven data to imem_driver_bfm.
  // This struct is defined in imem_macros.svh
  `imem_RESPONDER_STRUCT
    imem_responder_s imem_responder_struct;
  //*******************************************************************
  // FUNCTION: to_responder_struct()
  // This function packs transaction variables into a imem_responder_s
  // structure.  The function returns the handle to the imem_responder_struct.
  // This function is defined in imem_macros.svh
  `imem_TO_RESPONDER_STRUCT_FUNCTION 
  //*******************************************************************
  // FUNCTION: from_responder_struct()
  // This function unpacks the struct provided as an argument into transaction 
  // variables of this class.
  // This function is defined in imem_macros.svh
  `imem_FROM_RESPONDER_STRUCT_FUNCTION 
  // ****************************************************************************
  // FUNCTION : new()
  // This function is the standard SystemVerilog constructor.
  //
  function new( string name = "" );
    super.new( name );
  endfunction

  // ****************************************************************************
  // FUNCTION: convert2string()
  // This function converts all variables in this class to a single string for 
  // logfile reporting.
  //
  virtual function string convert2string();
    // pragma uvmf custom convert2string begin
    return $sformatf("addr:0x%04h instr:0x%04h (%s)", addr, instr, disasm(instr));
    // pragma uvmf custom convert2string end
  endfunction

  //*******************************************************************
  // FUNCTION: do_print()
  // This function is automatically called when the .print() function
  // is called on this class.
  //
  virtual function void do_print(uvm_printer printer);
    // pragma uvmf custom do_print begin
    // UVMF_CHANGE_ME : Current contents of do_print allows for the use of UVM 1.1d, 1.2 or P1800.2.
    // Update based on your own printing preference according to your preferred UVM version
    $display(convert2string());
    // pragma uvmf custom do_print end
  endfunction

  //*******************************************************************
  // FUNCTION: do_compare()
  // This function is automatically called when the .compare() function
  // is called on this class.
  //
  virtual function bit do_compare (uvm_object rhs, uvm_comparer comparer);
    imem_transaction  RHS;
    if (!$cast(RHS,rhs)) return 0;
    // pragma uvmf custom do_compare begin
    // UVMF_CHANGE_ME : Eliminate comparison of variables not to be used for compare
    return (super.do_compare(rhs,comparer)
            &&(this.addr == RHS.addr)
            &&(this.instr == RHS.instr)
            );
    // pragma uvmf custom do_compare end
  endfunction

  //*******************************************************************
  // FUNCTION: do_copy()
  // This function is automatically called when the .copy() function
  // is called on this class.
  //
  virtual function void do_copy (uvm_object rhs);
    imem_transaction  RHS;
    assert($cast(RHS,rhs));
    // pragma uvmf custom do_copy begin
    super.do_copy(rhs);
    this.addr = RHS.addr;
    this.instr = RHS.instr;
    // pragma uvmf custom do_copy end
  endfunction

  // ****************************************************************************
  // FUNCTION: add_to_wave()
  // This function is used to display variables in this class in the waveform 
  // viewer.  The start_time and end_time variables must be set before this 
  // function is called.  If the start_time and end_time variables are not set
  // the transaction will be hidden at 0ns on the waveform display.
  // 
  virtual function void add_to_wave(int transaction_viewing_stream_h);
    `ifdef QUESTA
    if (transaction_view_h == 0) begin
      transaction_view_h = $begin_transaction(transaction_viewing_stream_h,"imem_transaction",start_time);
    end
    super.add_to_wave(transaction_view_h);
    // pragma uvmf custom add_to_wave begin
    // UVMF_CHANGE_ME : Color can be applied to transaction entries based on content, example below
    // case()
    //   1 : $add_color(transaction_view_h,"red");
    //   default : $add_color(transaction_view_h,"grey");
    // endcase
    // UVMF_CHANGE_ME : Eliminate transaction variables not wanted in transaction viewing in the waveform viewer
    $add_attribute(transaction_view_h,addr,"addr");
    $add_attribute(transaction_view_h,instr,"instr");
    // pragma uvmf custom add_to_wave end
    $end_transaction(transaction_view_h,end_time);
    $free_transaction(transaction_view_h);
    `endif // QUESTA
  endfunction

endclass

// pragma uvmf custom external begin
// pragma uvmf custom external end

