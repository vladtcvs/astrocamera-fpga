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

`timescale 1ns/1ns
module tester_spi_write();

reg sck;
reg mosi;
wire miso;
reg cs;

reg clk;

wire [7:0] addr;
wire [7:0] write_data;
wire [7:0] read_data = 8'hAB;
wire write_data_valid;
wire read_data_request;

reg expect_addr;
reg expect_read;
reg expect_write;
reg insert_dummy;

spi_memory_slave#(1) spislave(.main_clock(clk),
                              .sck(sck),
                              .cs(cs),
                              .si(mosi),
                              .so(miso),
                              .addr(addr),
                              .write_data(write_data),
                              .write_data_valid(write_data_valid),
                              .read_data(read_data),
                              .read_data_request(read_data_request),
                              .expect_addr(expect_addr),
                              .expect_read(expect_read),
                              .expect_write(expect_write),
                              .insert_dummy_cycles(insert_dummy)
);

integer i;

initial begin
clk = 1'b0;
sck = 1'b0;
mosi = 1'b0;
cs = 1'b1;
expect_addr = 1'b0;
expect_read = 1'b0;
expect_write = 1'b0;
insert_dummy = 1'b0;
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

// sending write command 8'h02 = 8'b00000010

`MOSI(0)
`MOSI(0)
`MOSI(0)
`MOSI(0)

`MOSI(0)
`MOSI(0)
`MOSI(1)
`MOSI(0)

expect_addr <= 1'b1;
// sending address = 8'hAB = 8'b10101011

`MOSI(1)
expect_addr <= 1'b0;
`MOSI(0)
`MOSI(1)
`MOSI(0)

`MOSI(1)
`MOSI(0)
`MOSI(1)
`MOSI(1)

expect_write <= 1'b1;
// sending data = 8'hCD = 8'b11001101

`MOSI(1)
`MOSI(1)
`MOSI(0)
`MOSI(0)

`MOSI(1)
`MOSI(1)
`MOSI(0)
`MOSI(1)

// sending data = 8'h53 = 8'b01010011

`MOSI(0)
`MOSI(1)
`MOSI(0)
`MOSI(1)

`MOSI(0)
`MOSI(0)
`MOSI(1)
expect_write <= 1'b0;
`MOSI(1)

// finish SPI transaction
cs = 1'b1;
for (i = 0; i < 10; i=i+1) begin
    clk = ~clk;
    #10;
end


$stop;
end

endmodule
