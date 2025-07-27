vlib work
vlog ../src/qpi_memory_slave.v tester_qpi_read_quad.v
vsim -voptargs=+acc work.tester_qpi_read_quad
add wave  \
	sim:/tester_qpi_read_quad/qpislave/main_clock \
	sim:/tester_qpi_read_quad/qpislave/sck \
	sim:/tester_qpi_read_quad/qpislave/cs \
	sim:/tester_qpi_read_quad/qpislave/io \
	sim:/tester_qpi_read_quad/qpislave/read_data \
	sim:/tester_qpi_read_quad/qpislave/read_data_flag \
	sim:/tester_qpi_read_quad/qpislave/command \
	sim:/tester_qpi_read_quad/qpislave/address \
	sim:/tester_qpi_read_quad/qpislave/data \
	sim:/tester_qpi_read_quad/qpislave/state \
	sim:/tester_qpi_read_quad/qpislave/first_data_byte \
    sim:/tester_qpi_read_quad/qpislave/counter

run 10000ns
