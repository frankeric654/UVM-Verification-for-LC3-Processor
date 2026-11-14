// Cycle model based on the supplied controller_model and LC3_DesignSpec.
// State belongs to each object and is reset explicitly. No DUT outputs are inputs.
// Sampling contract: one call after each rising edge, at the following falling edge.
class control_reference_model extends uvm_object;
    `uvm_object_utils(control_reference_model)
    typedef enum bit [2:0] {
        IDLE = 3, READ = 0, WRITE = 2, INDIRECT_READ = 1, INDIRECT_WRITE = 5
    } memory_state_t;
    typedef struct packed {
        bit supported, control_op, memory_op, writes_dr, use_sr1, use_sr2;
        bit [3:0] opcode;
        bit [2:0] dr, sr1, sr2;
    } instruction_t;

    protected bit seen_reset;
    protected bit fe1_valid, fe2_valid, dec_valid, exe_valid;
    protected memory_state_t memory_state;

    function new(string name = "control_reference_model");
        super.new(name);
        seen_reset = 0;
        memory_state = IDLE;
    endfunction

    protected function instruction_t decode(logic [15:0] ir);
        instruction_t d = '0;
        d.opcode = ir[15:12];
        d.supported = d.opcode inside {0,1,2,3,5,6,7,9,10,11,12,14};
        d.control_op = d.opcode inside {0,12};
        d.memory_op = d.opcode inside {2,3,6,7,10,11};
        d.writes_dr = d.opcode inside {1,2,5,6,9,10,14};
        d.use_sr1 = d.opcode inside {1,5,6,7,9,12};
        d.use_sr2 = d.opcode inside {3,7,11} ||
                    (d.opcode inside {1,5} && !ir[5]);
        d.dr = ir[11:9];
        d.sr1 = ir[8:6];
        d.sr2 = d.opcode inside {3,7,11} ? ir[11:9] : ir[2:0];
        return d;
    endfunction

    function void reset_model();
        seen_reset = 1;
        // Reset establishes PC. The first post-reset edge starts Fetch 2.
        // Equivalent to the supplied model's initial Fetch-1 priming call.
        fe1_valid = 1;
        fe2_valid = 0;
        dec_valid = 0;
        exe_valid = 0;
        memory_state = IDLE;
    endfunction

    function control_out_transaction predict(control_in_transaction t, bit reset_enable_fetch = 0);
        control_out_transaction p = control_out_transaction::type_id::create("predicted");
        instruction_t fetched, decoded, executed;
        bit fetch_valid, stalled, has_branch, branch_resolved, branch_taken;
        bit next_fe1, next_fe2, next_dec, next_exe;
        p.cycle = t.cycle;
        p.sample_time = t.sample_time;
        p.reset = t.reset;
        {p.enable_updatePC, p.enable_fetch, p.enable_decode, p.enable_execute,
         p.enable_writeback, p.bypass_alu_1, p.bypass_alu_2, p.bypass_mem_1,
         p.bypass_mem_2, p.br_taken} = '0;
        p.mem_state = 3;

        if ($isunknown(t.reset))
            `uvm_fatal("CONTROL_RESET_X", "Synchronous reset contains X/Z")
        if (t.reset) begin
            reset_model();
            p.enable_fetch = reset_enable_fetch;
            return p;
        end
        if (!seen_reset)
            `uvm_fatal("CONTROL_NO_RESET", "Control monitoring must begin before a synchronous reset")
        if ($isunknown({t.complete_instr, t.IR, t.IR_Exec}))
            `uvm_fatal("CONTROL_INPUT_X", {"Cannot predict controller inputs: ", t.convert2string()})

        fetched = decode(t.Instr_dout);
        decoded = decode(t.IR);
        executed = decode(t.IR_Exec);
        fetch_valid = fe2_valid && t.complete_instr;
        if (fetch_valid && ($isunknown(t.Instr_dout) || !fetched.supported))
            `uvm_fatal("CONTROL_OPCODE", "Valid fetched instruction is unknown or outside the supported 12 opcodes")
        if ((dec_valid && !decoded.supported) || (exe_valid && !executed.supported))
            `uvm_fatal("CONTROL_OPCODE", "Valid pipeline instruction is outside the supported 12 opcodes")

        branch_resolved = exe_valid && executed.control_op;
        if (branch_resolved && $isunknown({t.NZP, t.psr}))
            `uvm_fatal("CONTROL_FLAGS_X", "Branch resolution uses unknown NZP/PSR")
        branch_taken = branch_resolved && ((t.psr & t.NZP) != 0);

        if (exe_valid) begin
            if (memory_state != IDLE && $isunknown(t.complete_data))
                `uvm_fatal("CONTROL_COMPLETE_X", "Active data-memory operation has unknown completion")
            case (memory_state)
                IDLE: case (executed.opcode)
                    2,6: memory_state = READ;
                    3,7: memory_state = WRITE;
                    10: memory_state = INDIRECT_READ;
                    11: memory_state = INDIRECT_WRITE;
                    default: ;
                endcase
                READ, WRITE: if (t.complete_data) memory_state = IDLE;
                INDIRECT_READ: if (t.complete_data) memory_state = READ;
                INDIRECT_WRITE: if (t.complete_data) memory_state = WRITE;
                default: `uvm_fatal("CONTROL_MODEL_STATE", "Invalid reference memory state")
            endcase
        end
        stalled = memory_state != IDLE;
        has_branch = (fetch_valid && fetched.control_op) ||
                     (dec_valid && decoded.control_op) || branch_resolved;
        next_fe1 = stalled ? fe1_valid : (!has_branch || branch_resolved);
        next_fe2 = stalled ? fe2_valid : (!has_branch && fe1_valid);
        next_dec = stalled ? dec_valid : fetch_valid;
        next_exe = stalled ? exe_valid : dec_valid;

        p.br_taken = !stalled && branch_taken;
        // DesignSpec: an outstanding instruction-memory wait holds the PC.
        // The supplied function omits this completion qualification.
        p.enable_updatePC = !stalled &&
                            ((!has_branch && t.complete_instr) || branch_taken);
        p.enable_fetch = !stalled && next_fe2;
        p.enable_decode = !stalled && next_dec;
        p.enable_execute = !stalled && next_exe;
        p.enable_writeback = !stalled && exe_valid && executed.writes_dr;
        p.mem_state = memory_state[1:0];

        // Combinational bypass logic uses the current IR/IR_Exec, including
        // held register values during stalls, as in the supplied model.
        if (executed.writes_dr) begin
            if (decoded.use_sr1 && decoded.sr1 == executed.dr) begin
                p.bypass_mem_1 = executed.memory_op;
                p.bypass_alu_1 = !executed.memory_op;
            end
            if (decoded.use_sr2 && decoded.sr2 == executed.dr) begin
                p.bypass_mem_2 = executed.memory_op;
                p.bypass_alu_2 = !executed.memory_op;
            end
        end
        fe1_valid = next_fe1;
        fe2_valid = next_fe2;
        dec_valid = next_dec;
        exe_valid = next_exe;
        return p;
    endfunction
endclass
