#!/usr/bin/env python3
"""Generate memory-access traces (one hex byte address per line, word aligned).

  sequential.hex : walks through 2 KB word by word (spatial locality)
  random.hex     : 512 random words in a 64 KB range (little locality)
  repeated.hex   : loops 8 times over a 512 B array that fits in the cache
                   (temporal locality)
"""
import os
import random

OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "traces")


def write(name, addrs):
    with open(os.path.join(OUT_DIR, name), "w") as f:
        for a in addrs:
            f.write(f"{a:08x}\n")
    print(f"{name}: {len(addrs)} accesses")


def main():
    random.seed(42)  # reproducible
    os.makedirs(OUT_DIR, exist_ok=True)

    sequential = [a for a in range(0x0000, 0x0800, 4)]
    rand = [random.randrange(0, 0x10000 // 4) * 4 for _ in range(512)]
    repeated = [a for _ in range(8) for a in range(0x1000, 0x1200, 4)]

    write("sequential.hex", sequential)
    write("random.hex", rand)
    write("repeated.hex", repeated)


if __name__ == "__main__":
    main()
