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

                    output wire [7:0] status);
 
    wire [7:0] controller_status;
    wire [7:0] flash_status;
    wire [7:0] memory_status;

    /* Control interface wires */
    wire [7:0] ctl_addr;
    wire [7:0] ctl_read_data;
    wire ctl_read_data_flag;
    wire [7:0] ctl_write_data;
    wire ctl_write_data_flag;
    wire ctl_operation_progress;
    wire ctl_write_data_prepare;
    wire ctl_read_data_prepare;
    wire ctl_addr_valid;

    /* Memory interface wires */
    wire [23:0] mem_addr;
    reg [7:0] mem_read_data = 8'h12;
    wire mem_read_data_flag;
    wire [7:0] mem_write_data;
    wire mem_write_data_flag;
    wire mem_operation_progress;
    wire mem_write_data_prepare;
    wire mem_read_data_prepare;
    wire mem_addr_valid;
    reg mem_invalid_operation = 1'b0;

    assign mem_qpi_io[2] = 1'bz;
    assign mem_qpi_io[3] = 1'bz;

    /* Flash access wires */
    reg [7:0]  flash_opcode = 8'h00;
    reg [23:0] flash_addr = 24'h0;
    reg [7:0]  flash_write = 8'hFF;
    wire [7:0] flash_read;
    reg flash_erase = 1'b0;
    reg flash_addr_flag = 1'b0;
    reg flash_wel = 1'b0;

    /* Send command for transmit opcode & addr */
	reg flash_opcode_addr_trigger = 1'b0;
    wire flash_opcode_addr_completed;

    /* Transmit and receive data */
    reg flash_data_trigger = 1'b0;
    wire flash_data_ready;
    wire flash_data_completed;

    reg flash_access_not_ready = 1'b0;
    reg flash_finalize_trigger = 1'b0;
    wire flash_interface_busy;
    reg flash_busy = 1'b0;

    localparam FLASH_SM_IDLE = 4'd0,
               FLASH_SM_READ = 4'd1,
               FLASH_SM_WRITE = 4'd2,
               FLASH_SM_WREN = 4'd3,
               FLASH_SM_WREN_FINISH = 4'd4,
               FLASH_SM_ERASE = 4'd5,
               FLASH_SM_ERR = 4'd14,
               FLASH_SM_FINAL = 4'd15;

    reg [3:0] flash_sm;

    /* Common control */
    reg map_to_flash = 1'b1;
    reg flash_sck_go = 1'b1;

    assign controller_status = {4'hF,
                                mem_invalid_operation,
                                flash_access_not_ready,
                                map_to_flash,
                                flash_busy};

    assign flash_status = {flash_wel,

                           flash_interface_busy,
                           flash_finalize_trigger,

                           flash_data_completed,
                           flash_data_ready,
                           flash_data_trigger,

                           flash_opcode_addr_completed,
                           flash_opcode_addr_trigger};

    assign memory_status = {2'h0,
                            mem_read_data_prepare,
                            mem_write_data_prepare,
                            mem_operation_progress,
                            mem_addr_valid,
                            mem_read_data_flag,
                            mem_write_data_flag};

    /*
	 * Control registers map:
	 *
	 * 0x00: {1, 1, 1, 1, 1, MTF, FB, FIB}
	 *     MTF - RW, 0 - map memory SPI interface to SRAM, 1 - map memory SPI interface to Flash
	 *     FB -  RO, flash busy
	 *     FIB - RO, flash interface busy
	 *
	 */

    assign ctl_read_data = (ctl_addr == 8'h00) ? controller_status : 
                           (ctl_addr == 8'h01) ? flash_status : 
                           (ctl_addr == 8'h02) ? memory_status : 
                            8'h00;


    reg [7:0] read_value = 8'hAB;
    

    /* Control SPI interface */
    spi_memory_slave#(1, 0) ctl_slave(.main_clock(clk),
                                       .sck(ctl_spi_sck),
                                       .cs(ctl_spi_cs),
                                       .si(ctl_spi_si),
                                       .so(ctl_spi_so),
                                       .write_data_prepare(ctl_write_data_prepare),
                                       .read_data_prepare(ctl_read_data_prepare),
                                       .addr(ctl_addr),
                                       .addr_valid(ctl_addr_valid),
                                       .write_data(ctl_write_data),
                                       .write_data_flag(ctl_write_data_flag),
                                       .read_data(ctl_read_data),
                                       .read_data_flag(ctl_read_data_flag),
                                       .operation_in_progress(ctl_operation_progress));


    /* Flash SPI master */
    wire [3:0] flash_state;
    spi_memory_master#(3, 5) spimaster(.main_clock(clk),
                                        .sck(flash_sck), .cs(flash_cs), .mosi(flash_mosi), .miso(flash_miso),

                                        .opcode(flash_opcode),
                                        .addr(flash_addr),
                                        .dummy_cycles(4'd0),
                                        .write_data(flash_write),
                                        .read_data(flash_read),

                                        .opcode_addr_trigger(flash_opcode_addr_trigger),
                                        .addr_flag(flash_addr_flag),
                                        .opcode_addr_completed(flash_opcode_addr_completed),

                                        .data_trigger(flash_data_trigger),
                                        .data_ready(flash_data_ready),
                                        .data_completed(flash_data_completed),

                                        .finalize_trigger(flash_finalize_trigger),
                                        .busy(flash_interface_busy),
                                        .state_out(flash_state));

    /* Memory SPI interface */
    spi_memory_slave#(3, 8) memory_slave(.main_clock(clk),
                                       .sck(mem_qpi_sck),
                                       .cs(mem_qpi_cs),
                                       .si(mem_qpi_io[0]),
                                       .so(mem_qpi_io[1]),
                                       .write_data_prepare(mem_write_data_prepare),
                                       .read_data_prepare(mem_read_data_prepare),
                                       .addr(mem_addr),
                                       .addr_valid(mem_addr_valid),
                                       .write_data(mem_write_data),
                                       .write_data_flag(mem_write_data_flag),
                                       .read_data(mem_read_data),
                                       .read_data_flag(mem_read_data_flag),
                                       .operation_in_progress(mem_operation_progress));

    reg prev_ctl_write_data_flag = 1'b0;
    reg prev_ctl_read_data_flag = 1'b0;

    reg prev_mem_write_data_flag = 1'b0;
    reg prev_mem_read_data_flag = 1'b0;

    reg prev_flash_opcode_addr_completed = 1'b0;
    reg prev_flash_data_completed = 1'b0;
    reg prev_flash_data_ready = 1'b0;

    reg prev_ctl_op = 1'b0;
    reg prev_mem_addr_valid = 1'b0;

    reg prev_mem_write_data_prepare = 1'b0;

    integer counter = 0;

    assign status = {flash_access_not_ready, flash_interface_busy,
                     flash_data_completed, flash_data_ready, flash_opcode_addr_completed,
	                 flash_finalize_trigger, flash_data_trigger, flash_opcode_addr_trigger};

    /*assign status = {flash_state, flash_opcode_addr_completed,
	                 flash_finalize_trigger, flash_data_trigger, flash_opcode_addr_trigger};*/

    //assign status = mem_write_data;

    //assign status = flash_addr[7:0];

//    assign status = mem_read_cnt;

    always @ (posedge clk) begin
        /* Write control registers */
        if (!prev_ctl_write_data_flag && ctl_write_data_flag) begin
            if (ctl_addr == 8'h0) begin
                map_to_flash <= ctl_write_data[2];
            end else if (ctl_addr == 8'h1) begin
                if (ctl_write_data[7]) begin
                    flash_erase <= 1'b1;
                end
            end
        end

        case (flash_sm)

        FLASH_SM_IDLE : begin
            flash_finalize_trigger <= 1'b0;
            if (map_to_flash) begin
                if (mem_addr_valid) begin
                    if (mem_read_data_prepare) begin
                        flash_addr <= mem_addr;
                        flash_opcode_addr_trigger <= 1'b1;
                        flash_data_trigger <= 1'b0;
                        flash_opcode <= 8'h03;
                        flash_addr_flag <= 1'b1;
                        flash_sm <= FLASH_SM_READ;

                    end else if (mem_write_data_prepare) begin
                        if (flash_wel) begin
                            flash_addr <= mem_addr;
                            flash_opcode_addr_trigger <= 1'b1;
                            flash_data_trigger <= 1'b0;
                            flash_opcode <= 8'h02;
                            flash_addr_flag <= 1'b1;
                            flash_sm <= FLASH_SM_WRITE;
                        end
                    end else begin
                        mem_invalid_operation <= 1'b1;
                        flash_sm <= FLASH_SM_ERR;
                    end
                end

                if (!flash_wel && (mem_write_data_prepare || flash_erase)) begin
                    flash_addr_flag <= 1'b0;
                    flash_opcode <= 8'h06;
                    flash_opcode_addr_trigger <= 1'b1;
                    flash_sm <= FLASH_SM_WREN;
                end

                if (flash_wel && flash_erase) begin
                    flash_addr_flag <= 1'b0;
                    flash_opcode <= 8'hC7;
                    flash_opcode_addr_trigger <= 1'b1;
                    flash_sm <= FLASH_SM_ERASE;
                end
            end
        end

        FLASH_SM_READ : begin
            if (!prev_mem_read_data_flag && mem_read_data_flag) begin
                if (flash_interface_busy) begin
                    flash_access_not_ready <= 1'b1;
                    flash_sm <= FLASH_SM_ERR;
                end else begin
                    flash_data_trigger <= 1'b1;
                end
            end

            if (!prev_flash_data_completed && flash_data_completed) begin
                read_value <= flash_read;
                mem_read_data <= flash_read;
                flash_data_trigger <= 1'b0;
            end

            if (!mem_operation_progress)
                flash_sm <= FLASH_SM_FINAL;
        end

        FLASH_SM_WRITE : begin
            if (!prev_mem_write_data_flag && mem_write_data_flag) begin
                if (flash_interface_busy) begin
                    flash_access_not_ready <= 1'b1;
                    flash_sm <= FLASH_SM_ERR;
                end else begin
                    flash_write <= mem_write_data;
                    flash_data_trigger <= 1'b1;
                end
            end

            if (!prev_flash_data_completed && flash_data_completed) begin
                flash_data_trigger <= 1'b0;
            end

            if (!mem_operation_progress) begin
                flash_sm <= FLASH_SM_FINAL;
                flash_wel <= 1'b0;
            end
        end

        FLASH_SM_WREN : begin
            if (!prev_flash_opcode_addr_completed && flash_opcode_addr_completed) begin
                flash_sm <= FLASH_SM_FINAL;
                flash_wel <= 1'b1;
            end
        end

        FLASH_SM_ERASE : begin
            if (!prev_flash_opcode_addr_completed && flash_opcode_addr_completed) begin
                flash_sm <= FLASH_SM_FINAL;
                flash_wel <= 1'b0;
                flash_erase <= 1'b0;
            end
        end
        

        FLASH_SM_ERR : begin
            flash_sm <= FLASH_SM_FINAL;
        end

        FLASH_SM_FINAL : begin
            flash_finalize_trigger <= 1'b1;
            flash_sm <= FLASH_SM_IDLE;
            flash_opcode_addr_trigger <= 1'b0;
            flash_data_trigger <= 1'b0;
            flash_access_not_ready <= 1'b0;
            mem_invalid_operation <= 1'b0;
        end

        endcase

        prev_ctl_write_data_flag <= ctl_write_data_flag;
        prev_ctl_read_data_flag <= ctl_read_data_flag;

        prev_mem_read_data_flag <= mem_read_data_flag;
        prev_mem_write_data_flag <= mem_write_data_flag;

        prev_mem_write_data_prepare <= mem_write_data_prepare;

        prev_flash_opcode_addr_completed <= flash_opcode_addr_completed;
        prev_flash_data_completed <= flash_data_completed;
        prev_flash_data_ready <= flash_data_ready;

        prev_ctl_op <= ctl_operation_progress;
        prev_mem_addr_valid <= mem_addr_valid;

    end

endmodule
