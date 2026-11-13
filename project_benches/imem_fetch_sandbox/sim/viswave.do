 

onerror resume
wave tags F0
wave update off

wave spacer -backgroundcolor Salmon { fetch_env_fetch_in_agent }
wave add uvm_test_top.environment.fetch_env.fetch_in_agent.fetch_in_agent_monitor.txn_stream -radix string -tag F0
wave group fetch_env_fetch_in_agent_bus
wave add -group fetch_env_fetch_in_agent_bus hdl_top.fetch_env_fetch_in_agent_bus.* -radix hexadecimal -tag F0
wave group fetch_env_fetch_in_agent_bus -collapse
wave insertion [expr [wave index insertpoint] +1]
wave spacer -backgroundcolor Salmon { fetch_env_fetch_out_agent }
wave add uvm_test_top.environment.fetch_env.fetch_out_agent.fetch_out_agent_monitor.txn_stream -radix string -tag F0
wave group fetch_env_fetch_out_agent_bus
wave add -group fetch_env_fetch_out_agent_bus hdl_top.fetch_env_fetch_out_agent_bus.* -radix hexadecimal -tag F0
wave group fetch_env_fetch_out_agent_bus -collapse
wave insertion [expr [wave index insertpoint] +1]
wave spacer -backgroundcolor Salmon { imem_agent }
wave add uvm_test_top.environment.imem_agent.imem_agent_monitor.txn_stream -radix string -tag F0
wave group imem_agent_bus
wave add -group imem_agent_bus hdl_top.imem_agent_bus.* -radix hexadecimal -tag F0
wave group imem_agent_bus -collapse
wave insertion [expr [wave index insertpoint] +1]

wave update on
WaveSetStreamView

