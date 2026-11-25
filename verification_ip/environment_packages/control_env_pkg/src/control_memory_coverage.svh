class control_memory_coverage extends uvm_component;
    `uvm_component_utils(control_memory_coverage)

    uvm_analysis_imp_cov_in #(control_in_transaction, control_memory_coverage) control_in_export;
    uvm_analysis_imp_cov_out #(control_out_transaction, control_memory_coverage) control_out_export;

    control_in_transaction inputs_by_cycle[longint unsigned];
    control_out_transaction outputs_by_cycle[longint unsigned];

    logic [7:0] compact_state_history;
    logic [1:0] sampled_state;
    logic [1:0] previous_state = 2'd3;
    logic sampled_reset;
    logic sampled_complete_data;
    logic sampled_complete_instr;
    logic sampled_enable_execute;
    int unsigned sampled_complete_corner;
    int unsigned wait_cycles;
    int unsigned stall_cycles;
    int unsigned memory_run_length;
    int unsigned fetch_wait_cycles;
    int unsigned last_data_wait_class;
    int unsigned first_phase_wait_class;
    int unsigned pending_control_class;
    logic [3:0] active_opcode;
    logic [3:0] previous_exec_opcode;
    bit previous_complete_data;
    bit previous_reset;
    bit just_completed_memory;
    bit awaiting_next_fetch;
    bit have_first_phase_wait;
    bit have_previous_exec;
    bit have_active_memory;
    bit pending_control_next;

    logic [15:0] instruction_history[16];
    int unsigned history_count;

    covergroup memory_state_cg with function sample(
        logic [1:0] state, logic reset, logic complete_data, logic [3:0] opcode
    );
        option.per_instance = 1;
        cp_state: coverpoint state {
            bins read = {2'd0};
            bins indirect = {2'd1};
            bins write = {2'd2};
            bins idle = {2'd3};
        }
        cp_reset: coverpoint reset;
        cp_complete_data: coverpoint complete_data;
        cx_reset_state: cross cp_reset, cp_state, cp_complete_data;
        cp_reset_opcode: coverpoint opcode iff (reset) {
            bins memory_ops[] = {4'h2,4'h3,4'h6,4'h7,4'hA,4'hB};
        }
    endgroup

    covergroup mem_state_transition_cg with function sample(
        logic [1:0] previous, logic [1:0] current
    );
        option.per_instance = 1;
        cp_transition: coverpoint {previous, current} {
            bins idle_read = {4'b1100};
            bins idle_pointer = {4'b1101};
            bins idle_write = {4'b1110};
            bins idle_stay = {4'b1111};
            bins read_wait = {4'b0000};
            bins read_done = {4'b0011};
            bins pointer_wait = {4'b0101};
            bins pointer_to_read = {4'b0100};
            bins pointer_to_write = {4'b0110};
            bins write_wait = {4'b1010};
            bins write_done = {4'b1011};
            illegal_bins illegal = {
                4'b0001, 4'b0010, 4'b0111, 4'b1000, 4'b1001
            };
        }
    endgroup

    covergroup dmem_wait_cg with function sample(
        logic [1:0] state, int unsigned wait_class
    );
        option.per_instance = 1;
        cp_state: coverpoint state {
            bins read = {2'd0};
            bins pointer = {2'd1};
            bins write = {2'd2};
        }
        cp_wait: coverpoint wait_class {
            bins zero = {0};
            bins one = {1};
            bins two = {2};
            bins three_four = {3};
            bins five_eight = {4};
            bins nine_plus = {5};
        }
        cx_wait_state: cross cp_state, cp_wait;
    endgroup

    covergroup indirect_wait_cg with function sample(
        logic [3:0] opcode, int unsigned first_wait, int unsigned second_wait
    );
        option.per_instance = 1;
        cp_opcode: coverpoint opcode {
            bins ldi = {4'hA};
            bins sti = {4'hB};
        }
        cp_first_wait: coverpoint first_wait {
            bins zero = {0}; bins one = {1}; bins two_plus = {[2:5]};
        }
        cp_second_wait: coverpoint second_wait {
            bins zero = {0}; bins one = {1}; bins two_plus = {[2:5]};
        }
        cx_phases: cross cp_opcode, cp_first_wait, cp_second_wait;
    endgroup

    covergroup instruction_path_cg with function sample(
        logic [3:0] opcode, int unsigned path
    );
        option.per_instance = 1;
        cp_opcode: coverpoint opcode {
            bins ld = {4'h2}; bins ldr = {4'h6}; bins ldi = {4'hA};
            bins st = {4'h3}; bins str = {4'h7}; bins sti = {4'hB};
        }
        cp_path: coverpoint path {
            bins direct_read = {0};
            bins direct_write = {1};
            bins indirect_read = {2};
            bins indirect_write = {3};
        }
        cx_instr_state_path: cross cp_opcode, cp_path {
            bins ld_path = binsof(cp_opcode.ld) && binsof(cp_path.direct_read);
            bins ldr_path = binsof(cp_opcode.ldr) && binsof(cp_path.direct_read);
            bins st_path = binsof(cp_opcode.st) && binsof(cp_path.direct_write);
            bins str_path = binsof(cp_opcode.str) && binsof(cp_path.direct_write);
            bins ldi_path = binsof(cp_opcode.ldi) && binsof(cp_path.indirect_read);
            bins sti_path = binsof(cp_opcode.sti) && binsof(cp_path.indirect_write);
        }
    endgroup

    covergroup completion_corner_cg with function sample(int unsigned corner);
        option.per_instance = 1;
        cp_corner: coverpoint corner {
            bins complete_high_idle = {0};
            bins complete_high_first_active_cycle = {1};
            bins complete_data_rise_active = {2};
            bins reset_after_completion = {3};
        }
    endgroup

    covergroup instruction_wait_cg with function sample(
        int unsigned fetch_wait, int unsigned data_wait
    );
        option.per_instance = 1;
        cp_fetch_wait: coverpoint fetch_wait {
            bins zero = {0}; bins one = {1}; bins two_plus = {[2:5]};
        }
        cp_data_wait: coverpoint data_wait {
            bins zero = {0}; bins one = {1}; bins two_plus = {[2:5]};
        }
        cx_instr_data_wait: cross cp_fetch_wait, cp_data_wait;
    endgroup

    covergroup stall_length_cg with function sample(
        logic [3:0] opcode, int unsigned length
    );
        option.per_instance = 1;
        cp_opcode: coverpoint opcode {
            bins ld = {4'h2}; bins ldr = {4'h6}; bins ldi = {4'hA};
            bins st = {4'h3}; bins str = {4'h7}; bins sti = {4'hB};
        }
        cp_length: coverpoint length {
            bins one = {1}; bins two = {2}; bins three_plus = {[3:1024]};
        }
        cx_stall_length: cross cp_opcode, cp_length;
    endgroup

    covergroup class_transition_cg with function sample(
        int unsigned previous_class, int unsigned current_class
    );
        option.per_instance = 1;
        cp_previous: coverpoint previous_class {
            bins alu = {0}; bins load = {1}; bins store = {2};
            bins lea = {3}; bins control = {4};
        }
        cp_current: coverpoint current_class {
            bins alu = {0}; bins load = {1}; bins store = {2};
            bins lea = {3}; bins control = {4};
        }
        cx_class_trans: cross cp_previous, cp_current;
    endgroup

    covergroup mem_back_to_back_cg with function sample(
        logic [3:0] previous_opcode, logic [3:0] current_opcode
    );
        option.per_instance = 1;
        cp_previous: coverpoint previous_opcode {
            bins memory_ops[] = {4'h2,4'h3,4'h6,4'h7,4'hA,4'hB};
        }
        cp_current: coverpoint current_opcode {
            bins memory_ops[] = {4'h2,4'h3,4'h6,4'h7,4'hA,4'hB};
        }
        cx_mem_b2b: cross cp_previous, cp_current;
    endgroup

    covergroup memory_run_cg with function sample(int unsigned run_length);
        option.per_instance = 1;
        cp_mem_run_length: coverpoint run_length {
            bins one = {1}; bins two = {2}; bins three = {3}; bins four_plus = {[4:1024]};
        }
    endgroup

    covergroup dependency_cg with function sample(
        logic [3:0] producer_opcode, logic [3:0] consumer_opcode,
        int unsigned role, int unsigned distance, logic [3:0] bypass_route
    );
        option.per_instance = 1;
        cp_producer: coverpoint producer_opcode {
            bins alu[] = {4'h1,4'h5,4'h9};
            bins load[] = {4'h2,4'h6,4'hA};
            bins lea = {4'hE};
        }
        cp_consumer: coverpoint consumer_opcode {
            bins add = {4'h1}; bins and_op = {4'h5}; bins not_op = {4'h9};
            bins st = {4'h3}; bins str = {4'h7}; bins sti = {4'hB};
            bins ldr = {4'h6};
        }
        cp_role: coverpoint role {
            bins sr1 = {0}; bins sr2 = {1}; bins both = {2};
            bins store_sr = {3}; bins base = {4};
        }
        cp_distance: coverpoint distance {
            bins one = {1}; bins two = {2}; bins three_plus = {[3:16]};
        }
        cp_bypass_route: coverpoint bypass_route {
            bins none = {4'b0000};
            bins alu_1 = {4'b0001};
            bins alu_2 = {4'b0010};
            bins mem_1 = {4'b0100};
            bins mem_2 = {4'b1000};
            bins combined[] = {
                4'b0011, 4'b0101, 4'b0110, 4'b0111,
                4'b1001, 4'b1010, 4'b1011, 4'b1100,
                4'b1101, 4'b1110, 4'b1111
            };
        }
        cx_dependency: cross cp_producer, cp_consumer, cp_role,
                       cp_distance, cp_bypass_route;
    endgroup

    covergroup branch_outcome_cg with function sample(
        logic [2:0] mask, logic [2:0] psr, logic taken
    );
        option.per_instance = 1;
        cp_mask: coverpoint mask { bins masks[] = {[0:7]}; }
        cp_psr: coverpoint psr {
            bins n = {3'b100}; bins z = {3'b010}; bins p = {3'b001};
        }
        cp_taken: coverpoint taken;
        cx_branch_outcome: cross cp_mask, cp_psr, cp_taken;
    endgroup

    covergroup load_branch_cg with function sample(
        logic [3:0] load_opcode, logic [2:0] mask, logic [2:0] psr,
        logic taken, int unsigned distance
    );
        option.per_instance = 1;
        cp_load: coverpoint load_opcode {
            bins ld = {4'h2}; bins ldr = {4'h6}; bins ldi = {4'hA};
        }
        cp_mask: coverpoint mask { bins masks[] = {[0:7]}; }
        cp_psr: coverpoint psr {
            bins n = {3'b100}; bins z = {3'b010}; bins p = {3'b001};
        }
        cp_taken: coverpoint taken;
        cp_distance: coverpoint distance {
            bins one = {1}; bins two = {2}; bins three_plus = {[3:16]};
        }
        cx_load_branch: cross cp_load, cp_mask, cp_psr, cp_taken, cp_distance;
    endgroup

    covergroup store_branch_cg with function sample(
        logic [3:0] store_opcode, logic [2:0] mask,
        logic taken, int unsigned distance
    );
        option.per_instance = 1;
        cp_store: coverpoint store_opcode {
            bins st = {4'h3}; bins str = {4'h7}; bins sti = {4'hB};
        }
        cp_mask: coverpoint mask { bins masks[] = {[0:7]}; }
        cp_taken: coverpoint taken;
        cp_distance: coverpoint distance {
            bins one = {1}; bins two = {2}; bins three_plus = {[3:16]};
        }
        cx_store_branch: cross cp_store, cp_mask, cp_taken, cp_distance;
    endgroup

    covergroup control_next_cg with function sample(
        int unsigned control_class, int unsigned next_class
    );
        option.per_instance = 1;
        cp_control: coverpoint control_class {
            bins branch_not_taken = {0};
            bins branch_taken = {1};
            bins jump = {2};
        }
        cp_next: coverpoint next_class {
            bins alu = {0}; bins load = {1}; bins store = {2};
            bins lea = {3}; bins control = {4};
        }
        cx_control_next: cross cp_control, cp_next;
    endgroup

    function new(string name = "control_memory_coverage", uvm_component parent = null);
        super.new(name, parent);
        control_in_export = new("control_in_export", this);
        control_out_export = new("control_out_export", this);
        memory_state_cg = new();
        mem_state_transition_cg = new();
        dmem_wait_cg = new();
        indirect_wait_cg = new();
        instruction_path_cg = new();
        completion_corner_cg = new();
        instruction_wait_cg = new();
        stall_length_cg = new();
        class_transition_cg = new();
        mem_back_to_back_cg = new();
        memory_run_cg = new();
        dependency_cg = new();
        branch_outcome_cg = new();
        load_branch_cg = new();
        store_branch_cg = new();
        control_next_cg = new();
        compact_state_history = 8'hFF;
    endfunction

    function void write_cov_in(control_in_transaction t);
        inputs_by_cycle[t.cycle] = t;
        if (outputs_by_cycle.exists(t.cycle)) begin
            sample_pair(t, outputs_by_cycle[t.cycle]);
            inputs_by_cycle.delete(t.cycle);
            outputs_by_cycle.delete(t.cycle);
        end
    endfunction

    function void write_cov_out(control_out_transaction t);
        outputs_by_cycle[t.cycle] = t;
        if (inputs_by_cycle.exists(t.cycle)) begin
            sample_pair(inputs_by_cycle[t.cycle], t);
            inputs_by_cycle.delete(t.cycle);
            outputs_by_cycle.delete(t.cycle);
        end
    endfunction

    function int unsigned wait_class(int unsigned cycles);
        if (cycles == 0) return 0;
        if (cycles == 1) return 1;
        if (cycles == 2) return 2;
        if (cycles <= 4) return 3;
        if (cycles <= 8) return 4;
        return 5;
    endfunction

    function int unsigned short_wait_class(int unsigned cycles);
        if (cycles == 0) return 0;
        if (cycles == 1) return 1;
        return 2;
    endfunction

    function bit is_memory_opcode(logic [3:0] opcode);
        return opcode inside {4'h2,4'h3,4'h6,4'h7,4'hA,4'hB};
    endfunction

    function int unsigned instruction_class(logic [3:0] opcode);
        if (opcode inside {4'h1,4'h5,4'h9}) return 0;
        if (opcode inside {4'h2,4'h6,4'hA}) return 1;
        if (opcode inside {4'h3,4'h7,4'hB}) return 2;
        if (opcode == 4'hE) return 3;
        if (opcode inside {4'h0,4'hC}) return 4;
        return 5;
    endfunction

    function bit writes_register(logic [3:0] opcode);
        return opcode inside {4'h1,4'h2,4'h5,4'h6,4'h9,4'hA,4'hE};
    endfunction

    function int signed find_producer(logic [2:0] source_reg);
        for (int i = 0; i < history_count; i++) begin
            if (writes_register(instruction_history[i][15:12]) &&
                instruction_history[i][11:9] == source_reg)
                return i;
        end
        return -1;
    endfunction

    function void check_dependency(logic [15:0] consumer, int unsigned role,
                                   logic [2:0] source_reg,
                                   control_out_transaction out_tx);
        int producer_index;
        producer_index = find_producer(source_reg);
        if (producer_index >= 0)
            dependency_cg.sample(
                instruction_history[producer_index][15:12],
                consumer[15:12],
                role,
                producer_index + 1,
                {out_tx.bypass_mem_2, out_tx.bypass_mem_1,
                 out_tx.bypass_alu_2, out_tx.bypass_alu_1}
            );
    endfunction

    function void sample_dependencies(logic [15:0] instruction,
                                      control_out_transaction out_tx);
        logic [3:0] opcode;
        logic [2:0] src1;
        logic [2:0] src2;
        bit use_src1;
        bit use_src2;
        int src1_producer;
        int src2_producer;

        opcode = instruction[15:12];
        use_src1 = 0;
        use_src2 = 0;
        src1 = instruction[8:6];
        src2 = instruction[2:0];

        case (opcode)
            4'h1,4'h5: begin
                use_src1 = 1;
                use_src2 = !instruction[5];
            end
            4'h9: use_src1 = 1;
            4'h3,4'hB: begin
                use_src1 = 1;
                src1 = instruction[11:9];
            end
            4'h7: begin
                use_src1 = 1;
                src1 = instruction[11:9];
                check_dependency(instruction, 4, instruction[8:6], out_tx);
            end
            4'h6: check_dependency(instruction, 4, instruction[8:6], out_tx);
            default: ;
        endcase

        if (use_src1 && use_src2 && src1 == src2) begin
            src1_producer = find_producer(src1);
            src2_producer = find_producer(src2);
            if (src1_producer >= 0 && src1_producer == src2_producer)
                check_dependency(instruction, 2, src1, out_tx);
            else begin
                check_dependency(instruction, 0, src1, out_tx);
                check_dependency(instruction, 1, src2, out_tx);
            end
        end else begin
            if (use_src1)
                check_dependency(instruction,
                    opcode inside {4'h3,4'h7,4'hB} ? 3 : 0, src1, out_tx);
            if (use_src2)
                check_dependency(instruction, 1, src2, out_tx);
        end
    endfunction

    function void update_instruction_history(logic [15:0] instruction);
        for (int i = 15; i > 0; i--)
            instruction_history[i] = instruction_history[i-1];
        instruction_history[0] = instruction;
        if (history_count < 16) history_count++;
    endfunction

    function void sample_pair(control_in_transaction in_tx,
                              control_out_transaction out_tx);
        logic [3:0] opcode;
        int unsigned current_class;
        int unsigned previous_class;
        int unsigned current_path;
        int unsigned current_wait_class;

        sampled_state = out_tx.mem_state;
        sampled_reset = in_tx.reset;
        sampled_complete_data = in_tx.complete_data;
        sampled_complete_instr = in_tx.complete_instr;
        sampled_enable_execute = out_tx.enable_execute;
        opcode = in_tx.IR_Exec[15:12];

        memory_state_cg.sample(sampled_state, sampled_reset,
                               sampled_complete_data, opcode);
        if (!sampled_reset)
            mem_state_transition_cg.sample(previous_state, sampled_state);

        if (sampled_reset && !previous_reset) begin
            history_count = 0;
            have_previous_exec = 0;
            have_active_memory = 0;
            have_first_phase_wait = 0;
            awaiting_next_fetch = 0;
            pending_control_next = 0;
            wait_cycles = 0;
            stall_cycles = 0;
            memory_run_length = 0;
        end

        if (sampled_reset && just_completed_memory)
            sampled_complete_corner = 3;
        else if (sampled_state == 2'd3 && sampled_complete_data)
            sampled_complete_corner = 0;
        else if (sampled_state != 2'd3 && sampled_complete_data &&
                 sampled_state != previous_state)
            sampled_complete_corner = 1;
        else if (sampled_state != 2'd3 && sampled_complete_data &&
                 !previous_complete_data)
            sampled_complete_corner = 2;
        else
            sampled_complete_corner = 4;
        if (sampled_complete_corner == 3 ||
            (sampled_complete_corner <= 2 && !sampled_reset))
            completion_corner_cg.sample(sampled_complete_corner);

        if (sampled_reset)
            compact_state_history = 8'hFF;
        else begin
            if (previous_state == 2'd3 && sampled_state != 2'd3)
                compact_state_history = 8'hFF;
            if (sampled_state != previous_state)
                compact_state_history = {
                    compact_state_history[5:0], sampled_state
                };
        end
        if (!sampled_reset && sampled_state != 2'd3) begin
            if (!have_active_memory || previous_state == 2'd3) begin
                active_opcode = opcode;
                have_active_memory = 1;
                stall_cycles = 0;
                wait_cycles = 0;
            end
            stall_cycles++;
            if (!sampled_complete_data)
                wait_cycles++;
            else begin
                current_wait_class = wait_class(wait_cycles);
                dmem_wait_cg.sample(sampled_state, current_wait_class);
                last_data_wait_class = short_wait_class(wait_cycles);
                if (sampled_state == 2'd1)
                    first_phase_wait_class = last_data_wait_class;
                if ((sampled_state == 2'd0 || sampled_state == 2'd2) &&
                    have_first_phase_wait &&
                    (active_opcode == 4'hA || active_opcode == 4'hB))
                    indirect_wait_cg.sample(active_opcode,
                        first_phase_wait_class, last_data_wait_class);
                if (sampled_state == 2'd1)
                    have_first_phase_wait = 1;
                wait_cycles = 0;
            end
        end

        if (!sampled_reset && previous_state != 2'd3 &&
            sampled_state == 2'd3) begin
            if (have_active_memory) begin
                stall_length_cg.sample(active_opcode, stall_cycles);
                if (compact_state_history == 8'hF3)
                    current_path = 0;
                else if (compact_state_history == 8'hFB)
                    current_path = 1;
                else if (compact_state_history == 8'hD3)
                    current_path = 2;
                else if (compact_state_history == 8'hDB)
                    current_path = 3;
                else
                    current_path = 4;
                if (current_path < 4)
                    instruction_path_cg.sample(active_opcode, current_path);
                just_completed_memory = 1;
                awaiting_next_fetch = 1;
                fetch_wait_cycles = 0;
                have_active_memory = 0;
                have_first_phase_wait = 0;
            end
        end else if (!sampled_reset && sampled_state == 2'd3) begin
            just_completed_memory = 0;
        end

        if (awaiting_next_fetch && !sampled_reset) begin
            if (!sampled_complete_instr)
                fetch_wait_cycles++;
            else begin
                instruction_wait_cg.sample(
                    short_wait_class(fetch_wait_cycles),
                    last_data_wait_class
                );
                awaiting_next_fetch = 0;
            end
        end

        if (sampled_enable_execute && !sampled_reset) begin
            current_class = instruction_class(opcode);
            if (pending_control_next) begin
                control_next_cg.sample(pending_control_class, current_class);
                pending_control_next = 0;
            end
            if (have_previous_exec) begin
                previous_class = instruction_class(previous_exec_opcode);
                class_transition_cg.sample(previous_class, current_class);
                if (is_memory_opcode(previous_exec_opcode) &&
                    is_memory_opcode(opcode))
                    mem_back_to_back_cg.sample(previous_exec_opcode, opcode);
            end
            if (current_class != 5)
                sample_dependencies(in_tx.IR_Exec, out_tx);
            if (opcode == 4'h0) begin
                branch_outcome_cg.sample(
                    in_tx.IR_Exec[11:9], in_tx.psr, out_tx.br_taken
                );
                for (int i = 0; i < history_count; i++) begin
                    if (writes_register(instruction_history[i][15:12])) begin
                        if (instruction_history[i][15:12] inside {4'h2,4'h6,4'hA})
                            load_branch_cg.sample(
                                instruction_history[i][15:12],
                                in_tx.IR_Exec[11:9], in_tx.psr,
                                out_tx.br_taken, i + 1
                            );
                        break;
                    end
                end
                for (int i = 0; i < history_count; i++) begin
                    if (writes_register(instruction_history[i][15:12]))
                        break;
                    if (instruction_history[i][15:12] inside {4'h3,4'h7,4'hB}) begin
                        store_branch_cg.sample(
                            instruction_history[i][15:12],
                            in_tx.IR_Exec[11:9], out_tx.br_taken, i + 1
                        );
                        break;
                    end
                end
                pending_control_class = out_tx.br_taken ? 1 : 0;
                pending_control_next = 1;
            end else if (opcode == 4'hC) begin
                pending_control_class = 2;
                pending_control_next = 1;
            end
            if (is_memory_opcode(opcode))
                memory_run_length++;
            else if (memory_run_length != 0) begin
                memory_run_cg.sample(memory_run_length);
                memory_run_length = 0;
            end
            previous_exec_opcode = opcode;
            have_previous_exec = 1;
            update_instruction_history(in_tx.IR_Exec);
        end
        previous_state = sampled_state;
        previous_complete_data = sampled_complete_data;
        previous_reset = sampled_reset;
        if (sampled_reset)
            just_completed_memory = 0;
    endfunction

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        if (memory_run_length != 0)
            memory_run_cg.sample(memory_run_length);
        `uvm_info("LC3_MEMORY_COV",
            $sformatf("state=%0.2f%% transitions=%0.2f%% waits=%0.2f%% indirect_waits=%0.2f%% paths=%0.2f%% completion=%0.2f%% fetch_waits=%0.2f%% stalls=%0.2f%% classes=%0.2f%% memory_b2b=%0.2f%% memory_runs=%0.2f%% dependencies=%0.2f%% branches=%0.2f%% load_branch=%0.2f%% store_branch=%0.2f%% control_next=%0.2f%%",
                memory_state_cg.get_inst_coverage(),
                mem_state_transition_cg.get_inst_coverage(),
                dmem_wait_cg.get_inst_coverage(),
                indirect_wait_cg.get_inst_coverage(),
                instruction_path_cg.get_inst_coverage(),
                completion_corner_cg.get_inst_coverage(),
                instruction_wait_cg.get_inst_coverage(),
                stall_length_cg.get_inst_coverage(),
                class_transition_cg.get_inst_coverage(),
                mem_back_to_back_cg.get_inst_coverage(),
                memory_run_cg.get_inst_coverage(),
                dependency_cg.get_inst_coverage(),
                branch_outcome_cg.get_inst_coverage(),
                load_branch_cg.get_inst_coverage(),
                store_branch_cg.get_inst_coverage(),
                control_next_cg.get_inst_coverage()),
            UVM_LOW)
    endfunction
endclass
