`timescale 1ns/1ns
module tester;

	reg sck;
	reg mosi;
	wire miso;
	reg cs;
	
	reg clk;
		
	controller ctl(.clk(clk),
				   .ctl_spi_sck(sck),
				   .ctl_spi_cs(cs),
				   .ctl_spi_si(mosi),
				   .ctl_spi_so(miso));

	initial // Clock generator
		begin
			clk = 0;
			forever #10 clk = !clk;
		end

	initial // Test stimulus
	begin
	end


endmodule
