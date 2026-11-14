// Cache Data RAM: one block (BLOCK_BYTES) per line.
// A refill writes the whole block; a read returns one 32-bit word,
// selected by the word part of the block offset.
module data_ram #(
    parameter LINES       = 64,
    parameter BLOCK_BYTES = 16
) (
    input  wire                             clk,
    input  wire                             we,
    input  wire [$clog2(LINES)-1:0]         index,
    input  wire [$clog2(BLOCK_BYTES/4)-1:0] word_sel,
    input  wire [BLOCK_BYTES*8-1:0]         block_in,
    output wire [31:0]                      word_out
);
    reg [BLOCK_BYTES*8-1:0] mem [0:LINES-1];

    always @(posedge clk)
        if (we) mem[index] <= block_in;

    wire [BLOCK_BYTES*8-1:0] block = mem[index];
    assign word_out = block[word_sel*32 +: 32];
endmodule
