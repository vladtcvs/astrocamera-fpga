/*
 * CPOL = 0
 * CPHA = 0
 * MOSI data is sampled by slave (this) on rising edge of SCK
 * MISO data is sampled by master on rising edge of SCK and shifted of falling
 *
 * main_clock      - fpga clock
 * sck, cs, si, so - SPI pins
 * addr            - requested address
 * write_data      - register with data to write
 * write_data_flag - goes LOW->HIGH when data should be written
 * read_data       - input for data to read
 * read_data_flag  - goes LOW->HIGH when request for data read issued
 *
 * ADDR_BYTES        - length of address register in bytes
 * READ_DUMMY_CYCLES - amount of dummy bit read before transmitting first read byte.
 *
 * When read_data_flag goes HIGH, memory should set value in read_data input before READ_DUMMY_CYCLES expires.
 *
 * NOTICE: module assumes that SCK and CS signals doesn't have noise and have clear edges.
 *         You possibly may need to "refine" them from noise if you have slow edges or smth else.
 */

module spi_memory_slave (   main_clock,
                            sck, cs, si, so,
                            
                            write_data_prepare,
                            read_data_prepare,

                            addr, 
                            addr_valid,
                            write_data,
                            write_data_flag,
                            read_data,
                            read_data_flag,
                            operation_in_progress
);

    parameter ADDR_BYTES = 3;
    parameter READ_DUMMY_CYCLES = 8;

    parameter READ_CMD_OPCODE = 8'h03;
    parameter WRITE_CMD_OPCODE = 8'h02;

    // main clock
    input  wire main_clock;

    // External interface
    input  wire sck;
    input  wire cs;
    input  wire si;
    output  wire so;

    // Internal interface

    output reg read_data_prepare;
    output reg write_data_prepare;
    output reg addr_valid;
    output wire [ADDR_BYTES*8-1:0] addr;
    
    output wire [7:0] write_data;
    output reg        write_data_flag = 0;

    input wire [7:0]  read_data;
    output reg        read_data_flag = 0;

    output wire operation_in_progress;

    // state
    reg [7:0]  command = 0;
    reg [ADDR_BYTES*8-1:0] address = 0;
    reg [7:0]  data = 0;
    reg [7:0]  counter = 0;

	localparam WRITE_CMD=4'h0, WRITE_ADDR=4'h1, WRITE_DATA=4'h2, READ_DATA=4'h3, PRE_READ_DUMMY=4'h4, READ_DUMMY=4'h5, IDLE=4'hf;
	reg [3:0] state = WRITE_CMD;

	assign addr = address;	
	assign write_data = data;

    assign so = (cs == 0) ? ((state == READ_DATA) ? data[7] : 1'b1) : 1'bz;
    assign operation_in_progress = !cs;


    reg first_data_byte;

    reg prev_cs = 1'b1;
    reg prev_sck = 1'b0;
    reg addr_completed = 1'b0;

    always @ (posedge main_clock) begin
        if (cs) begin
            state <= WRITE_CMD;
            first_data_byte <= 1'b0;
            counter <= 0;
            command <= 0;
            data <= 0;
            address <= 0;
            addr_valid <= 1'b0;
            write_data_flag <= 1'b0;
            read_data_flag <= 1'b0;
            read_data_prepare <= 1'b0;
            write_data_prepare <= 1'b0;
            addr_valid <= 1'b0;
            addr_completed <= 1'b0;
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
                if (addr_completed) begin
                    addr_valid <= 1'b1; 
                    addr_completed <= 1'b0;
                end
                case (state)
                    WRITE_DATA : begin
                        if (counter == 8) begin
                            write_data_flag <= 1'b1;
                            counter <= 0;
                            first_data_byte <= 1'b0;
                        end
                    end

                    PRE_READ_DUMMY : begin
                        counter <= 0;
                        if (READ_DUMMY_CYCLES != 0) begin
                            state <= READ_DUMMY;
                        end else begin
                            state <= READ_DATA;
                            data <= read_data;
                        end
                    end

                    READ_DUMMY : begin
                        if (counter == READ_DUMMY_CYCLES) begin
                            data <= read_data;
                            state <= READ_DATA;
                            counter <= 0;
                        end else if (counter == 1) begin
                            read_data_flag <= 1'b1;
                        end
                    end

                    READ_DATA : begin
                        if (counter == 1) begin
                            read_data_flag <= 1'b1;
                        end

                        if (counter == 5'd8) begin
                            data <= read_data;
                            counter <= 0;
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
                                    WRITE_CMD_OPCODE : begin	// Write
                                        state <= WRITE_ADDR;
                                        write_data_prepare <= 1'b1;
                                    end
                                    READ_CMD_OPCODE : begin	// Read
                                        state <= WRITE_ADDR;
                                        read_data_prepare <= 1'b1;
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
                                addr_completed <= 1'b1;
                                case (command)
                                    WRITE_CMD_OPCODE : begin	// Write
                                        state <= WRITE_DATA;
                                    end
                                    READ_CMD_OPCODE : begin	// Read
                                        state <= PRE_READ_DUMMY;
                                    end
                                endcase
                                counter <= 0;
                            end
                            default : begin
                                counter <= counter + 5'd1;
                            end
                        endcase
                        address <= {address[(ADDR_BYTES*8-2):0], si};
                    end

                    WRITE_DATA : begin
                        if (counter == 0)
                            write_data_flag <= 1'b0;
                        counter <= counter + 5'd1;
                        data    <= {data[6:0], si};
                    end

                    READ_DUMMY : begin
                        read_data_flag <= 1'b0;
                        counter <= counter + 5'd1;
                    end

                    READ_DATA : begin
                        read_data_flag <= 1'b0;
                        counter <= counter + 5'd1;
                    end
                endcase
            end
        end
        prev_cs  <= cs;
        prev_sck <= sck;
    end
endmodule
