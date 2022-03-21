set_global_assignment -entity "fft_ip" -library "lib_fft_ip" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "fft_ip" -library "lib_fft_ip" -name IP_TOOL_VERSION "15.0"
set_global_assignment -entity "fft_ip" -library "lib_fft_ip" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_fft_ip" -name SPD_FILE [file join $::quartus(sip_path) "../fft_ip.spd"]
set_global_assignment -library "lib_fft_ip" -name MISC_FILE [file join $::quartus(sip_path) "../../fft_ip.qsys"]

set_global_assignment -library "lib_fft_ip" -name MISC_FILE [file join $::quartus(sip_path) "fft_ip.v"]
set_global_assignment -library "lib_fft_ip" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_ip_fft_ii_0_opt_twi1.hex"]
set_global_assignment -library "lib_fft_ip" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_ip_fft_ii_0_opt_twi2.hex"]
set_global_assignment -library "lib_fft_ip" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_ip_fft_ii_0_opt_twr1.hex"]
set_global_assignment -library "lib_fft_ip" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_ip_fft_ii_0_opt_twr2.hex"]
set_global_assignment -library "lib_fft_ip" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_ip_fft_ii_0_opt_twi3.hex"]
set_global_assignment -library "lib_fft_ip" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_ip_fft_ii_0_opt_twr3.hex"]
set_global_assignment -library "lib_fft_ip" -name MISC_FILE [file join $::quartus(sip_path) "submodules/fft_ip_fft_ii_0.vo"]
