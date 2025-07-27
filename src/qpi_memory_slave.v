/*
 * CPOL = 0
 * CPHA = 0
 * input data is sampled by slave (this) on rising edge of SCK
 * output data is sampled by master on rising edge of SCK and shifted of falling
 */

module qpi_memory_slave (   main_clock,
                            sck, cs, io,
                            addr,
                            write_data,
                            write_data_flag,
                            read_data,
                            read_data_flag
);

    parameter ADDR_BYTES = 3;
    parameter READ_DUMMY_CYCLES = 8;

    // main clock
    input  wire main_clock;

    // Port declarations
    input  wire sck;
    input  wire cs;
    inout  wire [3:0] io;

    output wire [ADDR_BYTES*8-1:0] addr;
    
    output wire [7:0] write_data;
    output reg        write_data_flag = 0;

    input wire [7:0]  read_data;
    output reg        read_data_flag = 0;

    reg [7:0]  command = 0;
    reg [ADDR_BYTES*8-1:0] address = 0;
    reg [7:0]  data = 0;
    reg [4:0]  counter = 0;

    parameter WRITE_CMD='d0, WRITE_ADDR='d1, WRITE_DATA='d2, READ_DATA=3'd3, READ_DUMMY='d4, IDLE='d5, ERR = 'd6;
    reg [2:0] state = WRITE_CMD;

    parameter SINGLE_MODE = 0, DOUBLE_MODE=1, QUAD_MODE=2;
    reg [1:0] iomode = SINGLE_MODE;

    parameter CMD_SINGLE_WRITE = 8'h02, CMD_SINGLE_READ = 8'h03,
              CMD_DOUBLE_READ = 8'h3B,  CMD_DOUBLE_WRITE = 8'h3A,
              CMD_QUAD_READ = 8'hEB,    CMD_QUAD_WRITE = 8'h38;

    reg iostate_output = 1'b0;

    assign addr = address;	
    assign write_data = data;

    reg first_data_byte;

    reg prev_cs = 1'b1;
    reg prev_sck = 1'b0;

    wire [3:0] outwire;
    wire [3:0] inwire = io;
    wire si = io[0];

    assign io = (!iostate_output) ? 4'bz : 
            (iomode == SINGLE_MODE) ? {1'bz, 1'bz, outwire[0], 1'bz} :
            (iomode == DOUBLE_MODE) ? {1'bz, 1'bz, outwire[1], outwire[0]} :
            (iomode == QUAD_MODE) ? {outwire[3], outwire[2], outwire[1], outwire[0]} :
            4'bz;

    assign outwire = (iomode == SINGLE_MODE) ? {1'bz, 1'bz, 1'bz, data[7]} :
                     (iomode == DOUBLE_MODE) ? {1'bz, 1'bz, data[7], data[6]} :
                     (iomode == QUAD_MODE) ? {data[7], data[6], data[5], data[4]} : 4'bz;

    wire [4:0] data_counter = (iomode == SINGLE_MODE) ? 5'd8 : (iomode == DOUBLE_MODE) ? 5'd4 : (iomode == QUAD_MODE) ? 5'd2 : 5'd8;

    always @ (posedge main_clock) begin
        if (cs) begin
            iomode <= SINGLE_MODE;
            state <= WRITE_CMD;
            iostate_output = 1'b0;
            first_data_byte <= 1'b0;
            counter <= 0;
            command <= 0;
            data <= 0;
            address <= 0;
            write_data_flag <= 1'b0;
            read_data_flag <= 1'b0;
        end else if (!cs) begin
            if (prev_cs) begin
                iomode <= SINGLE_MODE;
                state <= WRITE_CMD;
                iostate_output = 1'b0;
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
                        if (counter == data_counter) begin
                            write_data_flag <= 1'b1;
                            counter <= 0;
                            first_data_byte <= 1'b0;
                        end
                    end

                    READ_DUMMY : begin
                        if (counter == READ_DUMMY_CYCLES) begin
                            data <= read_data;
                            state <= READ_DATA;
                            iostate_output <= 1'b1;
                            counter <= 0;
                        end else if (counter == 1) begin
                            read_data_flag <= 1'b1;
                        end
                    end

                    READ_DATA : begin
                        if (counter == 1) begin
                            read_data_flag <= 1'b1;
                        end

                        if (counter == data_counter) begin
                            data <= read_data;
                            counter <= 0;
                        end else begin
                            case (iomode)
                                SINGLE_MODE :
                                    data    <= {data[6:0], 1'b0};
                                DOUBLE_MODE :
                                    data    <= {data[5:0], 1'b0, 1'b0};
                                QUAD_MODE :
                                    data    <= {data[3:0], 1'b0, 1'b0, 1'b0, 1'b0};
                            endcase 
                        end
                    end
                endcase
            end else if (sck && (!prev_sck)) begin
                case (state)
                    WRITE_CMD : begin
                        case (counter)
                            7 : begin
                                case ({command[6:0], si})
                                    CMD_SINGLE_READ, CMD_SINGLE_WRITE,
                                    CMD_DOUBLE_READ, CMD_DOUBLE_WRITE,
                                    CMD_QUAD_READ,   CMD_QUAD_WRITE :
                                        state <= WRITE_ADDR;
                                    default :
                                        state <= ERR;
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
                                    CMD_SINGLE_WRITE : begin	// Write
                                        state <= WRITE_DATA;
                                        iomode <= SINGLE_MODE;
                                    end
                                    CMD_SINGLE_READ : begin	// Read
                                        state <= READ_DUMMY;
                                        iomode <= SINGLE_MODE;
                                    end
                                    CMD_DOUBLE_WRITE : begin	// double Write
                                        state <= WRITE_DATA;
                                        iomode <= DOUBLE_MODE;
                                    end
                                    CMD_DOUBLE_READ : begin	// double Read
                                        state <= READ_DUMMY;
                                        iomode <= DOUBLE_MODE;
                                    end
                                    CMD_QUAD_WRITE : begin	// quad Write
                                        state <= WRITE_DATA;
                                        iomode <= QUAD_MODE;
                                    end
                                    CMD_QUAD_READ : begin	    // quad Read
                                        state <= READ_DUMMY;
                                        iomode <= QUAD_MODE;
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
                        if (counter == 0 && !first_data_byte)
                            address <= address + 1'b1;
                        if (counter == 0)
                            write_data_flag <= 1'b0;

                        counter <= counter + 5'd1;
                        case (iomode)
                            SINGLE_MODE :
                                data    <= {data[6:0], si};
                            DOUBLE_MODE :
                                data    <= {data[5:0], io[1], io[0]};
                            QUAD_MODE :
                                data    <= {data[3:0], io[3], io[2], io[1], io[0]};
                        endcase
                        
                    end

                    READ_DUMMY : begin
                        read_data_flag <= 1'b0;
                        counter <= counter + 5'd1;
                    end

                    READ_DATA : begin
                        read_data_flag <= 1'b0;
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
