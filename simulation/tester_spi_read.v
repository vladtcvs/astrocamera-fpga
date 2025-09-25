
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

module expect_module(input wire clk, input wire valid, input wire enable, output wire expect);
    reg prev_valid = 1'b0;
    reg exp = 1'b0;

    assign expect = exp;
    always @ (posedge clk) begin
        if (!enable) begin
            exp <= 1'b0;
        end else begin
            if (!prev_valid && valid) begin
                exp <= 1'b1;
            end
        end
        prev_valid <= valid;
    end
endmodule

`timescale 1ns/1ns
module tester_spi_read();

reg sck;
reg mosi;
wire miso;
reg cs;

reg clk;

wire [7:0] addr;
wire [7:0] write_data;
reg [7:0] read_data = 8'h00;
wire addr_valid;
wire write_data_valid;
wire read_data_request;
wire read_data_captured;

reg expect_write = 1'b0;
reg expect_addr = 1'b0;

reg insert_dummy = 1'b1;
wire expect_read;

expect_module _expect_read(.clk(clk), .valid(addr_valid), .enable(enable_expect_read), .expect(expect_read));

spi_memory_slave#(1, 8) spislave(.main_clock(clk),
                              .sck(sck),
                              .cs(cs),
                              .si(mosi),
                              .so(miso),
                              .addr(addr),
                              .addr_valid(addr_valid),
                              .write_data(write_data),
                              .write_data_valid(write_data_valid),
                              .read_data(read_data),
                              .read_data_request(read_data_request),
                              .read_data_captured(read_data_captured),
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

// sending write command 8'h03 = 8'b00000011
expect_addr = 1'b1;

`MOSI(0)
`MOSI(0)
`MOSI(0)
`MOSI(0)

`MOSI(0)
`MOSI(0)
`MOSI(1)
`MOSI(1)

// sending address = 8'hAB = 8'b10101011

`MOSI(1)
expect_addr = 1'b0;
`MOSI(0)
`MOSI(1)
`MOSI(0)

`MOSI(1)
`MOSI(0)
`MOSI(1)
read_data = 8'hAB;
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

read_data = 8'h53;
// reading data at 8'hAB

`MOSI(0)
`MOSI(0)
`MOSI(0)
`MOSI(0)

`MOSI(0)
`MOSI(0)
`MOSI(0)
`MOSI(0)

// reading data at 8'h53

`MOSI(0)
`MOSI(0)
`MOSI(0)
`MOSI(0)

`MOSI(0)
`MOSI(0)
`MOSI(0)
`MOSI(0)

// finish SPI transaction
cs = 1'b1;
for (i = 0; i < 10; i=i+1) begin
    clk = ~clk;
    #10;
end


$stop;
end

endmodule
