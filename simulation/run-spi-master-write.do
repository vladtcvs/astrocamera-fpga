vlib work
vlog ../src/spi_memory_master.v tester_spi_master_write.v
vsim -voptargs=+acc work.tester_spi_master_write
add wave  \
	sim:/tester_spi_master_write/spimaster/main_clock \
	sim:/tester_spi_master_write/spimaster/sck \
	sim:/tester_spi_master_write/spimaster/cs \
	sim:/tester_spi_master_write/spimaster/mosi \
	sim:/tester_spi_master_write/spimaster/miso \
        sim:/tester_spi_master_write/spimaster/finalize_trigger \
	sim:/tester_spi_master_write/spimaster/opcode_addr_trigger \
	sim:/tester_spi_master_write/spimaster/opcode_addr_completed \
	sim:/tester_spi_master_write/spimaster/data_trigger \
	sim:/tester_spi_master_write/spimaster/data_ready \
	sim:/tester_spi_master_write/spimaster/data_completed \
	sim:/tester_spi_master_write/spimaster/write_shift \
	sim:/tester_spi_master_write/spimaster/state

run 10000ns
