#!/usr/bin/env bash
# Compile the cache and run all three traces. Results go to results/.
set -e
cd "$(dirname "$0")/.."
mkdir -p build results

python3 scripts/gen_traces.py

iverilog -g2012 -o build/sim.vvp rtl/*.v tb/*.v

for t in sequential random repeated; do
    vvp -n build/sim.vvp +TRACE=traces/$t.hex | grep -v -e "VCD info" -e "\$finish" | tee results/$t.txt
done
