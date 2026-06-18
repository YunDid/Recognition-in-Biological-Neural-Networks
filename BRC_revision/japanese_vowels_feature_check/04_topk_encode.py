#!/usr/bin/env python3
"""Convert continuous site-score blocks into top-k binary stimulation blocks."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np


def read_block_data(data_path: Path) -> list[np.ndarray]:
    blocks: list[np.ndarray] = []
    current: list[list[float]] = []
    for line in data_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            if current:
                blocks.append(np.asarray(current, dtype=float))
                current = []
            continue
        current.append([float(x) for x in line.split()])
    if current:
        blocks.append(np.asarray(current, dtype=float))
    return blocks


def write_block_data(blocks: list[np.ndarray], out_path: Path) -> None:
    lines: list[str] = []
    for block in blocks:
        for row in block:
            lines.append(" ".join(str(int(value)) for value in row))
        lines.append("")
    out_path.write_text("\n".join(lines), encoding="utf-8")


def topk_block(block: np.ndarray, k: int) -> np.ndarray:
    if k < 1 or k > block.shape[1]:
        raise ValueError(f"k must be in [1, {block.shape[1]}], got {k}.")
    out = np.zeros(block.shape, dtype=int)
    for row_idx, row in enumerate(block):
        if np.all(np.abs(row) < 1e-12):
            continue
        order = np.argsort(row)[::-1]
        out[row_idx, order[:k]] = 1
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--k", required=True, type=int, choices=range(1, 7))
    args = parser.parse_args()

    blocks = read_block_data(args.data)
    out_blocks = [topk_block(block, args.k) for block in blocks]
    write_block_data(out_blocks, args.out)
    print(f"wrote,{args.out}")
    print(f"k,{args.k}")
    print(f"n_samples,{len(out_blocks)}")


if __name__ == "__main__":
    main()
