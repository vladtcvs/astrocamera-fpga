module controller(input clk,
				   input  wire ctl_spi_sck,
				   input  wire ctl_spi_cs,
				   input  wire ctl_spi_si,
				   output wire ctl_spi_so);

	wire [7:0] addr;
    
    reg [7:0] data0 = 8'h12;
    reg [7:0] data1 = 8'hAB;
    reg [7:0] read_data;
    wire read_data_flag;

    wire [7:0] write_data;
    wire write_data_flag;

    spi_memory_slave#(1) spislave(.main_clock(clk),
                                  .sck(ctl_spi_sck),
                                  .cs(ctl_spi_cs),
                                  .si(ctl_spi_si),
                                  .so(ctl_spi_so),
                                  .addr(addr),
                                  .write_data(write_data),
                                  .write_data_flag(write_data_flag),
                                  .read_data(read_data),
                                  .read_data_flag(read_data_flag));

    reg prev_read_data_flag;
    reg prev_write_data_flag;
    always @ (posedge clk) begin
        if (!prev_read_data_flag && read_data_flag) begin
            if (addr[0] == 1'b0)
                read_data <= data0;
            else
                read_data <= data1;
        end

        if (!prev_write_data_flag && write_data_flag) begin
            if (addr[0] == 1'b0)
                data0 <= write_data;
            else
                data1 <= write_data;
        end

        prev_read_data_flag  <= read_data_flag;
        prev_write_data_flag <= write_data_flag;
    end

endmodule