module top(input osc_in,
           input  wire ctl_spi_sck,
			input  wire ctl_spi_cs,
			input  wire ctl_spi_si,
			output wire ctl_spi_so
);
	wire pll_lock;
	wire clkop;
	pll main_pll(.CLK(osc_in), .CLKOP(clkop), .LOCK(pll_lock));
	
	controller ctl(.clk(clkop),
				   .ctl_spi_sck(ctl_spi_sck),
				   .ctl_spi_cs(ctl_spi_cs),
				   .ctl_spi_si(ctl_spi_si),
				   .ctl_spi_so(ctl_spi_so));
endmodule
