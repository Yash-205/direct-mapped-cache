// Testbench: replays a memory-access trace, checks every returned word,
// and reports hits, misses, hit/miss ratio and AMAT.
//
// Usage: vvp sim.vvp +TRACE=traces/sequential.hex
`timescale 1ns/1ps
module tb_cache;
    localparam ADDR_W      = 32;
    localparam CACHE_BYTES = 1024;
    localparam BLOCK_BYTES = 16;
    localparam MEM_LATENCY = 10;

    reg                      clk = 0, rst = 1;
    reg                      cpu_req = 0;
    reg  [ADDR_W-1:0]        cpu_addr = 0;
    wire [31:0]              cpu_rdata;
    wire                     cpu_ready, hit, miss;
    wire                     mem_req, mem_ready;
    wire [ADDR_W-1:0]        mem_addr;
    wire [BLOCK_BYTES*8-1:0] mem_rdata;

    always #5 clk = ~clk;   // 100 MHz

    cache_top #(.ADDR_W(ADDR_W), .CACHE_BYTES(CACHE_BYTES), .BLOCK_BYTES(BLOCK_BYTES)) dut (
        .clk(clk), .rst(rst),
        .cpu_req(cpu_req), .cpu_addr(cpu_addr), .cpu_rdata(cpu_rdata),
        .cpu_ready(cpu_ready), .hit(hit), .miss(miss),
        .mem_req(mem_req), .mem_addr(mem_addr),
        .mem_ready(mem_ready), .mem_rdata(mem_rdata));

    main_memory #(.ADDR_W(ADDR_W), .BLOCK_BYTES(BLOCK_BYTES), .LATENCY(MEM_LATENCY)) mem (
        .clk(clk), .rst(rst), .mem_req(mem_req), .mem_addr(mem_addr),
        .mem_ready(mem_ready), .mem_rdata(mem_rdata));

    // statistics
    integer hits = 0, misses = 0, errors = 0;
    integer total_cycles = 0, hit_cycles = 0, miss_cycles = 0;
    always @(posedge clk) begin
        if (hit)  hits   = hits + 1;
        if (miss) misses = misses + 1;
    end

    reg [1023:0] trace_file;
    integer fd, cycles, accesses, was_hit;
    reg [ADDR_W-1:0] addr;
    real hit_rate, miss_rate, t_hit, t_penalty, amat_formula, amat_measured;

    initial begin
        if (!$value$plusargs("TRACE=%s", trace_file))
            trace_file = "traces/sequential.hex";
        fd = $fopen(trace_file, "r");
        if (fd == 0) begin
            $display("ERROR: cannot open %0s", trace_file);
            $finish;
        end

        $dumpfile("build/dump.vcd");
        $dumpvars(0, tb_cache);

        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);

        accesses = 0;
        while ($fscanf(fd, "%h\n", addr) == 1) begin
            // issue one read request
            cpu_addr <= addr;
            cpu_req  <= 1'b1;
            @(posedge clk);
            cpu_req  <= 1'b0;
            cycles  = 0;
            was_hit = 0;
            // wait for the response
            while (!cpu_ready) begin
                @(posedge clk);
                cycles = cycles + 1;
                if (hit) was_hit = 1;
            end
            if (cpu_rdata !== {addr[31:2], 2'b00}) begin
                errors = errors + 1;
                if (errors <= 5)
                    $display("DATA ERROR addr=%h got=%h", addr, cpu_rdata);
            end
            total_cycles = total_cycles + cycles;
            if (was_hit) hit_cycles  = cycles;
            else         miss_cycles = cycles;
            accesses = accesses + 1;
            @(posedge clk);   // back in IDLE
        end
        $fclose(fd);

        hit_rate      = 100.0 * hits / accesses;
        miss_rate     = 100.0 * misses / accesses;
        t_hit         = hit_cycles;
        t_penalty     = miss_cycles - hit_cycles;
        amat_formula  = t_hit + (misses * 1.0 / accesses) * t_penalty;
        amat_measured = total_cycles * 1.0 / accesses;

        $display("------------------------------------------------");
        $display("Trace           : %0s", trace_file);
        $display("Cache           : %0d B, %0d B blocks, %0d lines",
                 CACHE_BYTES, BLOCK_BYTES, CACHE_BYTES/BLOCK_BYTES);
        $display("Accesses        : %0d", accesses);
        $display("Hits / Misses   : %0d / %0d", hits, misses);
        $display("Hit ratio       : %0.2f %%", hit_rate);
        $display("Miss ratio      : %0.2f %%", miss_rate);
        $display("Hit time        : %0.0f cycles", t_hit);
        $display("Miss penalty    : %0.0f cycles", t_penalty);
        $display("AMAT (formula)  : %0.3f cycles", amat_formula);
        $display("AMAT (measured) : %0.3f cycles", amat_measured);
        $display("Data errors     : %0d", errors);
        $display("------------------------------------------------");
        $finish;
    end
endmodule
