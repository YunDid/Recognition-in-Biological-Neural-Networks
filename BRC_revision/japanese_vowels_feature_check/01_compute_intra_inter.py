#!/usr/bin/env python3
"""Compute within-class and between-class distances for UCI block datasets.

Input format:
  - Data file: samples separated by blank lines; each row is one time frame.
  - Size file: one integer per class, matching the UCI Japanese Vowels format.

Examples:
  python 01_compute_intra_inter.py --data ae.train --size size_ae.train --metric dtw_euclidean
  python 01_compute_intra_inter.py --data standardized_12slot.txt --size size_ae.train --metric flat_euclidean
  python 01_compute_intra_inter.py --data top2_6site.txt --size size_ae.train --metric flat_hamming
"""

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


def read_labeled_samples(data_path: Path, size_path: Path, selected: set[int]) -> tuple[list[np.ndarray], np.ndarray]:
    blocks = read_block_data(data_path)
    sizes = [int(x) for x in size_path.read_text(encoding="utf-8").split()]
    if len(blocks) != sum(sizes):
        raise ValueError(f"Parsed {len(blocks)} samples, but size file expects {sum(sizes)}.")

    samples: list[np.ndarray] = []
    labels: list[int] = []
    idx = 0
    for speaker, count in enumerate(sizes, start=1):
        for _ in range(count):
            if speaker in selected:
                samples.append(blocks[idx])
                labels.append(speaker)
            idx += 1
    return samples, np.asarray(labels, dtype=int)


def zscore_flat_features(x: np.ndarray) -> np.ndarray:
    std = x.std(axis=0)
    keep = std > 1e-12
    if not np.any(keep):
        return x[:, :0]
    return (x[:, keep] - x[:, keep].mean(axis=0)) / std[keep]


def dtw_euclidean(a: np.ndarray, b: np.ndarray) -> float:
    table = np.full((len(a) + 1, len(b) + 1), np.inf, dtype=float)
    table[0, 0] = 0.0
    for i in range(1, len(a) + 1):
        ai = a[i - 1]
        for j in range(1, len(b) + 1):
            cost = float(np.linalg.norm(ai - b[j - 1]))
            table[i, j] = cost + min(table[i - 1, j], table[i, j - 1], table[i - 1, j - 1])
    return float(table[-1, -1] / (len(a) + len(b)))


def pair_distance(a: np.ndarray, b: np.ndarray, metric: str) -> float:
    if metric == "dtw_euclidean":
        return dtw_euclidean(a, b)
    if metric == "flat_euclidean":
        if a.shape != b.shape:
            raise ValueError("flat_euclidean requires all samples to have the same shape.")
        return float(np.linalg.norm(a.ravel() - b.ravel()))
    if metric == "flat_hamming":
        if a.shape != b.shape:
            raise ValueError("flat_hamming requires all samples to have the same shape.")
        return float(np.mean(a.ravel() != b.ravel()))
    raise ValueError(f"Unknown metric: {metric}")


def compute(samples: list[np.ndarray], labels: np.ndarray, metric: str, feature_zscore: bool) -> tuple[float, float, float]:
    working = samples
    if feature_zscore and metric != "dtw_euclidean":
        flat = np.vstack([x.ravel() for x in samples])
        flat = zscore_flat_features(flat)
        working = [flat[i : i + 1] for i in range(flat.shape[0])]

    intra: list[float] = []
    inter: list[float] = []
    for i in range(len(working)):
        for j in range(i + 1, len(working)):
            d = pair_distance(working[i], working[j], metric)
            if labels[i] == labels[j]:
                intra.append(d)
            else:
                inter.append(d)
    intra_mean = float(np.mean(intra))
    inter_mean = float(np.mean(inter))
    return intra_mean, inter_mean, inter_mean / intra_mean


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", required=True, type=Path)
    parser.add_argument("--size", required=True, type=Path)
    parser.add_argument("--selected-speakers", default="1-8")
    parser.add_argument("--metric", choices=["dtw_euclidean", "flat_euclidean", "flat_hamming"], default="flat_euclidean")
    parser.add_argument(
        "--feature-zscore",
        action="store_true",
        help="Z-score flattened features before flat_euclidean. Use this for scale-normalized descriptive distances.",
    )
    args = parser.parse_args()

    samples, labels = read_labeled_samples(args.data, args.size, parse_speakers(args.selected_speakers))
    intra, inter, ratio = compute(samples, labels, args.metric, args.feature_zscore)
    print(f"n_samples,{len(samples)}")
    print(f"n_classes,{len(set(labels.tolist()))}")
    print(f"metric,{args.metric}")
    print(f"intra_mean,{intra:.6f}")
    print(f"inter_mean,{inter:.6f}")
    print(f"inter_intra_ratio,{ratio:.6f}")


if __name__ == "__main__":
    main()
