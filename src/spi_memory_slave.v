/*
 * CPOL = 0
 * CPHA = 0
 * MOSI data is sampled by slave (this) on rising edge of SCK
 * MISO data is sampled by master on rising edge of SCK and shifted of falling
 */

module spi_memory_slave (
    main_clock,
    sck, cs, si, so,
    addr,
    write_data,
    write_data_flag,
    read_data,
    read_data_flag
);

    parameter ADDR_BYTES = 3;

    // main clock
    input  wire main_clock;

    // Port declarations
    input  wire sck;
    input  wire cs;
    input  wire si;
    output  wire so;

    output wire [ADDR_BYTES*8-1:0] addr;
    
    output wire [7:0] write_data;
    output reg        write_data_flag = 0;

    input wire [7:0]  read_data;
    output reg        read_data_flag = 0;

	reg [7:0]  command = 0;
	reg [ADDR_BYTES*8-1:0] address = 0;
	reg [7:0]  data = 0;
	reg [4:0]  counter = 0;

	parameter WRITE_CMD='d0, WRITE_ADDR='d1, WRITE_DATA='d2, READ_DATA=3'd3, READ_DUMMY='d4, IDLE='d5;
	reg [2:0] state = WRITE_CMD;

	assign addr = address;	
	assign write_data = data;

	assign so = (cs == 0) ? data[7] : 1'bz;

    reg first_data_byte;

    reg prev_cs = 1'b1;
    reg prev_sck = 1'b0;

    always @ (posedge main_clock) begin
        if (cs) begin
            state <= WRITE_CMD;
            first_data_byte <= 1'b0;
            counter <= 0;
            command <= 0;
            data <= 0;
            address <= 0;
            write_data_flag <= 1'b0;
            read_data_flag <= 1'b0;
        end else if (!cs) begin
            if (prev_cs) begin
                state <= WRITE_CMD;
                first_data_byte <= 1'b1;
                counter <= 0;
                command <= 0;
                data <= 0;
                address <= 0;
                write_data_flag <= 1'b0;
                read_data_flag <= 1'b0;
            end else if ((!sck) && prev_sck) begin
                case (state)
                    WRITE_DATA : begin
                        if (counter == 8) begin
                            write_data_flag <= 1'b1;
                            counter <= 0;
                            first_data_byte <= 1'b0;
                        end else if (counter == 4) begin
                            write_data_flag <= 1'b0;
                        end
                    end

                    READ_DUMMY, READ_DATA : begin
                        if (counter == 8) begin
                            data <= read_data;
                            read_data_flag <= 1'b0;
                            state <= READ_DATA;
                            counter <= 0;
                        end else if (counter == 2) begin
                            read_data_flag <= 1'b1;
                            data    <= {data[6:0], 1'b0};
                        end else begin
                            data    <= {data[6:0], 1'b0};
                        end
                    end
                endcase
            end else if (sck && (!prev_sck)) begin
                case (state)
                    WRITE_CMD : begin
                        case (counter)
                            7 : begin
                                case ({command[6:0], si})
                                    8'h02 : begin	// Write
                                        state <= WRITE_ADDR;
                                    end
                                    8'h03 : begin	// Read
                                        state <= WRITE_ADDR;
                                    end
                                endcase
                                counter <= 0;
                            end
                            default: begin
                                counter <= counter + 5'd1;
                            end
                        endcase
                        command <= {command[6:0], si};
                    end

                    WRITE_ADDR : begin
                        case (counter)
                            ADDR_BYTES * 8 - 1 : begin
                                case (command)
                                    8'h02 : begin	// Write
                                        state <= WRITE_DATA;
                                    end
                                    8'h03 : begin	// Read
                                        state <= READ_DUMMY;
                                    end
                                endcase
                                counter <= 0;
                            end
                            default : begin
                                counter <= counter + 5'd1;
                            end
                        endcase
                        address <= {address[(ADDR_BYTES*4-2):0], si};
                    end

                    WRITE_DATA : begin
                        if (counter == 0 && !first_data_byte)
                            address <= address + 1'b1;
                        counter <= counter + 5'd1;
                        data    <= {data[6:0], si};
                    end

                    READ_DUMMY : begin
                        counter <= counter + 5'd1;
                    end

                    READ_DATA : begin
                        if (counter == 0) begin
                            address <= address + 1'b1;
                        end
                        counter <= counter + 5'd1;
                    end
                endcase
            end
        end
        prev_cs  <= cs;
        prev_sck <= sck;
    end
endmodule
