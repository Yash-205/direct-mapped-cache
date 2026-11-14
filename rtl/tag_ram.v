// Tag RAM: one tag per cache line. Synchronous write, asynchronous read.
module tag_ram #(
    parameter LINES  = 64,
    parameter TAG_W  = 22
) (
    input  wire                     clk,
    input  wire                     we,
    input  wire [$clog2(LINES)-1:0] index,
    input  wire [TAG_W-1:0]         tag_in,
    output wire [TAG_W-1:0]         tag_out
);
    reg [TAG_W-1:0] mem [0:LINES-1];

    always @(posedge clk)
        if (we) mem[index] <= tag_in;

    assign tag_out = mem[index];
endmodule
