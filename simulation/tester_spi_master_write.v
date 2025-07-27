`define WAIT2                 \
begin				\
#10				\
clk = ~clk;			\
#10				\
clk = ~clk;			\
end

`define WAIT4                 \
begin				\
`WAIT2				\
`WAIT2				\
end

`define WAIT8                 \
begin				\
`WAIT4				\
`WAIT4				\
end

`define WAIT16                 \
begin				\
`WAIT8				\
`WAIT8				\
end


`timescale 1ns/1ns
module calculate_sent_bytes(clk, can_start, captured, trigger);

input wire clk;
input wire can_start;
input wire captured;
output wire trigger;

reg [3:0] counter = 0;
reg prev;

assign trigger = (counter < 2) && can_start;

always @ (posedge clk)
begin
    if (!prev && captured)
        counter <= counter + 1;

    prev <= captured;
end

endmodule

module tester_spi_master_write();

reg clk;
reg miso;
wire mosi;
wire sck;
wire cs;

reg [7:0] addr;
reg [7:0] data_write;

wire [7:0] data_read;

reg opcode_addr_trigger = 1'b0;
wire opcode_addr_completed;

reg data_trigger = 1'b0;
wire data_ready;
wire data_complete;

reg finalize_trigger = 1'b0;

calculate_sent_bytes ___(clk, write_flag, data_write_captured, data_write_flag);

spi_memory_master#(1) spimaster(.main_clock(clk),
                                .sck(sck),
                                .cs(cs),
                                .mosi(mosi),
                                .miso(miso),

                                .opcode(8'h02),
                                .addr(addr),
                                .dummy_cycles(4'd0),
                                .write_data(data_write),
                                .read_data(data_read),

                                .opcode_addr_trigger(opcode_addr_trigger),
                                .addr_flag(1'b1),
                                .opcode_addr_completed(opcode_addr_completed),

                                .data_trigger(data_trigger),
                                .data_ready(data_ready),
                                .data_completed(data_completed),

                                .finalize_trigger(finalize_trigger),
                                .busy(busy));

initial begin

clk = 1'b0;
miso = 1'b0;

addr = 8'hAB;
data_write = 8'h12;

finalize_trigger = 1'b0;
opcode_addr_trigger = 1'b0;
data_trigger = 1'b0;

`WAIT16

opcode_addr_trigger = 1'b1;
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16

data_trigger = 1'b1;

`WAIT16
data_trigger = 1'b0;
`WAIT16
`WAIT16
finalize_trigger = 1'b1;
`WAIT4
finalize_trigger = 1'b0;
opcode_addr_trigger = 1'b0;
data_trigger = 1'b0;
`WAIT4

`WAIT16
opcode_addr_trigger = 1'b1;
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16

data_trigger = 1'b1;

`WAIT16
data_trigger = 1'b0;
`WAIT16
`WAIT16
finalize_trigger = 1'b1;
`WAIT4


$stop;
end

endmodule

