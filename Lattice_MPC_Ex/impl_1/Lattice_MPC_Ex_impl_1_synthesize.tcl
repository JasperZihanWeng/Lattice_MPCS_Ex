if {[catch {

# define run engine funtion
source [file join {C:/lscc/radiant/2025.2.1} scripts tcl flow run_engine.tcl]
# define global variables
global para
set para(gui_mode) "1"
set para(prj_dir) "C:/Users/Kumar Lab/Desktop/Jasper/Lattice Projects/MPCS_ex/Lattice_MPC_Ex"
if {![file exists {C:/Users/Kumar Lab/Desktop/Jasper/Lattice Projects/MPCS_ex/Lattice_MPC_Ex/impl_1}]} {
  file mkdir {C:/Users/Kumar Lab/Desktop/Jasper/Lattice Projects/MPCS_ex/Lattice_MPC_Ex/impl_1}
}
cd {C:/Users/Kumar Lab/Desktop/Jasper/Lattice Projects/MPCS_ex/Lattice_MPC_Ex/impl_1}
# synthesize IPs
# synthesize VMs
# propgate constraints
file delete -force -- Lattice_MPC_Ex_impl_1_cpe.ldc
::radiant::runengine::run_engine_newmsg cpe -syn synpro -f "Lattice_MPC_Ex_impl_1.cprj" "MPCS_ex.cprj" -a "LFCPNX"  -o Lattice_MPC_Ex_impl_1_cpe.ldc
# synthesize top design
file delete -force -- Lattice_MPC_Ex_impl_1.vm Lattice_MPC_Ex_impl_1.ldc
if {[file normalize "C:/Users/Kumar Lab/Desktop/Jasper/Lattice Projects/MPCS_ex/Lattice_MPC_Ex/impl_1/Lattice_MPC_Ex_impl_1_synplify.tcl"] != [file normalize "./Lattice_MPC_Ex_impl_1_synplify.tcl"]} {
  file copy -force "C:/Users/Kumar Lab/Desktop/Jasper/Lattice Projects/MPCS_ex/Lattice_MPC_Ex/impl_1/Lattice_MPC_Ex_impl_1_synplify.tcl" "./Lattice_MPC_Ex_impl_1_synplify.tcl"
}
if {[ catch {::radiant::runengine::run_engine synpwrap -prj "Lattice_MPC_Ex_impl_1_synplify.tcl" -log "Lattice_MPC_Ex_impl_1.srf"} result options ]} {
    file delete -force -- Lattice_MPC_Ex_impl_1.vm Lattice_MPC_Ex_impl_1.ldc
    return -options $options $result
}
::radiant::runengine::run_postsyn [list -a LFCPNX -p LFCPNX-100 -t LFG672 -sp 9_High-Performance_1.0V -oc Industrial -top -w -o Lattice_MPC_Ex_impl_1_syn.udb Lattice_MPC_Ex_impl_1.vm] [list Lattice_MPC_Ex_impl_1.ldc]

} out]} {
   ::radiant::runengine::runtime_log $out
   exit 1
}
