module top(clk,
           ctl_spi_sck, ctl_spi_cs, ctl_spi_si, ctl_spi_so,
		   mem_qpi_sck, mem_qpi_cs, mem_qpi_io,
           flash_sck, flash_cs, flash_mosi, flash_miso, flash_we,
           leds);
input  wire ctl_spi_sck;
input  wire ctl_spi_cs;
input  wire ctl_spi_si;
output wire ctl_spi_so;

input  wire mem_qpi_sck;
input  wire mem_qpi_cs;
inout  wire [3:0] mem_qpi_io;

output wire flash_sck;
output wire flash_cs;
output wire flash_mosi;
input  wire flash_miso;
output wire flash_we;

input wire clk;
output wire [3:0] leds;

wire [7:0] status;
assign leds = ~status[3:0];

assign flash_we = 1'b1;

wire ctl_cs;
wire ctl_sck;
wire mem_cs;
wire mem_sck;
slow_edge_refine ctl_sck_refine(.clk(clk), .in(ctl_spi_sck), .out(ctl_sck));
slow_edge_refine ctl_cs_refine(.clk(clk), .in(ctl_spi_cs), .out(ctl_cs));
slow_edge_refine mem_sck_refine(.clk(clk), .in(mem_qpi_sck), .out(mem_sck));
slow_edge_refine mem_cs_refine(.clk(clk), .in(mem_qpi_cs), .out(mem_cs));

controller ctl( .clk(clk),
                .ctl_spi_sck(ctl_sck),
                .ctl_spi_cs(ctl_cs),
                .ctl_spi_si(ctl_spi_si),
                .ctl_spi_so(ctl_spi_so),

                .mem_qpi_sck(mem_sck),
                .mem_qpi_cs(mem_cs),
                .mem_qpi_io(mem_qpi_io),

                .flash_sck(flash_sck),
                .flash_cs(flash_cs),
                .flash_mosi(flash_mosi),
                .flash_miso(flash_miso),

                .status(status));

endmodule
