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

`define DOUBLE(bit1, bit0)              \
    begin                               \
wr[0] = bit0;                           \
wr[1] = bit1;                           \
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
module tester_qpi_write_double();

reg sck;
reg  [3:0] iowrite;
wire [3:0] io;

reg mosi;
reg[1:0] wr;

reg double_mode = 0;

wire miso = io[1];
assign io[0] = double_mode ? wr[0] : mosi;
assign io[1] = double_mode ? wr[1] : 1'bz;
assign io[2] = 1'b0;
assign io[3] = 1'b0;


reg cs;
reg clk;

wire [7:0] addr;
wire [7:0] write_data;
wire [7:0] read_data = 8'hAB;
wire write_data_flag;
wire read_data_flag;

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

// sending write command 8'h3A = 8'b00111010

`MOSI(0)
`MOSI(0)
`MOSI(1)
`MOSI(1)

`MOSI(1)
`MOSI(0)
`MOSI(1)
`MOSI(0)

// sending address = 8'hAB = 8'b10101011

`MOSI(1)
`MOSI(0)
`MOSI(1)
`MOSI(0)

`MOSI(1)
`MOSI(0)
`MOSI(1)
`MOSI(1)

// sending data = 8'hCD = 8'b11001101

double_mode = 1'b1;

`DOUBLE(1, 1)
`DOUBLE(0, 0)

`DOUBLE(1, 1)
`DOUBLE(0, 1)

// sending data = 8'h53 = 8'b01010011

`DOUBLE(0, 1)
`DOUBLE(0, 1)

`DOUBLE(0, 0)
`DOUBLE(1, 1)

// finish SPI transaction
cs = 1'b1;
for (i = 0; i < 10; i=i+1) begin
    clk = ~clk;
    #10;
end


$stop;
end

endmodule
