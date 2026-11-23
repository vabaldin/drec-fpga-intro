source zynq.tcl
set sources [glob ../../../examples/2026/06_axil2reg/src/axil2reg*.sv]
set sources [lsearch -all -inline -not -glob $sources *_inc.sv]
build_zynq axil_led [concat axil_led.v $sources] ../../../examples/2026/09_ps7_axi_led/fpga.xdc 0
