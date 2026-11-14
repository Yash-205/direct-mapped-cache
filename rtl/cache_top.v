// Direct-mapped cache (read path) - top level.
// Defaults: 1 KB cache, 16-byte blocks, 32-bit addresses -> 64 lines.
module cache_top #(
    parameter ADDR_W      = 32,
    parameter CACHE_BYTES = 1024,
    parameter BLOCK_BYTES = 16
) (
    input  wire                     clk,
    input  wire                     rst,
    // CPU side
    input  wire                     cpu_req,
    input  wire [ADDR_W-1:0]        cpu_addr,
    output wire [31:0]              cpu_rdata,
    output wire                     cpu_ready,
    output wire                     hit,        // 1-cycle pulse per hit
    output wire                     miss,       // 1-cycle pulse per miss
    // Main-memory side
    output wire                     mem_req,
    output wire [ADDR_W-1:0]        mem_addr,
    input  wire                     mem_ready,
    input  wire [BLOCK_BYTES*8-1:0] mem_rdata
);
    localparam LINES    = CACHE_BYTES / BLOCK_BYTES;
    localparam OFFSET_W = $clog2(BLOCK_BYTES);
    localparam INDEX_W  = $clog2(LINES);
    localparam TAG_W    = ADDR_W - INDEX_W - OFFSET_W;

    // Latched request address
    reg  [ADDR_W-1:0] addr_q;
    wire latch_addr;
    always @(posedge clk)
        if (rst)             addr_q <= {ADDR_W{1'b0}};
        else if (latch_addr) addr_q <= cpu_addr;

    wire [TAG_W-1:0]    tag;
    wire [INDEX_W-1:0]  index;
    wire [OFFSET_W-1:0] offset;

    addr_decoder #(.ADDR_W(ADDR_W), .INDEX_W(INDEX_W), .OFFSET_W(OFFSET_W)) u_dec (
        .addr(addr_q), .tag(tag), .index(index), .offset(offset));

    wire array_we, valid_bit, cmp_hit, refill_start, refill_done;
    wire [TAG_W-1:0]         stored_tag;
    wire [BLOCK_BYTES*8-1:0] refill_block;

    tag_ram #(.LINES(LINES), .TAG_W(TAG_W)) u_tag (
        .clk(clk), .we(array_we), .index(index), .tag_in(tag), .tag_out(stored_tag));

    valid_ram #(.LINES(LINES)) u_valid (
        .clk(clk), .rst(rst), .we(array_we), .index(index), .valid_out(valid_bit));

    data_ram #(.LINES(LINES), .BLOCK_BYTES(BLOCK_BYTES)) u_data (
        .clk(clk), .we(array_we), .index(index),
        .word_sel(offset[OFFSET_W-1:2]),
        .block_in(refill_block), .word_out(cpu_rdata));

    tag_comparator #(.TAG_W(TAG_W)) u_cmp (
        .valid(valid_bit), .stored_tag(stored_tag), .addr_tag(tag), .hit(cmp_hit));

    cache_controller u_ctrl (
        .clk(clk), .rst(rst), .cpu_req(cpu_req), .hit(cmp_hit),
        .refill_done(refill_done), .latch_addr(latch_addr), .cpu_ready(cpu_ready),
        .refill_start(refill_start), .array_we(array_we),
        .hit_pulse(hit), .miss_pulse(miss));

    mem_interface #(.ADDR_W(ADDR_W), .BLOCK_BYTES(BLOCK_BYTES)) u_mem_if (
        .clk(clk), .rst(rst), .start(refill_start), .addr(addr_q),
        .done(refill_done), .block_out(refill_block),
        .mem_req(mem_req), .mem_addr(mem_addr),
        .mem_ready(mem_ready), .mem_rdata(mem_rdata));
endmodule
