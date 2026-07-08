#-- Lattice Semiconductor Corporation Ltd.
#-- Synplify OEM project file

#device options
set_option -technology LFCPNX
set_option -part LFCPNX_100
set_option -package LFG672I
set_option -speed_grade -9
#compilation/mapping options
set_option -symbolic_fsm_compiler true
set_option -resource_sharing true

#use verilog standard option
set_option -vlog_std v2001

#map options
set_option -frequency 200
set_option -maxfan 1000
set_option -auto_constrain_io 0
set_option -retiming false; set_option -pipe true
set_option -force_gsr false
set_option -compiler_compatible 0


set_option -default_enum_encoding default

#timing analysis options



#automatic place and route (vendor) options
set_option -write_apr_constraint 1

#synplifyPro options
set_option -fix_gated_and_generated_clocks 0
set_option -update_models_cp 0
set_option -resolve_multiple_driver 0


set_option -rw_check_on_ram 0
set_option -seqshift_no_replicate 0
set_option -automatic_compile_point 0

#-- set any command lines input by customer

set_option -dup false
set_option -disable_io_insertion false
add_file -constraint {C:/lscc/radiant/2025.2.1/scripts/tcl/flow/radiant_synplify_vars.tcl}
add_file -constraint {Lattice_MPC_Ex_impl_1_cpe.ldc}
add_file -verilog {C:/lscc/radiant/2025.2.1/ip/pmi/pmi_lfcpnx.v}
add_file -vhdl -lib pmi {C:/lscc/radiant/2025.2.1/ip/pmi/pmi_lfcpnx.vhd}
add_file -verilog -vlog_std v2001 {C:/Users/Kumar Lab/Desktop/Jasper/Lattice Projects/MPCS_ex/rtl/Flashing_Light.v}
add_file -verilog -vlog_std v2001 {C:/Users/Kumar Lab/Desktop/Jasper/Lattice Projects/MPCS_ex/rtl/MPCS_ex.v}
add_file -verilog -vlog_std v2001 {C:/Users/Kumar Lab/Desktop/Jasper/Lattice Projects/MPCS_ex/rtl/MPCS_ex.v}
#-- top module name
set_option -top_module flashing_lights
set_option -include_path {C:/Users/Kumar Lab/Desktop/Jasper/Lattice Projects/MPCS_ex/Lattice_MPC_Ex}
set_option -include_path {C:/Users/Kumar Lab/Desktop/Jasper/Lattice Projects/MPCS_ex}

#-- set result format/file last
project -result_format "vm"
project -result_file "./Lattice_MPC_Ex_impl_1.vm"

#-- error message log file
project -log_file {Lattice_MPC_Ex_impl_1.srf}

project -run -clean
