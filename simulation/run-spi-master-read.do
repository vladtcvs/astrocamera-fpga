vlib work
vlog ../src/spi_memory_master.v tester_spi_master_read.v
vsim -voptargs=+acc work.tester_spi_master_read
add wave  \
	sim:/tester_spi_master_read/spimaster/main_clock \
	sim:/tester_spi_master_read/spimaster/sck \
	sim:/tester_spi_master_read/spimaster/cs \
	sim:/tester_spi_master_read/spimaster/mosi \
	sim:/tester_spi_master_read/spimaster/miso \
	sim:/tester_spi_master_read/spimaster/trigger \
	sim:/tester_spi_master_read/spimaster/state \
        sim:/tester_spi_master_read/spimaster/read_data_flag \
        sim:/tester_spi_master_read/spimaster/read_data \
        sim:/tester_spi_master_read/spimaster/read_in_progress \
        sim:/tester_spi_master_read/spimaster/read_data_ready \
        sim:/tester_spi_master_read/spimaster/read_data_flag_captured

run 10000ns
