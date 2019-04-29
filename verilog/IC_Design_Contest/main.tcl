# Import Design
read_file -format verilog  "./LEDDC_v10.v"

current_design [get_designs LEDDC]
link

source -echo -verbose ./LEDDC_DC.sdc

# Compile Design
current_design [get_designs LEDDC]

set high_fanout_net_threshold 0

uniquify
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

compile_ultra

# Output Design
current_design [get_designs LEDDC]

remove_unconnected_ports -blast_buses [get_cells -hierarchical *]

set bus_inference_style {%s[%d]}
set bus_naming_style {%s[%d]}
set hdlout_internal_busses true
change_names -hierarchy -rule verilog
define_name_rules name_rule -allowed {a-z A-Z 0-9 _} -max_length 255 -type cell
define_name_rules name_rule -allowed {a-z A-Z 0-9 _[]} -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
define_name_rules name_rule -case_insensitive
change_names -hierarchy -rules name_rule

write -format ddc     -hierarchy -output "LEDDC_syn.ddc"
write -format verilog -hierarchy -output "LEDDC_syn.v"
write_sdf -version 2.1  LEDDC_syn.sdf
report_timing -path full -delay max -max_paths 1 -nworst 1
report_area -nosplit