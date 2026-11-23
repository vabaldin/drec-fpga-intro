proc build_zynq {module sources constraints use_hp} {
    create_project fpga ./fpga -part xc7z020clg400-2
    set_property target_language Verilog [current_project]
    add_files -norecurse $sources
    update_compile_order -fileset sources_1
    create_bd_design design_1 -dir fpga

    set ps [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps]
    set_property -dict [list \
        CONFIG.PCW_EN_CLK0_PORT 1 CONFIG.PCW_EN_RST0_PORT 1 \
        CONFIG.PCW_PRESET_BANK1_VOLTAGE {LVCMOS 1.8V} \
        CONFIG.PCW_SD0_PERIPHERAL_ENABLE 1 CONFIG.PCW_SD0_SD0_IO {MIO 40 .. 45} \
        CONFIG.PCW_UART1_PERIPHERAL_ENABLE 1 CONFIG.PCW_UART1_UART1_IO {MIO 48 .. 49} \
        CONFIG.PCW_UIPARAM_DDR_BUS_WIDTH {16 Bit} CONFIG.PCW_UIPARAM_DDR_PARTNO {MT41J256M16 RE-125} \
        CONFIG.PCW_USE_M_AXI_GP0 1 CONFIG.PCW_USE_S_AXI_HP0 $use_hp \
    ] $ps
    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
        -config {make_external "FIXED_IO, DDR" Master "Disable" Slave "Disable"} $ps

    set conv [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter:2.1 conv]
    set_property -dict {CONFIG.SI_PROTOCOL AXI3 CONFIG.MI_PROTOCOL AXI4LITE CONFIG.TRANSLATION_MODE 2} $conv
    set reset [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset]
    set_property CONFIG.C_EXT_RESET_HIGH 0 $reset
    set one [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 locked]
    set_property CONFIG.CONST_VAL 1 $one
    set dut [create_bd_cell -type module -reference $module peripheral]

    set clk [get_bd_pins ps/FCLK_CLK0]
    set rst [get_bd_pins reset/peripheral_aresetn]
    connect_bd_net $clk [get_bd_pins {ps/M_AXI_GP0_ACLK reset/slowest_sync_clk conv/aclk peripheral/clk}]
    connect_bd_net $rst [get_bd_pins {conv/aresetn peripheral/rst_n}]
    connect_bd_net [get_bd_pins ps/FCLK_RESET0_N] [get_bd_pins reset/ext_reset_in]
    connect_bd_net [get_bd_pins locked/dout] [get_bd_pins reset/dcm_locked]
    connect_bd_intf_net [get_bd_intf_pins ps/M_AXI_GP0] [get_bd_intf_pins conv/S_AXI]
    connect_bd_intf_net [get_bd_intf_pins conv/M_AXI] [get_bd_intf_pins peripheral/s_axil]

    if {$use_hp} {
        set hp [create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 hp]
        set_property -dict {CONFIG.NUM_SI 1 CONFIG.NUM_MI 1} $hp
        connect_bd_net $clk [get_bd_pins {hp/aclk ps/S_AXI_HP0_ACLK}]
        connect_bd_net $rst [get_bd_pins hp/aresetn]
        connect_bd_intf_net [get_bd_intf_pins peripheral/m_axi] [get_bd_intf_pins hp/S00_AXI]
        connect_bd_intf_net [get_bd_intf_pins hp/M00_AXI] [get_bd_intf_pins ps/S_AXI_HP0]
    }
    if {$constraints ne ""} {
        connect_bd_net [create_bd_port -dir O -from 3 -to 0 -type data led] [get_bd_pins peripheral/led]
        add_files -fileset constrs_1 -norecurse $constraints
    }

    set reg [get_bd_addr_segs -of_objects [get_bd_intf_pins peripheral/s_axil]]
    assign_bd_address -offset 0x43c00000 -range 0x10000 -target_address_space [get_bd_addr_spaces ps/Data] $reg
    assign_bd_address
    validate_bd_design
    save_bd_design
    add_files -norecurse [make_wrapper -files [get_files design_1.bd] -top]
    set_property top design_1_wrapper [current_fileset]
    update_compile_order -fileset sources_1
    launch_runs impl_1 -to_step write_bitstream -jobs 4
    wait_on_run impl_1
    if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {
        error "Bitstream generation failed"
    }
    write_hw_platform -fixed -include_bit -force -file fpga/design_1_wrapper.xsa
}
