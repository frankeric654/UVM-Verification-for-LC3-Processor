`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class mem_access_scoreboard extends uvm_component;
    `uvm_component_utils(mem_access_scoreboard)

    uvm_analysis_imp_expected #(
        mem_access_out_transaction,
        mem_access_scoreboard
    ) expected_export;
    uvm_analysis_imp_actual #(
        mem_access_out_transaction,
        mem_access_scoreboard
    ) actual_export;

    mem_access_out_transaction expected_queue[$];
    mem_access_out_transaction expected;
    int unsigned expected_count;
    int unsigned comparison_count;
    int unsigned mismatch_count;

    function new(
        string name = "mem_access_scoreboard",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        expected_export = new("expected_export", this);
        actual_export = new("actual_export", this);
        expected_count = 0;
        comparison_count = 0;
        mismatch_count = 0;
    endfunction

    function void write_expected(mem_access_out_transaction transaction);
        expected_queue.push_back(transaction);
        expected_count++;
        `uvm_info(
            "SCOREBOARD_EXPECTED",
            $sformatf(
                "Received expected transaction:\n%s",
                transaction.convert2string()
            ),
            UVM_HIGH
        )
    endfunction

    function void write_actual(mem_access_out_transaction actual);
        if (expected_queue.size() == 0) begin
            mismatch_count++;
            `uvm_error(
                "SCOREBOARD_UNEXPECTED",
                $sformatf(
                    "Received actual transaction with no expected transaction:\n%s",
                    actual.convert2string()
                )
            )
            return;
        end

        expected = expected_queue.pop_front();
        comparison_count++;
        if (actual.compare(expected)) begin
            `uvm_info(
                "SCOREBOARD_MATCH",
                $sformatf(
                    "Transaction matched:\nExpected: %s\nActual: %s",
                    expected.convert2string(),
                    actual.convert2string()
                ),
                UVM_MEDIUM
            )
        end
        else begin
            mismatch_count++;
            `uvm_error(
                "SCOREBOARD_MISMATCH",
                $sformatf(
                    "Transaction mismatch:\nExpected: %s\nActual: %s",
                    expected.convert2string(),
                    actual.convert2string()
                )
            )
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info(
            "SCOREBOARD_REPORT",
            $sformatf(
                "\n\nExpected transactions received: %0d\nComparisons made: %0d\nMismatches: %0d\nExpected transactions remaining: %0d",
                expected_count,
                comparison_count,
                mismatch_count,
                expected_queue.size()
            ),
            UVM_LOW
        )
        if (expected_queue.size() != 0) begin
            `uvm_error(
                "SCOREBOARD_INCOMPLETE",
                $sformatf(
                    "%0d expected transactions were never compared",
                    expected_queue.size()
                )
            )
        end
    endfunction
endclass : mem_access_scoreboard
