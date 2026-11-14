// Address Decoder: splits a CPU address into tag / index / offset fields.
// Default (1 KB cache, 16 B blocks, 32-bit address):
//   offset = addr[3:0]   (4 bits)
//   index  = addr[9:4]   (6 bits -> 64 lines)
//   tag    = addr[31:10] (22 bits)

// parameters make the module reusable and adaptable to any combination of block size and number of lines in a cache

module addr_decoder #(
    parameter ADDR_W   = 32,
    parameter INDEX_W  = 6,
    parameter OFFSET_W = 4
) (
    input  wire [ADDR_W-1:0]                  addr,
    output wire [ADDR_W-INDEX_W-OFFSET_W-1:0] tag,
    output wire [INDEX_W-1:0]                 index,
    output wire [OFFSET_W-1:0]                offset
);
    assign offset = addr[OFFSET_W-1:0];
    assign index  = addr[OFFSET_W+INDEX_W-1:OFFSET_W];
    assign tag    = addr[ADDR_W-1:OFFSET_W+INDEX_W];
endmodule

// Offset [3:0] (4 bits): Points to the specific byte/word inside a 16-byte block.
// Index [9:4] (6 bits): Selects which of the 64 rows/lines in the cache to check.
// Tag [31:10] (22 bits): The unique identifier tag stored in that row.