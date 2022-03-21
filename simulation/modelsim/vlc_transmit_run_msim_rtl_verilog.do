transcript on
if ![file isdirectory verilog_libs] {
	file mkdir verilog_libs
}

vlib verilog_libs/altera_ver
vmap altera_ver ./verilog_libs/altera_ver
vlog -vlog01compat -work altera_ver {d:/altera/15.0/quartus/eda/sim_lib/altera_primitives.v}

vlib verilog_libs/lpm_ver
vmap lpm_ver ./verilog_libs/lpm_ver
vlog -vlog01compat -work lpm_ver {d:/altera/15.0/quartus/eda/sim_lib/220model.v}

vlib verilog_libs/sgate_ver
vmap sgate_ver ./verilog_libs/sgate_ver
vlog -vlog01compat -work sgate_ver {d:/altera/15.0/quartus/eda/sim_lib/sgate.v}

vlib verilog_libs/altera_mf_ver
vmap altera_mf_ver ./verilog_libs/altera_mf_ver
vlog -vlog01compat -work altera_mf_ver {d:/altera/15.0/quartus/eda/sim_lib/altera_mf.v}

vlib verilog_libs/altera_lnsim_ver
vmap altera_lnsim_ver ./verilog_libs/altera_lnsim_ver
vlog -sv -work altera_lnsim_ver {d:/altera/15.0/quartus/eda/sim_lib/altera_lnsim.sv}

vlib verilog_libs/cycloneive_ver
vmap cycloneive_ver ./verilog_libs/cycloneive_ver
vlog -vlog01compat -work cycloneive_ver {d:/altera/15.0/quartus/eda/sim_lib/cycloneive_atoms.v}

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/uart_rx.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/vlc_transmit.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/qam16.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/pll_mul2.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/pll_addCP.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/Fre_Division.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/fft_ctrl.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/conv_code.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/add_CP.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/RAM_real.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/RAM_imag.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/RAM_ctrl.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/ROM_syn.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/RAM_addcp.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/addcp_ctrl.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/fifo_rx.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/db {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/db/pll_mul2_altpll.v}
vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/db {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/db/pll_addcp_altpll.v}
vlib fft_ip
vmap fft_ip fft_ip
vlog -vlog01compat -work fft_ip +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/fft_ip/synthesis {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/fft_ip/synthesis/fft_ip.v}
vlog -sv -work fft_ip +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/fft_ip/synthesis/submodules {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/fft_ip/synthesis/submodules/fft_ip_fft_ii_0.sv}
vcom -93 -work fft_ip {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/fft_ip/synthesis/submodules/auk_dspip_text_pkg.vhd}
vcom -93 -work fft_ip {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/fft_ip/synthesis/submodules/auk_dspip_math_pkg.vhd}
vcom -93 -work fft_ip {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/fft_ip/synthesis/submodules/auk_dspip_lib_pkg.vhd}

vlog -vlog01compat -work work +incdir+C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/sim {C:/Users/fz.000/Desktop/vlc_system/experiment/vlc_transmit/sim/test_transmit.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -L fft_ip -voptargs="+acc"  test_transmit

add wave *
view structure
view signals
run -all
