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
	sim:/tester_spi_read/spislave/read_data_flag \
	sim:/tester_spi_read/spislave/command \
	sim:/tester_spi_read/spislave/address \
	sim:/tester_spi_read/spislave/data \
	sim:/tester_spi_read/spislave/state \
    sim:/tester_spi_read/spislave/counter

run 10000ns
