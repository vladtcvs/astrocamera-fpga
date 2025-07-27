
`define MOSI(value)                     \
    begin                               \
mosi = value;                           \
for (i = 0; i < 5; i=i+1) begin         \
    clk = ~clk;                         \
    #10;                                \
end                                     \
sck = 1;                                \
for (i = 0; i < 10; i=i+1) begin        \
    clk = ~clk;                         \
    #10;                                \
end                                     \
sck = 0;                                \
for (i = 0; i < 5; i=i+1) begin         \
    clk = ~clk;                         \
    #10;                                \
end                                     \
    end

`define QUAD                            \
    begin                               \
for (i = 0; i < 5; i=i+1) begin         \
    clk = ~clk;                         \
    #10;                                \
end                                     \
sck = 1;                                \
for (i = 0; i < 10; i=i+1) begin        \
    clk = ~clk;                         \
    #10;                                \
end                                     \
sck = 0;                                \
for (i = 0; i < 5; i=i+1) begin         \
    clk = ~clk;                         \
    #10;                                \
end                                     \
    end

`timescale 1ns/1ns
module tester_qpi_read_quad();

reg sck;
reg mosi;
wire [3:0] io;
reg cs;

reg clk;

wire [7:0] addr;
wire [7:0] write_data;
wire [7:0] read_data = 8'hAB;
wire write_data_flag;
wire read_data_flag;

reg quad_mode = 0;

assign io[0] = quad_mode ? 1'bz : mosi;
assign io[1] = 1'bz;
assign io[2] = 1'bz;
assign io[3] = 1'bz;

qpi_memory_slave#(1) qpislave(.main_clock(clk),
                              .sck(sck),
                              .cs(cs),
                              .io(io),
                              .addr(addr),
                              .write_data(write_data),
                              .write_data_flag(write_data_flag),
                              .read_data(read_data),
                              .read_data_flag(read_data_flag));

integer i;

initial begin
clk = 1'b0;
sck = 1'b0;
mosi = 1'b0;
cs = 1'b1;
#10
for (i = 0; i < 10; i=i+1) begin
    clk = ~clk;
    #10;
end

cs = 1'b0;
for (i = 0; i < 10; i=i+1) begin
    clk = ~clk;
    #10;
end

// sending quad read command 8'hEB = 8'b11101011

`MOSI(1)
`MOSI(1)
`MOSI(1)
`MOSI(0)

`MOSI(1)
`MOSI(0)
`MOSI(1)
`MOSI(1)

// sending address = 8'hAB = 8'b10101011

`MOSI(1)
`MOSI(0)
`MOSI(1)
`MOSI(0)

`MOSI(1)
`MOSI(0)
`MOSI(1)
`MOSI(1)

// Sending 8 dummy cycles

`MOSI(0)
`MOSI(0)
`MOSI(0)
`MOSI(0)

`MOSI(0)
`MOSI(0)
`MOSI(0)
`MOSI(0)

quad_mode = 1'b1;
// reading data at 8'hAB

`QUAD
`QUAD

// reading data at 8'hAC

`QUAD
`QUAD

// finish SPI transaction
cs = 1'b1;
for (i = 0; i < 10; i=i+1) begin
    clk = ~clk;
    #10;
end


$stop;
end

endmodule
