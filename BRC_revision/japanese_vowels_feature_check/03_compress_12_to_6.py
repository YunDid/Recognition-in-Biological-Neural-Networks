#!/usr/bin/env python3
"""Compress 12 feature columns into 6 site scores by adjacent-pair means."""

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
            lines.append(" ".join(f"{value:.10g}" for value in row))
        lines.append("")
    out_path.write_text("\n".join(lines), encoding="utf-8")


def compress_block(block: np.ndarray, use_abs: bool) -> np.ndarray:
    if block.shape[1] != 12:
        raise ValueError(f"Expected 12 columns, got {block.shape[1]}.")
    source = np.abs(block) if use_abs else block
    out = np.zeros((block.shape[0], 6), dtype=float)
    for site in range(6):
        out[:, site] = source[:, 2 * site : 2 * site + 2].mean(axis=1)
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--abs", action="store_true", help="Use abs(value) before adjacent-pair averaging.")
    args = parser.parse_args()

    blocks = read_block_data(args.data)
    out_blocks = [compress_block(block, args.abs) for block in blocks]
    write_block_data(out_blocks, args.out)
    print(f"wrote,{args.out}")
    print(f"n_samples,{len(out_blocks)}")
    print("n_features,6")


if __name__ == "__main__":
    main()
