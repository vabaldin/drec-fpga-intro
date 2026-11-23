source ../09_ps7_axil_led/zynq.tcl
set sources [glob ../02_syst_array/src/*.sv ../03_syst_array/src/*.sv \
    ../05_syst_array/src/*.sv ../06_syst_array/src/*.sv \
    ../../../examples/2026/06_axil2reg/src/axil2reg*.sv]
set sources [lsearch -all -inline -not -glob $sources *_tb.sv]
set sources [lsearch -all -inline -not -glob $sources *_inc.sv]
build_zynq sa_zynq [concat sa_zynq.v $sources] {} 1
