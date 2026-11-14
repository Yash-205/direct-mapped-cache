// Behavioural main-memory model (simulation only).
// Answers a block request after LATENCY cycles. Each 32-bit word holds its
// own byte address, so the testbench can check that the data is correct.
module main_memory #(
    parameter ADDR_W      = 32,
    parameter BLOCK_BYTES = 16,
    parameter LATENCY     = 10
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     mem_req,
    input  wire [ADDR_W-1:0]        mem_addr,
    output reg                      mem_ready,
    output reg  [BLOCK_BYTES*8-1:0] mem_rdata
);
    integer cnt, w;

    always @(posedge clk) begin
        mem_ready <= 1'b0;
        if (rst) begin
            cnt <= 0;
        end else if (mem_req && !mem_ready) begin
            if (cnt == LATENCY - 1) begin
                for (w = 0; w < BLOCK_BYTES/4; w = w + 1)
                    mem_rdata[w*32 +: 32] <= mem_addr + w*4;
                mem_ready <= 1'b1;
                cnt       <= 0;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
endmodule
