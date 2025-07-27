vlib work
vlog ../src/qpi_memory_slave.v tester_qpi_write_single.v
vsim -voptargs=+acc work.tester_qpi_write_single
add wave  \
	sim:/tester_qpi_write_single/qpislave/main_clock \
	sim:/tester_qpi_write_single/qpislave/sck \
	sim:/tester_qpi_write_single/qpislave/cs \
	sim:/tester_qpi_write_single/qpislave/io[0] \
    sim:/tester_qpi_write_single/qpislave/io[1] \
	sim:/tester_qpi_write_single/qpislave/write_data \
	sim:/tester_qpi_write_single/qpislave/write_data_flag \
	sim:/tester_qpi_write_single/qpislave/command \
	sim:/tester_qpi_write_single/qpislave/address \
	sim:/tester_qpi_write_single/qpislave/data \
	sim:/tester_qpi_write_single/qpislave/state \
	sim:/tester_qpi_write_single/qpislave/first_data_byte \
    sim:/tester_qpi_write_single/qpislave/counter

run 10000ns
