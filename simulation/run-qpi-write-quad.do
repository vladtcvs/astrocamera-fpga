vlib work
vlog ../src/qpi_memory_slave.v tester_qpi_write_quad.v
vsim -voptargs=+acc work.tester_qpi_write_quad
add wave  \
	sim:/tester_qpi_write_quad/qpislave/main_clock \
	sim:/tester_qpi_write_quad/qpislave/sck \
	sim:/tester_qpi_write_quad/qpislave/cs \
	sim:/tester_qpi_write_quad/qpislave/io \
    sim:/tester_qpi_write_quad/qpislave/write_data \
	sim:/tester_qpi_write_quad/qpislave/write_data_flag \
	sim:/tester_qpi_write_quad/qpislave/command \
	sim:/tester_qpi_write_quad/qpislave/address \
	sim:/tester_qpi_write_quad/qpislave/data \
	sim:/tester_qpi_write_quad/qpislave/state \
	sim:/tester_qpi_write_quad/qpislave/first_data_byte \
    sim:/tester_qpi_write_quad/qpislave/counter

run 10000ns
