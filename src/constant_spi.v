/*
 * CPOL = 0
 * CPHA = 0
 * MOSI data is sampled by slave (this) on rising edge of SCK
 * MISO data is sampled by master on rising edge of SCK and shifted of falling
 */

module constant_spi(main_clock, sck, cs, so, status);    // main clock
    input  wire main_clock;
    output reg [7:0] status;

    // Port declarations
    input  wire sck;
    input  wire cs;
    output  wire so;

    reg prev_cs = 1'b1;
    reg prev_sck = 1'b0;

    reg [7:0] data;

    assign so = !cs ? data[7] : 1'bz;

    always @ (posedge main_clock) begin
        if (cs) begin
            data <= 8'hAB;
	    status <= 0;
        end else if (!cs) begin
            if (prev_sck & ~sck) begin
                data <= {data[6:0], data[7]};
                status <= status + 1;
            end
        end
        prev_cs <= cs;
        prev_sck <= sck;
    end

endmodule
