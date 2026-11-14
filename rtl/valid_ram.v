// Valid-Bit RAM: one valid bit per line. All bits are cleared on reset,
// so every line starts invalid (cold cache) and the first access misses.
module valid_ram #(
    parameter LINES = 64
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     we,       // set valid on refill
    input  wire [$clog2(LINES)-1:0] index,
    output wire                     valid_out
);
    reg [LINES-1:0] valid;

    always @(posedge clk) begin
        if (rst)     valid        <= {LINES{1'b0}};
        else if (we) valid[index] <= 1'b1;
    end

    assign valid_out = valid[index];
endmodule
