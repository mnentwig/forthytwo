set_property SRC_FILE_INFO {cfile:c:/temp/forthytwo/refImpl/refImpl.srcs/sources_1/ip/clk12_200/clk12_200.xdc rfile:../refImpl.srcs/sources_1/ip/clk12_200/clk12_200.xdc id:1 order:EARLY scoped_inst:iClk1/inst} [current_design]
current_instance iClk1/inst
set_property src_info {type:SCOPED_XDC file:1 line:57 export:INPUT save:INPUT read:READ} [current_design]
set_input_jitter [get_clocks -of_objects [get_ports in12]] 0.83333
