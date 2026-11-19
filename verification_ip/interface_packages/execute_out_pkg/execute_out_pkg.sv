
package execute_out_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  import execute_out_types_pkg::*;

  `include "execute_out_transaction.svh"
  `include "execute_out_monitor.svh"
  `include "execute_out_agent.svh"

endpackage
/*SystemVerilog 的 package 可以包含 Class Definition
但不能直接在 Package 內宣告 Interface
所以我們讓 Interface 獨立編譯，
再讓 UVM Class 透過 Virtual Interface Handle 存取它*/
