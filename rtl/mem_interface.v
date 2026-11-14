// Main-Memory Interface: fetches one whole block from main memory.
//   start      : pulse from the controller (miss detected)
//   mem_req    : held high until main memory answers with mem_ready
//   done       : one-cycle pulse when block_out holds the fetched block
module mem_interface #(
    parameter ADDR_W      = 32,
    parameter BLOCK_BYTES = 16
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     start,
    input  wire [ADDR_W-1:0]        addr,
    output reg                      done,
    output reg  [BLOCK_BYTES*8-1:0] block_out,
    // to / from main memory
    output reg                      mem_req,
    output reg  [ADDR_W-1:0]        mem_addr,
    input  wire                     mem_ready,
    input  wire [BLOCK_BYTES*8-1:0] mem_rdata
);
    localparam OFFSET_W = $clog2(BLOCK_BYTES);

    always @(posedge clk) begin
        if (rst) begin
            mem_req   <= 1'b0;
            mem_addr  <= {ADDR_W{1'b0}};
            done      <= 1'b0;
            block_out <= {BLOCK_BYTES*8{1'b0}};
        end else begin
            done <= 1'b0;
            if (start && !mem_req) begin
                mem_req  <= 1'b1;
                // block-aligned address
                mem_addr <= {addr[ADDR_W-1:OFFSET_W], {OFFSET_W{1'b0}}};
            end else if (mem_req && mem_ready) begin
                mem_req   <= 1'b0;
                block_out <= mem_rdata;
                done      <= 1'b1;
            end
        end
    end
endmodule
