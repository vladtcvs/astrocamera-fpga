vlib work
vlog ../src/spi_memory_slave.v tester_spi_read.v
vsim -voptargs=+acc work.tester_spi_read
add wave  \
	sim:/tester_spi_read/spislave/main_clock \
	sim:/tester_spi_read/spislave/sck \
	sim:/tester_spi_read/spislave/cs \
	sim:/tester_spi_read/spislave/si \
	sim:/tester_spi_read/spislave/so \
	sim:/tester_spi_read/spislave/read_data \
	sim:/tester_spi_read/spislave/read_data_request \
	sim:/tester_spi_read/spislave/read_data_captured \
	sim:/tester_spi_read/spislave/cmd \
	sim:/tester_spi_read/spislave/addr \
	sim:/tester_spi_read/addr_valid \
	sim:/tester_spi_read/spislave/data \
	sim:/tester_spi_read/spislave/state \
	sim:/tester_spi_read/spislave/counter \
	sim:/tester_spi_read/insert_dummy \
	sim:/tester_spi_read/expect_read

run 10000ns
