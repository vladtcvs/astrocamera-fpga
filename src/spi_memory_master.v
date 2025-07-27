/*
 * CPOL = 0
 * CPHA = 0
 * MOSI data is sampled by slave on rising edge of SCK
 * MISO data is sampled by master (this) on rising edge of SCK and shifted of falling
 *
 * SCK has 1/2 frequency of main_clk
*/
module spi_memory_master(main_clock,
                         sck, cs, mosi, miso,

                         opcode,              // instruction opcode
                         addr,                // address
                         dummy_cycles,        // dummy cycles (usually before read)
                         write_data,          // data to send
                         read_data,           // received data

                         opcode_addr_trigger,   // 0->1 start transmit opcode and addr (if addr_flag)
                         addr_flag,             // send address flag
                         opcode_addr_completed, // ready transmit opcode and addr

                         data_trigger,        // 0->1 start transmit / receive data byte
                         data_ready,          // ready for new trasmit / receive
                         data_completed,      // trasmit / receive completed

                         finalize_trigger,      // finish

                         busy,
						  state_out);

    parameter ADDR_BYTES = 3;
    parameter SCALER_BITS = 10;

    input wire main_clock;

    output reg sck = 1'b0 /* synthesis syn_force_pads=1 syn_noprune=1*/;
    output reg cs = 1'b1  /* synthesis syn_force_pads=1 syn_noprune=1*/;
    output wire mosi      /* synthesis syn_force_pads=1 syn_noprune=1*/;
    input wire miso       /* synthesis syn_force_pads=1 syn_noprune=1*/;

    output wire [3:0] state_out;

    ////////////////////////////////////////////////////////////////

    input wire [7:0]              opcode;
    input wire [ADDR_BYTES*8-1:0] addr;
    input wire [3:0]              dummy_cycles;
    input wire [7:0]              write_data;
    output reg [7:0]              read_data = 8'h00;

    input wire opcode_addr_trigger;
    input wire addr_flag;
    output reg opcode_addr_completed = 1'b0;

    input wire data_trigger;
    output reg data_ready = 1'b0;
    output reg data_completed = 1'b0;

    input wire finalize_trigger;

    output reg busy = 1'b0;

    ///////////////////////////////////////////////////////////////

    localparam STATE_IDLE = 4'd0,
              STATE_PREPARE = 4'd1,
              STATE_OPCODE = 4'd2,
              STATE_PRE_ADDR = 4'd3,
              STATE_ADDR = 4'd4,
              STATE_PRE_DUMMY = 4'd5,
              STATE_DUMMY = 4'd6,
              STATE_OPCODE_ADDR_COMPLETED = 4'd7,
              STATE_PRE_PROCESS = 4'd8,
              STATE_PROCESS = 4'd9,
              STATE_ERR = 4'd10,
              STATE_FINAL = 4'd15;

    reg [3:0] state = STATE_IDLE;
    reg [7:0] operation = 8'h00;

    reg [ADDR_BYTES*8-1:0] addr_shift;
    reg [7:0] write_shift = 8'h00;

    reg [9:0] counter = 0;

    reg prev_opcode_addr_trigger = 1'b0;
    reg prev_data_trigger = 1'b0;
    reg prev_finalize_trigger = 1'b0;

    reg opcode_addr_triggered = 1'b0;
    reg data_triggered = 1'b0;
    reg finalize_triggered = 1'b0;

    assign state_out = state;

    reg [SCALER_BITS-1:0] scaler = 'd0;
    wire scaler_reached = (scaler == 0);

    ///////////////////////////////////////////////////////////////

    assign mosi = (state == STATE_OPCODE) ? operation[7] :
                  (state == STATE_ADDR) ? addr_shift[ADDR_BYTES*8-1] :
                  (state == STATE_PROCESS) ? write_shift[7] :
                  1'b0;

    always @ (posedge main_clock)
    begin
        scaler <= scaler + 'd1;
        if (finalize_triggered) begin
            state <= STATE_FINAL;
            finalize_triggered <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE : begin
                    if (opcode_addr_triggered) begin
                        operation <= opcode;
                        state <= STATE_PREPARE;
                        counter <= 10'h0;
                        scaler <= 'd1;
                        addr_shift <= addr;
                        read_data <= 8'h00;
                        cs <= 1'b0;
                        busy <= 1'b1;
                        opcode_addr_triggered <= 1'b0;
                    end
                end

                STATE_PREPARE : begin
                    if (counter != 10'd7) begin
                        if (scaler_reached)
                            counter <= counter + 1'd1;
                    end else begin
                        if (scaler_reached) begin
                            state <= STATE_OPCODE;
                            counter <= 10'd0;
                        end
                    end
                end

                STATE_OPCODE : begin
                    if (scaler_reached) begin
                        if (counter[0] == 1'b0) begin
                            // posedge of SCK
                            sck <= 1'b1;
                            counter <= counter + 1'd1;
                        end else begin
                            // negedge of SCK and shift operation
                            sck <= 1'b0;
                            if (counter != 10'd15) begin
                                operation <= {operation[6:0], 1'b0};
                                counter <= counter + 1'd1;
                            end else begin
                                counter <= 10'd0;
                                state <= STATE_PRE_ADDR;
                            end
                        end
                    end
                end

                STATE_PRE_ADDR : begin
                    if (addr_flag)
                        state <= STATE_ADDR;
                    else
                        state <= STATE_PRE_DUMMY;
                end

                STATE_ADDR : begin
                    if (scaler_reached) begin
                        if (counter[0] == 1'b0) begin
                            // posedge of SCK
                            sck <= 1'b1;
                            counter <= counter + 1'b1;
                        end else begin
                            // negedge of SCK and shift operation
                            sck <= 1'b0;
                            if (counter != 2 * 8 * ADDR_BYTES - 1) begin
                                addr_shift <= {addr_shift[8 * ADDR_BYTES - 2:0], 1'b0};
                                counter <= counter + 1'd1;
                            end else begin
                                counter <= 10'd0;
                                state <= STATE_PRE_DUMMY;
                            end
                        end
                    end
                end

                STATE_PRE_DUMMY : begin
                    if (dummy_cycles != 4'd0)
                        state <= STATE_DUMMY;
                    else
                        state <= STATE_OPCODE_ADDR_COMPLETED;
                end

                STATE_DUMMY : begin
                    if (scaler_reached) begin
                        if (counter[0] == 1'b0) begin
                            // posedge of SCK
                            sck <= 1'b1;
                        end else begin
                            // negedge of SCK
                            sck <= 1'b0;
                            if (counter == 2*dummy_cycles - 1) begin
                                state <= STATE_OPCODE_ADDR_COMPLETED;
                            end
                        end
                    end
                end

                STATE_OPCODE_ADDR_COMPLETED: begin
                    state <= STATE_PRE_PROCESS;
                    opcode_addr_completed <= 1'b1;
                    data_ready <= 1'b1;
                    data_completed <= 1'b0;
                    busy <= 1'b0;
                end

                STATE_PRE_PROCESS : begin
                    if (data_triggered) begin
                        counter <= 10'd0;
                        scaler <= 'd1;
                        state <= STATE_PROCESS;
                        write_shift <= write_data;
                        data_ready <= 1'b0;
                        data_completed <= 1'b0;
                        data_triggered <= 1'b0;
                        busy <= 1'b1;
                    end
                end

                STATE_PROCESS : begin
                    if (scaler_reached) begin
                        if (counter[0] == 1'b0) begin
                            // posedge of SCK
                            sck <= 1'b1;
                            read_data <= {read_data[6:0], miso};
                            counter <= counter + 1'd1;
                        end else begin
                            // negedge of SCK
                            sck <= 1'b0;
                            if (counter != 10'd15) begin
                                counter <= counter + 1'd1;
                                write_shift <= {write_shift[6:0], 1'd0};
                            end else begin
                                counter <= 10'd0;
                                data_ready <= 1'b1;
                                data_completed <= 1'd1;
                                state <= STATE_PRE_PROCESS;
                                busy <= 1'b0;
                            end
                        end
                    end
                end

                STATE_ERR: begin
                end

                STATE_FINAL: begin
                    state <= STATE_IDLE;
                    busy <= 1'b0;
                    counter <= 10'h00;
                    opcode_addr_completed <= 1'b0;
                    data_ready <= 1'b0;
                    data_completed <= 1'b0;
                    read_data <= 8'h00;
                    cs <= 1'b1;
                    addr_shift <= 'h0;
                end
            endcase
        end

        prev_opcode_addr_trigger <= opcode_addr_trigger;
        prev_data_trigger <= data_trigger;
        prev_finalize_trigger <= finalize_trigger;

        if (!prev_opcode_addr_trigger && opcode_addr_trigger)
            opcode_addr_triggered <= 1'b1;
        if (!prev_data_trigger && data_trigger)
            data_triggered <= 1'b1;
        if (!prev_finalize_trigger && finalize_trigger)
            finalize_triggered <= 1'b1;

    end

endmodule
