create_project fpga ./fpga -part xc7z020clg400-2
add_files [list src/fpga_top.v src/down_cnt.sv]
add_files -fileset constrs_1 ../../../examples/2026/08_led/xdc/fpga.xdc
set_property top fpga_top [current_fileset]
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
    error "Bitstream generation failed"
}
