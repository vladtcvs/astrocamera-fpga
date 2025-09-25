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


module calculate_received_bytes(clk, can_start, captured, trigger);

input wire clk;
input wire can_start;
input wire captured;
output wire trigger;

reg [3:0] counter = 0;
reg prev;

assign trigger = (counter < 3) && can_start;

always @ (posedge clk)
begin
    if (!prev && captured)
        counter <= counter + 1;

    prev <= captured;
end

endmodule


`timescale 1ns/1ns
module tester_spi_master_read();

reg clk;
reg miso;
wire mosi;
wire sck;
wire cs;

reg [7:0] opcode;
reg [7:0] addr;
reg [7:0] data_write;
wire [7:0] data_read;

reg opcode_addr_trigger = 1'b0;
reg data_trigger = 1'b0;
reg finalize_trigger = 1'b0;

reg addr_flag;
wire opcode_addr_completed;

wire data_ready;
wire data_completed;

calculate_received_bytes ___(clk, read_flag, read_data_flag_captured, data_read_flag);

spi_memory_master#(1,1) spimaster(.main_clock(clk),
                                .sck(sck),
                                .cs(cs),
                                .mosi(mosi),
                                .miso(miso),

                                .opcode(opcode),
                                .addr(addr),
                                .dummy_cycles(8'd0),
                                .write_data(data_write),
                                .read_data(data_read),

                                .opcode_addr_trigger(opcode_addr_trigger),
                                .addr_flag(addr_flag),
                                .opcode_addr_completed(opcode_addr_completed),

                                .data_trigger(data_trigger),
                                .data_ready(data_ready),
                                .data_completed(data_completed),

                                .finalize_trigger(finalize_trigger),

                                .busy(busy));


initial begin

clk = 1'b0;
miso = 1'b1;
addr = 8'hAB;
data_write = 8'hC4;
addr_flag = 1'b0;
opcode = 8'h0;

`WAIT2
opcode = 8'h9F;
opcode_addr_trigger = 1;
`WAIT2
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
data_trigger = 1;
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
`WAIT16
finalize_trigger = 1;
`WAIT16
$stop;
end

endmodule

