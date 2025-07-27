vlib work
vlog ../src/qpi_memory_slave.v tester_qpi_read_double.v
vsim -voptargs=+acc work.tester_qpi_read_double
add wave  \
	sim:/tester_qpi_read_double/qpislave/main_clock \
	sim:/tester_qpi_read_double/qpislave/sck \
	sim:/tester_qpi_read_double/qpislave/cs \
	sim:/tester_qpi_read_double/qpislave/io[0] \
    sim:/tester_qpi_read_double/qpislave/io[1] \
	sim:/tester_qpi_read_double/qpislave/read_data \
	sim:/tester_qpi_read_double/qpislave/read_data_flag \
	sim:/tester_qpi_read_double/qpislave/command \
	sim:/tester_qpi_read_double/qpislave/address \
	sim:/tester_qpi_read_double/qpislave/data \
	sim:/tester_qpi_read_double/qpislave/state \
	sim:/tester_qpi_read_double/qpislave/first_data_byte \
    sim:/tester_qpi_read_double/qpislave/counter

run 10000ns
