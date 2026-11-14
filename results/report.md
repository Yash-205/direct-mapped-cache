# Hit/Miss Report and AMAT Analysis

**Configuration:** 1 KB direct-mapped cache, 16-byte blocks, 32-bit addresses → 64 lines.
Main-memory latency in the testbench is 10 cycles. All reads are 32-bit words.

## Address breakdown

| Field  | Bits    | Width | Reason                          |
|--------|---------|-------|---------------------------------|
| Offset | [3:0]   | 4     | log2(16 B block)                |
| Index  | [9:4]   | 6     | log2(1024 / 16 = 64 lines)      |
| Tag    | [31:10] | 22    | 32 − 6 − 4                      |

## Timing (from simulation)

- **Hit time:** 1 cycle (LOOKUP state answers directly).
- **Miss penalty:** 13 extra cycles = 10 (memory latency) + 1 (capture block in the memory interface) + 1 (write data/tag/valid) + 1 (respond).
- **AMAT** = Hit time + Miss ratio × Miss penalty

## Results

| Trace      | Accesses | Hits | Misses | Hit ratio | Miss ratio | AMAT (cycles)         |
|------------|---------:|-----:|-------:|----------:|-----------:|-----------------------|
| Sequential | 512      | 384  | 128    | 75.00 %   | 25.00 %    | 1 + 0.25 × 13 = 4.250 |
| Random     | 512      | 4    | 508    | 0.78 %    | 99.22 %    | 1 + 0.992 × 13 = 13.898 |
| Repeated   | 1024     | 992  | 32     | 96.88 %   | 3.12 %     | 1 + 0.031 × 13 = 1.406 |

The AMAT measured by counting simulation cycles is the same as the formula value for every trace. All returned data was checked against the memory model: 0 errors.

## Analysis

- **Sequential (spatial locality):** each 16-byte block holds 4 words. The first word of each block misses and the next 3 hit, so the hit ratio is exactly 3/4 = 75 %. Larger blocks would raise this.
- **Random (little locality):** addresses are spread over 64 KB, 64 times larger than the cache, so almost every access maps to a line holding another block. The hit ratio is close to the expected 1/64.
- **Repeated (temporal locality):** the 512-byte loop fits in the cache (32 lines). Only the first pass misses (32 compulsory misses); the other 7 passes all hit.
- **Valid bits:** all lines are invalid after reset, so the first access to every line is a compulsory miss even if the stored tag happens to match.
- **Direct-mapped limitation:** two addresses 1 KB apart share an index and evict each other (conflict misses). A set-associative cache would reduce this.

## Synthesis (Yosys, generic gates)

See `synth/synth_report.txt`. Main figures: 9,600 enable flip-flops for storage (64 × 128 data bits + 64 × 22 tag bits), 64 valid-bit flops, about 9,600 multiplexers for the read path, and about 20,100 cells in total. On an FPGA flow (Vivado or Quartus), the data and tag arrays would map to block RAM or LUT RAM instead.
