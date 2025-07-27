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


reg [7:0] addr;
reg [7:0] data_write;
reg  read_flag = 1'b0;
wire data_write_captured;
wire read_data_flag_captured;

wire [7:0] data_read;
wire data_read_flag;
wire data_read_ready;
reg trigger = 1'b0;

calculate_received_bytes ___(clk, read_flag, read_data_flag_captured, data_read_flag);

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

                                .addr_flag(1'b1),
                                .write_data_flag(1'b0),
                                .read_data_flag(data_read_flag),

                                .trigger(trigger),
                                .write_data_captured(data_write_captured),
                                .read_data_ready(data_read_ready),
                                .read_data_flag_captured(read_data_flag_captured),

                                .busy(busy));


initial begin

clk = 1'b0;
miso = 1'b1;
addr = 8'hAB;

trigger = 1'b0;
read_flag = 1'b1;
`WAIT2
trigger = 1'b1;
`WAIT2
//data_read_trigger = 1'b0;
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

$stop;
end

endmodule

