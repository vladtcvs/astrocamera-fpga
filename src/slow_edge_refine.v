module slow_edge_refine(clk, in, out);

    parameter BITS = 4;

    input wire clk;
    input wire in;
    output wire out;

    reg prev;
    assign out = prev;
    reg [BITS-1:0] chain;
    wire [BITS-1:0] invchain = ~chain;

    always @ (posedge clk)
    begin
        chain <= {chain[BITS-2:0], in};
        if (prev == 1'b0) begin
            if (invchain == 0) begin
                prev <= 1'b1;
            end
        end else begin
            if (chain == 0) begin
                prev <= 1'b0;
            end
        end
    end
endmodule
