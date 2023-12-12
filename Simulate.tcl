transcript off
#stop previous simulations
quit -sim	

# select a directory for creation of the work directory
vlib work
vmap work work

# compile the program and test-bench files
vcom sim_mem_init.vhdl de2_115_seven_segment.vhdl hex_to_7_seg.vhdl test_RC_receiver.vhdl RC_receiver.vhdl

# initializing the simulation window and adding waves to the simulation window
vsim test_RC_receiver
add wave sim:/test_RC_receiver/dev_to_test/*
 
# define simulation time
run 8275 ns
# zoom out
wave zoom full