vlib work
vlog ../src/spi_memory_slave.v tester_spi_write.v
vsim -voptargs=+acc work.tester_spi_write
add wave  \
	sim:/tester_spi_write/spislave/main_clock \
	sim:/tester_spi_write/spislave/sck \
	sim:/tester_spi_write/spislave/cs \
	sim:/tester_spi_write/spislave/si \
	sim:/tester_spi_write/spislave/so \
	sim:/tester_spi_write/spislave/write_data \
	sim:/tester_spi_write/spislave/write_data_flag \
	sim:/tester_spi_write/spislave/command \
	sim:/tester_spi_write/spislave/address \
	sim:/tester_spi_write/spislave/data \
	sim:/tester_spi_write/spislave/state \
	sim:/tester_spi_write/spislave/first_data_byte

run 10000ns
