#!/usr/bin/env python3
"""Standardize UCI block data and optionally resample each sample to fixed time slots."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np


def parse_speakers(text: str) -> set[int]:
    speakers: set[int] = set()
    for part in text.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            start, end = [int(x) for x in part.split("-", 1)]
            speakers.update(range(start, end + 1))
        else:
            speakers.add(int(part))
    return speakers


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


def select_fit_blocks(blocks: list[np.ndarray], size_path: Path | None, selected_speakers: str) -> list[np.ndarray]:
    if size_path is None:
        return blocks
    sizes = [int(x) for x in size_path.read_text(encoding="utf-8").split()]
    if len(blocks) != sum(sizes):
        raise ValueError(f"Parsed {len(blocks)} samples, but size file expects {sum(sizes)}.")
    selected = parse_speakers(selected_speakers)
    fit_blocks: list[np.ndarray] = []
    idx = 0
    for speaker, count in enumerate(sizes, start=1):
        for _ in range(count):
            if speaker in selected:
                fit_blocks.append(blocks[idx])
            idx += 1
    return fit_blocks


def write_block_data(blocks: list[np.ndarray], out_path: Path) -> None:
    lines: list[str] = []
    for block in blocks:
        for row in block:
            lines.append(" ".join(f"{value:.10g}" for value in row))
        lines.append("")
    out_path.write_text("\n".join(lines), encoding="utf-8")


def resample_time(block: np.ndarray, time_slots: int) -> np.ndarray:
    if time_slots <= 0 or len(block) == time_slots:
        return block.copy()
    if len(block) < time_slots:
        out = np.zeros((time_slots, block.shape[1]), dtype=float)
        out[: len(block), :] = block
        return out
    old_axis = np.arange(len(block), dtype=float)
    new_axis = np.linspace(0, len(block) - 1, time_slots)
    out = np.zeros((time_slots, block.shape[1]), dtype=float)
    for col in range(block.shape[1]):
        out[:, col] = np.interp(new_axis, old_axis, block[:, col])
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--time-slots", type=int, default=0, help="Set to 12 for the BRC MCS fixed-slot representation.")
    parser.add_argument("--fit-size", type=Path, help="Optional size file used to select classes for estimating mean/std.")
    parser.add_argument("--fit-speakers", default="1-8", help="Speaker classes used for mean/std when --fit-size is set.")
    parser.add_argument("--copy-size", type=Path, help="Optional path to size file that should be copied next to the output.")
    parser.add_argument("--out-size", type=Path)
    args = parser.parse_args()

    blocks = read_block_data(args.data)
    fit_blocks = select_fit_blocks(blocks, args.fit_size, args.fit_speakers)
    frames = np.vstack(fit_blocks)
    mu = frames.mean(axis=0)
    sigma = frames.std(axis=0)
    sigma[sigma == 0] = 1.0

    out_blocks = [resample_time((block - mu) / sigma, args.time_slots) for block in blocks]
    write_block_data(out_blocks, args.out)

    if args.copy_size:
        out_size = args.out_size or args.out.with_suffix(args.out.suffix + ".size")
        out_size.write_text(args.copy_size.read_text(encoding="utf-8"), encoding="utf-8")

    print(f"wrote,{args.out}")
    print(f"n_samples,{len(out_blocks)}")
    print(f"n_features,{out_blocks[0].shape[1]}")
    print(f"fit_samples,{len(fit_blocks)}")


if __name__ == "__main__":
    main()
