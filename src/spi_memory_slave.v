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

                            expect_addr,
                            expect_write,
                            expect_read,
                            insert_dummy_cycles,

                            cmd,
                            cmd_valid,

                            addr,
                            addr_valid,

                            write_data,
                            write_data_valid,

                            read_data,
                            read_data_request,
                            read_data_captured,

                            operation_in_progress
);

    parameter ADDR_BYTES = 3;
    parameter DUMMY_CYCLES = 8;

    // main clock
    input  wire main_clock;

    // External interface
    input  wire sck;
    input  wire cs;
    input  wire si;
    output  wire so;

    // Internal interface
    output reg [7:0] cmd = 8'h00;
    output reg cmd_valid = 1'b0;

    input wire expect_addr;
    input wire expect_write;
    input wire expect_read;
    input wire insert_dummy_cycles;

    output reg [ADDR_BYTES*8-1:0] addr;
    output reg addr_valid = 1'b0;

    output wire [7:0] write_data;
    output reg        write_data_valid = 0;
    
    input wire [7:0]  read_data;
    output reg        read_data_request = 0;
    output reg        read_data_captured = 0;

    output wire operation_in_progress;

    // state
    reg [7:0]  data = 0;
    reg [7:0]  counter = 0;

    localparam WRITE_CMD=4'h0, COMPLETED_ITEM=4'h1, WRITE_ADDR=4'h2, WRITE_DATA=4'h3, READ_DATA=4'h4, DUMMY=4'h5, ERROR=4'he, IDLE=4'hf;
    reg [3:0] state = WRITE_CMD;

    assign write_data = data;

    assign so = (cs == 0) ? ((state == READ_DATA || state == COMPLETED_ITEM) ? data[7] : 1'b1) : 1'bz;
    assign operation_in_progress = !cs;


    reg dummy_ready;

    reg prev_cs = 1'b1;
    reg prev_sck = 1'b0;

    always @ (posedge main_clock) begin
        if (cs) begin
            state <= IDLE;
            counter <= 0;
            cmd <= 0;
            cmd_valid <= 0;
            data <= 0;

            addr <= 'h0;
            addr_valid <= 1'b0;
            write_data_valid <= 1'b0;
            read_data_request <= 1'b0;
            read_data_captured <= 1'b0;

            dummy_ready <= 1'b0;
            addr_valid <= 1'b0;
        end else if (!cs) begin
            if (prev_cs) begin
                state <= WRITE_CMD;
                counter <= 0;

                cmd <= 0;
                cmd_valid <= 0;

                data <= 0;
                write_data_valid <= 0;
                read_data_request <= 0;
                read_data_captured <= 1'b0;

                dummy_ready <= 1'b0;

                addr <= 0;
                addr_valid <= 0;

            end else if ((!sck) && prev_sck) begin
                case (state)
                    WRITE_CMD : begin
                    end

                    WRITE_ADDR : begin
                    end

                    WRITE_DATA : begin
                    end

                    DUMMY : begin
                        read_data_request <= 1'b0;
                    end

                    READ_DATA : begin
                        read_data_request <= 1'b0;
                        data    <= {data[6:0], 1'b0};
                    end

                    COMPLETED_ITEM : begin
                        if (expect_read) begin
                            if (insert_dummy_cycles && !dummy_ready) begin
                                counter <= 'd0;
                                state <= DUMMY;
                                read_data_request <= 1'b0;
                            end else begin
                                counter <= 'd0;
                                state <= READ_DATA;
                                data <= read_data;
                                read_data_request <= 1'b0;
                                read_data_captured <= 1'b1;
                            end
                        end
                    end
                endcase
            end else if (sck && (!prev_sck)) begin
                read_data_captured <= 1'b0;
                case (state)
                    WRITE_CMD : begin
                        if (counter == 'd7) begin
                            cmd_valid <= 1'b1;
                            counter <= 0;
                            state <= COMPLETED_ITEM;
                        end else begin
                            counter <= counter + 1'd1;
                        end
                        cmd <= {cmd[6:0], si};
                    end

                    WRITE_ADDR : begin
                        if (counter == ADDR_BYTES * 8 - 1) begin
                            addr_valid <= 1'b1;
                            counter <= 0;
                            state <= COMPLETED_ITEM;
                        end else begin
                            counter <= counter + 1'd1;
                        end
                        addr <= {addr[(ADDR_BYTES*8-2):0], si};
                    end

                    WRITE_DATA : begin
                        if (counter == 'd7) begin
                            write_data_valid <= 1'b1;
                            counter <= 0;
                            state <= COMPLETED_ITEM;
                        end else begin
                            counter <= counter + 5'd1;
                        end
                        data    <= {data[6:0], si};
                    end

                    DUMMY : begin
                        if (counter == 0 && expect_read) begin
                            read_data_request <= 1'b1;
                        end
                        if (counter == DUMMY_CYCLES - 1) begin
                            counter <= 0;
                            state <= COMPLETED_ITEM;
                            dummy_ready <= 1'b1;
                        end else begin
                            counter <= counter + 5'd1;
                        end
                    end

                    READ_DATA : begin
                        if (counter == 'd0) begin
                            read_data_request <= 1'b1;
                            counter <= 'd1;
                        end else if (counter =='d7) begin
                            counter <= 0;
                            state <= COMPLETED_ITEM;
                        end else begin
                            counter <= counter + 1'd1;
                        end
                    end

                    COMPLETED_ITEM : begin
                        if (expect_write) begin
                            write_data_valid <= 1'b0;
                            data[0] <= si;
                            counter <= 'd1;
                            state <= WRITE_DATA;
                        end else if (expect_read) begin
                            // ERROR! we shouldn't be here!
                            // We should already be in READ_DATA state
                            state <= ERROR;
                        end else if (expect_addr && !addr_valid) begin
                            addr_valid <= 1'b0;
                            addr[0] <= si;
                            state <= WRITE_ADDR;
                            counter <= 'd1;
                        end else begin
                            // We don't have next operation - IDLE
                            state <= IDLE;
                        end
                    end

                    ERROR : begin
                        state <= IDLE;
                    end
                endcase
            end
        end
        prev_cs  <= cs;
        prev_sck <= sck;
    end
endmodule
