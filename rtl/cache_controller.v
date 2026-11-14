// Cache Controller FSM
//
//   IDLE    --cpu_req-->            LOOKUP   (latch address)
//   LOOKUP  --hit-->                IDLE     (cpu_ready, hit pulse)
//   LOOKUP  --miss-->               REFILL   (miss pulse, start memory fetch)
//   REFILL  --refill_done-->        RESPOND  (write data, tag, valid)
//   RESPOND -->                     IDLE     (cpu_ready)
module cache_controller (
    input  wire clk,
    input  wire rst,
    input  wire cpu_req,
    input  wire hit,           // from tag comparator
    input  wire refill_done,   // from memory interface
    output reg  latch_addr,
    output reg  cpu_ready,
    output reg  refill_start,
    output reg  array_we,      // write data RAM, tag RAM, valid bit
    output reg  hit_pulse,     // for statistics
    output reg  miss_pulse
);
    localparam IDLE    = 2'd0,
               LOOKUP  = 2'd1,
               REFILL  = 2'd2,
               RESPOND = 2'd3;

    reg [1:0] state, next;

    always @(posedge clk)
        if (rst) state <= IDLE;
        else     state <= next;

    always @(*) begin
        next         = state;
        latch_addr   = 1'b0;
        cpu_ready    = 1'b0;
        refill_start = 1'b0;
        array_we     = 1'b0;
        hit_pulse    = 1'b0;
        miss_pulse   = 1'b0;

        case (state)
            IDLE: if (cpu_req) begin
                latch_addr = 1'b1;
                next       = LOOKUP;
            end
            LOOKUP: if (hit) begin
                cpu_ready = 1'b1;
                hit_pulse = 1'b1;
                next      = IDLE;
            end else begin
                miss_pulse   = 1'b1;
                refill_start = 1'b1;
                next         = REFILL;
            end
            REFILL: if (refill_done) begin
                array_we = 1'b1;
                next     = RESPOND;
            end
            RESPOND: begin
                cpu_ready = 1'b1;
                next      = IDLE;
            end
        endcase
    end
endmodule
