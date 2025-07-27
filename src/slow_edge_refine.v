module slow_edge_refine(clk, in, out);

    input wire clk;
    input wire in;
    output wire out;

    reg prev;
    assign out = prev;
    reg [3:0] chain;

    always @ (posedge clk)
    begin
        chain <= {chain[2:0], in};
        if (prev == 1'b0) begin
            if (chain == 4'hF) begin
                prev <= 1'b1;
            end
        end else begin
            if (chain == 4'h0) begin
                prev <= 1'b0;
            end
        end
    end
endmodule
