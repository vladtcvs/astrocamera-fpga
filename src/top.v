module top(clk,
           ctl_spi_sck, ctl_spi_cs, ctl_spi_si, ctl_spi_so,
		   mem_spi_sck, mem_spi_cs, mem_spi_si, mem_spi_so,
           flash_sck, flash_cs, flash_mosi, flash_miso, flash_we,
           leds);
input  wire ctl_spi_sck;
input  wire ctl_spi_cs;
input  wire ctl_spi_si;
output wire ctl_spi_so;

input  wire mem_spi_sck;
input  wire mem_spi_cs;
input  wire mem_spi_si;
output wire mem_spi_so;

output wire flash_sck;
output wire flash_cs;
output wire flash_mosi;
input  wire flash_miso;
output wire flash_we;

input wire clk;
output wire [7:0] leds;

wire [7:0] status;
assign leds = ~status;

assign flash_we = 1'b1;

wire ctl_cs;
wire ctl_sck;
wire mem_cs;
wire mem_sck;
slow_edge_refine ctl_sck_refine(.clk(clk), .in(ctl_spi_sck), .out(ctl_sck));
slow_edge_refine ctl_cs_refine(.clk(clk), .in(ctl_spi_cs), .out(ctl_cs));
slow_edge_refine mem_sck_refine(.clk(clk), .in(mem_spi_sck), .out(mem_sck));
slow_edge_refine mem_cs_refine(.clk(clk), .in(mem_spi_cs), .out(mem_cs));

controller ctl( .clk(clk),
                .ctl_spi_sck(ctl_sck),
                .ctl_spi_cs(ctl_cs),
                .ctl_spi_si(ctl_spi_si),
                .ctl_spi_so(ctl_spi_so),

                .mem_spi_sck(mem_sck),
                .mem_spi_cs(mem_cs),
                .mem_spi_si(mem_spi_si),
                .mem_spi_so(mem_spi_so),

                .flash_sck(flash_sck),
                .flash_cs(flash_cs),
                .flash_mosi(flash_mosi),
                .flash_miso(flash_miso),

                .status(status));

endmodule
