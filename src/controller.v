module controller(  input clk,
                    input  wire ctl_spi_sck,
                    input  wire ctl_spi_cs,
                    input  wire ctl_spi_si,
                    output wire ctl_spi_so,

                    input  wire mem_qpi_sck,
                    input  wire mem_qpi_cs,
                    inout  wire [3:0] mem_qpi_io,

                    output wire flash_sck,
                    output wire flash_cs,
                    output wire flash_mosi,
                    input  wire flash_miso,

                    output  wire sram_qpi_sck,
                    inout  wire [3:0] sram_qpi_io,
                    output  wire [3:0] sram_qpi_cs,

                    output wire [7:0] status);
 
    parameter SPI_MASTER_SCALER_BITS = 10;
 
    /* Control interface wires */
    wire [7:0] ctl_cmd;
    wire ctl_cmd_valid;	

    wire [7:0] ctl_addr;
    wire ctl_addr_valid;

    wire [7:0] ctl_write_data;
    wire ctl_write_data_valid;

    wire [7:0] ctl_read_data;
    wire ctl_read_data_request;
    wire ctl_read_data_captured;

    reg ctl_expect_addr = 1'b0;
    reg ctl_expect_read = 1'b0;
    reg ctl_expect_write = 1'b0;
    reg ctl_insert_dummy_cycles = 1'b0;
    wire ctl_operation_progress;

    /* Memory interface wires */
    wire [7:0] mem_cmd;
    wire mem_cmd_valid;	

    wire [23:0] mem_addr;
    wire mem_addr_valid;

    wire [7:0] mem_write_data;
    wire mem_write_data_valid;

	reg [7:0] mem_read_data = 0;
    wire mem_read_data_request;
	wire mem_read_data_captured;

    reg mem_expect_addr = 1'b0;
    reg mem_expect_read = 1'b0;
    reg mem_expect_write = 1'b0;
    reg mem_insert_dummy_cycles = 1'b0;
    wire mem_operation_progress;

    reg mem_invalid_operation = 1'b0;

    ///////////////////// SRAM /////////////////////////////
    wire [7:0] sram_read;
    wire sram_opcode_addr_completed;
    wire sram_data_trigger_captured;
    wire sram_data_ready;
    wire sram_data_completed;
    wire sram_finalize_completed;

    wire sram_interface_busy;
    wire [3:0] sram_state;

    reg sram_access_not_ready = 1'b0;   
    ///////////////////// END SRAM /////////////////////////////

    ///////////////////// FLASH /////////////////////////////
    reg flash_wel = 1'b0;
    wire [7:0] flash_read;
    wire flash_opcode_addr_completed;
    wire flash_data_trigger_captured;
    wire flash_data_ready;
    wire flash_data_completed;
    wire flash_finalize_completed;

    wire flash_interface_busy;
    wire [3:0] flash_state;

    reg flash_access_not_ready = 1'b0;   
    ///////////////////// END FLASH /////////////////////////////

    ///////////////////// SRAM + FLASH /////////////////////
    reg map_to_flash = 1'b0;
    reg [7:0]  memory_opcode = 8'h00;
    reg [23:0] memory_addr = 24'h0;
    reg [7:0]  memory_write = 8'hFF;
    reg memory_addr_flag = 1'b0;
    reg memory_opcode_addr_trigger = 1'b0;
    reg memory_data_trigger = 1'b0;
    reg memory_finalize_trigger = 1'b0;

    reg memory_write_data_received = 1'b0;
    reg memory_transmitted = 1'b0;

    wire memory_opcode_addr_completed  = map_to_flash ? flash_opcode_addr_completed : sram_opcode_addr_completed;
    wire memory_data_trigger_captured  = map_to_flash ? flash_data_trigger_captured : sram_data_trigger_captured;
    wire memory_data_ready             = map_to_flash ? flash_data_ready : sram_data_ready;
    wire memory_data_completed         = map_to_flash ? flash_data_completed : sram_data_completed;
    wire memory_finalize_completed     = map_to_flash ? flash_finalize_completed : sram_finalize_completed;
	///////////////////// SRAM + FLASH /////////////////////

    

    /* Common control */
    wire [7:0] memory_status = {2'h3,
                                 map_to_flash,
                                 sram_interface_busy,
                                 flash_interface_busy,
                                 memory_opcode_addr_trigger,
                                 memory_data_trigger,
                                 memory_finalize_trigger
                               };
							
    wire [7:0] sram_status = {3'h7,
                               sram_opcode_addr_completed,
                               sram_data_trigger_captured,
                               sram_data_ready,
                               sram_data_completed,
                               sram_finalize_completed
							   };

    wire [7:0] flash_status = {2'h3,
                                flash_wel,
                                flash_opcode_addr_completed,
                                flash_data_trigger_captured,
                                flash_data_ready,
                                flash_data_completed,
                                flash_finalize_completed
							   };

    

    /* Control SPI interface */
    spi_memory_slave#(1, 8) ctl_slave(.main_clock(clk),
                                       .sck(ctl_spi_sck),
                                       .cs(ctl_spi_cs),
                                       .si(ctl_spi_si),
                                       .so(ctl_spi_so),

                                       .expect_addr(ctl_expect_addr),
                                       .expect_write(ctl_expect_write),
                                       .expect_read(ctl_expect_read),
                                       .insert_dummy_cycles(ctl_insert_dummy_cycles),

                                       .cmd(ctl_cmd),
                                       .cmd_valid(ctl_cmd_valid),

                                       .addr(ctl_addr),
                                       .addr_valid(ctl_addr_valid),

                                       .write_data(ctl_write_data),
                                       .write_data_valid(ctl_write_data_valid),

                                       .read_data(ctl_read_data),
                                       .read_data_request(ctl_read_data_request),
                                       .read_data_captured(ctl_read_data_captured),

                                       .operation_in_progress(ctl_operation_progress));

    /* Memory QPI interface */
    assign mem_qpi_io[2] = 1'bz;
    assign mem_qpi_io[3] = 1'bz;

	spi_memory_slave#(3, 8) mem_slave(.main_clock(clk),
                                       .sck(mem_qpi_sck),
                                       .cs(mem_qpi_cs),
                                       .si(mem_qpi_io[0]),
                                       .so(mem_qpi_io[1]),

                                       .expect_addr(mem_expect_addr),
                                       .expect_write(mem_expect_write),
                                       .expect_read(mem_expect_read),
                                       .insert_dummy_cycles(mem_insert_dummy_cycles),

                                       .cmd(mem_cmd),
                                       .cmd_valid(mem_cmd_valid),

                                       .addr(mem_addr),
                                       .addr_valid(mem_addr_valid),

                                       .write_data(mem_write_data),
                                       .write_data_valid(mem_write_data_valid),

                                       .read_data(mem_read_data),
                                       .read_data_request(mem_read_data_request),
                                       .read_data_captured(mem_read_data_captured),

                                       .operation_in_progress(mem_operation_progress));


    assign sram_qpi_io[2] = 1'bz;
    assign sram_qpi_io[3] = 1'bz;

    assign sram_qpi_cs[1] = 1'b1;
    assign sram_qpi_cs[2] = 1'b1;
    assign sram_qpi_cs[3] = 1'b1;

    spi_memory_master#(3, SPI_MASTER_SCALER_BITS) sram_master(
                                        .main_clock(clk),
                                        .sck(sram_qpi_sck),
                                        .cs(sram_qpi_cs[0]),
                                        .mosi(sram_qpi_io[0]),
                                        .miso(sram_qpi_io[1]),

                                        .opcode(memory_opcode),
                                        .addr(memory_addr),
                                        .dummy_cycles(8'd0),
                                        .write_data(memory_write),
                                        .read_data(sram_read),

                                        .opcode_addr_trigger(memory_opcode_addr_trigger),
                                        .addr_flag(memory_addr_flag),
                                        .opcode_addr_completed(sram_opcode_addr_completed),

                                        .data_trigger(memory_data_trigger),
                                        .data_trigger_captured(sram_data_trigger_captured),
                                        .data_ready(sram_data_ready),
                                        .data_completed(sram_data_completed),

                                        .finalize_trigger(memory_finalize_trigger),
                                        .finalize_completed(sram_finalize_completed),
                                        .busy(sram_interface_busy),
                                        .state_out(sram_state));


    integer counter = 0;

    
    localparam SM_CTL_IDLE = 0,
               SM_CTL_EXPECT_ADDR = 1, SM_CTL_EXPECT_WRITE = 2, SM_CTL_EXPECT_READ = 3,
               SM_CTL_WAIT_FINISH = 4, SM_CTL_ERR = 5;

    localparam SM_MEM_IDLE = 0,
	           SM_MEM_EXPECT_ADDR = 1, SM_MEM_EXPECT_ADDR_COMPLETED = 2,
               SM_MEM_EXPECT_READ = 3, SM_MEM_EXPECT_READ_COMPLETED = 4,
               SM_MEM_EXPECT_WRITE = 5, SM_MEM_EXPECT_WRITE_COMPLETED = 6,
               SM_MEM_EXPECT_FINISH = 7,
               SM_MEM_WAIT_FINISH = 8, SM_MEM_ERR = 9;

    reg [2:0] sm_ctl = SM_CTL_IDLE;
    reg [5:0] sm_mem = SM_MEM_IDLE;

    assign status = {
	    7'd0, sm_mem == SM_MEM_IDLE//sram_interface_busy
	};

    assign ctl_read_data = (ctl_addr == 8'h00) ? memory_status : 
                           (ctl_addr == 8'h01) ? sram_status :
                           (ctl_addr == 8'h02) ? flash_status :
                           (ctl_addr == 8'h03) ? sm_mem :
                            8'hAB;

    reg write_triggered = 1'b0;

    always @ (posedge clk) begin

        case (sm_ctl)
        SM_CTL_IDLE: begin
            if (ctl_cmd_valid) begin
                ctl_expect_write <= 1'b0;
                ctl_expect_read <= 1'b0;
                ctl_expect_addr <= 1'b1;
                sm_ctl <= SM_CTL_EXPECT_ADDR;
            end
        end

        SM_CTL_EXPECT_ADDR: begin
            if (ctl_addr_valid) begin
                ctl_expect_addr <= 1'b0;
                case (ctl_cmd)
                8'h02: begin // WRITE to control register
                    ctl_expect_write <= 1'b1;
                    ctl_insert_dummy_cycles <= 1'b0;
                    sm_ctl <= SM_CTL_EXPECT_WRITE;
                end
                8'h03: begin // READ from control register
                    ctl_expect_read <= 1'b1;
                    ctl_insert_dummy_cycles <= 1'b1;
                    sm_ctl <= SM_CTL_EXPECT_READ;
                end
                default: begin
                    sm_ctl <= SM_CTL_ERR;
                end
                endcase
            end
        end

        SM_CTL_EXPECT_READ: begin
            sm_ctl <= SM_CTL_WAIT_FINISH;
        end

        SM_CTL_EXPECT_WRITE: begin
            if (ctl_write_data_valid) begin
                if (ctl_addr == 8'h00) begin
                    map_to_flash <= ctl_write_data[5];
                end else if (ctl_addr == 8'h01) begin
                    memory_finalize_trigger <= 1'b1;
                end
                sm_ctl <= SM_CTL_WAIT_FINISH;
            end
        end

        SM_CTL_WAIT_FINISH: begin
            if (!ctl_operation_progress) begin
                sm_ctl <= SM_CTL_IDLE;
                ctl_expect_write <= 1'b0;
                ctl_expect_read <= 1'b0;
                ctl_expect_addr <= 1'b0;
            end
        end

        SM_CTL_ERR: begin
            sm_ctl <= SM_CTL_WAIT_FINISH;
        end

        default: begin
            sm_ctl <= SM_CTL_ERR;
        end
        endcase

        case (sm_mem)
 
        SM_MEM_IDLE: begin
            if (mem_cmd_valid) begin
                mem_expect_write <= 1'b0;
                mem_expect_read <= 1'b0;
                mem_expect_addr <= 1'b1;
                memory_finalize_trigger <= 1'b0;
                memory_data_trigger <= 1'b0;
                memory_opcode_addr_trigger <= 1'b0;
                sm_mem <= SM_MEM_EXPECT_ADDR;
            end
        end

        SM_MEM_WAIT_FINISH: begin
            if (!mem_operation_progress) begin
                sm_mem <= SM_MEM_IDLE;
                mem_expect_write <= 1'b0;
                mem_expect_read <= 1'b0;
                mem_expect_addr <= 1'b0;
            end
        end

        SM_MEM_EXPECT_ADDR: begin
            if (!mem_operation_progress) begin
                memory_finalize_trigger <= 1'b1;
                sm_mem <= SM_MEM_WAIT_FINISH;
            end else if (mem_addr_valid) begin
                mem_expect_addr <= 1'b0;
                case (mem_cmd)
                8'h02: begin // WRITE to memory
                    mem_expect_write <= 1'b1;
                    mem_insert_dummy_cycles <= 1'b0;

                    memory_addr <= mem_addr;
                    memory_addr_flag <= 1'b1;
                    memory_opcode_addr_trigger <= 1'b1;
                    memory_opcode <= 8'h02;

                    sm_mem <= SM_MEM_EXPECT_ADDR_COMPLETED;
                end
                8'h03: begin // READ from memory
                    mem_expect_read <= 1'b1;
                    mem_insert_dummy_cycles <= 1'b1;

                    memory_addr <= mem_addr;
                    memory_addr_flag <= 1'b1;
                    memory_opcode_addr_trigger <= 1'b1;
                    memory_opcode <= 8'h03;

                    sm_mem <= SM_MEM_EXPECT_ADDR_COMPLETED;
                end
                default: begin
                    sm_mem <= SM_MEM_ERR;
                end
                endcase
            end
        end

        SM_MEM_EXPECT_ADDR_COMPLETED: begin
            if (memory_opcode_addr_completed) begin
                memory_data_trigger <= 1'b0;
                case (memory_opcode)
                8'h02: begin // WRITE to memory
                    sm_mem <= SM_MEM_EXPECT_WRITE;
                end
                8'h03: begin // READ memory
                    sm_mem <= SM_MEM_EXPECT_READ;
                end
                endcase
            end
        end

        SM_MEM_EXPECT_READ: begin
            if (!mem_operation_progress) begin
                memory_finalize_trigger <= 1'b1;
                sm_mem <= SM_MEM_WAIT_FINISH;
            end else if (mem_read_data_request) begin
                memory_data_trigger <= 1'b1;
                sm_mem <= SM_MEM_EXPECT_READ_COMPLETED;
            end
        end

        SM_MEM_EXPECT_READ_COMPLETED: begin
            if (!mem_operation_progress) begin
                memory_finalize_trigger <= 1'b1;
                sm_mem <= SM_MEM_WAIT_FINISH;
            end else if (memory_data_completed && !mem_read_data_request) begin
                mem_read_data <= sram_read;
                memory_data_trigger <= 1'b0;
                sm_mem <= SM_MEM_EXPECT_READ;
            end
        end

        SM_MEM_EXPECT_WRITE: begin
            if (!mem_operation_progress) begin
                memory_finalize_trigger <= 1'b1;
                sm_mem <= SM_MEM_WAIT_FINISH;
            end else if (mem_write_data_valid) begin
                write_triggered <= 1'b0;
                memory_write <= mem_write_data;
                memory_data_trigger <= 1'b1;
                sm_mem <= SM_MEM_EXPECT_WRITE_COMPLETED;
            end
        end

        SM_MEM_EXPECT_WRITE_COMPLETED : begin
            if (!mem_write_data_valid) begin
                write_triggered <= 1'b1;
            end
            if (write_triggered && memory_data_completed) begin
                sm_mem <= SM_MEM_EXPECT_WRITE;
                memory_data_trigger <= 1'b0;
            end
        end

        SM_MEM_EXPECT_FINISH : begin
            if (memory_finalize_completed) begin
                sm_mem <= SM_MEM_WAIT_FINISH;
            end
        end

        SM_MEM_ERR: begin
            sm_mem <= SM_MEM_WAIT_FINISH;
        end
        default: begin
            sm_mem <= SM_MEM_ERR;
        end
        endcase
    end

endmodule
