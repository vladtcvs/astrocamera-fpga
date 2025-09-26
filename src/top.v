module top(clk,
           ctl_spi_sck, ctl_spi_cs, ctl_spi_si, ctl_spi_so,
           mem_qpi_sck, mem_qpi_cs, mem_qpi_io,
           flash_sck, flash_cs, flash_mosi, flash_miso, flash_we,
           sram_qpi_sck, sram_qpi_io, sram_qpi_cs,

           ccd_adc,
           ccd_horizontal_phases,
           ccd_vertical_phases,
           ccd_rg,
           ccd_vsub,
           ccd_xsub,
           ccd_cds_1,
           ccd_cds_2,
           ccd_adc_sample,

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

output wire sram_qpi_sck;
inout wire[3:0] sram_qpi_io;
output wire [3:0] sram_qpi_cs;

input wire [11:0] ccd_adc;
output wire [3:0] ccd_horizontal_phases;
output wire [9:0] ccd_vertical_phases;
output wire ccd_rg;
output wire ccd_vsub;
output wire ccd_xsub;
output wire ccd_cds_1;
output wire ccd_cds_2;
output wire ccd_adc_sample;

input wire clk;
output wire [3:0] leds;

wire [7:0] status;
assign leds = ~status[3:0];

wire [7:0] _ccd_horizontal_phases;
wire [15:0] _ccd_vertical_phases;
assign ccd_horizontal_phases = _ccd_horizontal_phases[3:0];
assign ccd_vertical_phases = _ccd_vertical_phases[9:0];

assign flash_we = 1'b1;

wire clkop;
wire lock;

pll ___pll(.CLK(clk), .CLKOP(clkop), .LOCK(lock));

wire ctl_cs;
wire ctl_sck;
wire mem_cs;
wire mem_sck;
slow_edge_refine#(4) ctl_sck_refine(.clk(clkop), .in(ctl_spi_sck), .out(ctl_sck));
slow_edge_refine#(4) ctl_cs_refine(.clk(clkop), .in(ctl_spi_cs), .out(ctl_cs));
slow_edge_refine#(3) mem_sck_refine(.clk(clkop), .in(mem_qpi_sck), .out(mem_sck));
slow_edge_refine#(3) mem_cs_refine(.clk(clkop), .in(mem_qpi_cs), .out(mem_cs));

controller#(2) ctl( .clk(clkop),
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

                .sram_qpi_sck(sram_qpi_sck),
                .sram_qpi_io(sram_qpi_io),
                .sram_qpi_cs(sram_qpi_cs),

                .ccd_adc(ccd_adc),
                .ccd_horizontal_phases(_ccd_horizontal_phases),
                .ccd_vertical_phases(_ccd_vertical_phases),
                .ccd_rg(ccd_rg),
                .ccd_vsub(ccd_vsub),
                .ccd_xsub(ccd_xsub),
                .ccd_cds_1(ccd_cds_1),
                .ccd_cds_2(ccd_cds_2),
                .ccd_adc_sample(ccd_adc_sample),

                .status(status));

endmodule
