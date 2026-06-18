#!/usr/bin/env python3
"""Run stratified 5-fold linear SVM classification on same-shape block data.

This script intentionally uses only numpy. It implements a simple one-vs-rest
linear SVM with squared hinge loss, sufficient for checking whether a feature
representation preserves speaker-discriminative information.

Input samples must all have the same shape. Raw variable-length Japanese Vowels
utterances should first be converted with 02_standardize_dataset.py or another
fixed-time-slot transform.
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


def make_folds(labels: np.ndarray, n_fold: int, seed: int) -> list[np.ndarray]:
    rng = np.random.default_rng(seed)
    folds: list[list[int]] = [[] for _ in range(n_fold)]
    for label in sorted(set(labels.tolist())):
        idx = np.where(labels == label)[0]
        idx = rng.permutation(idx)
        chunks = np.array_split(idx, n_fold)
        for fold_id, chunk in enumerate(chunks):
            folds[fold_id].extend(chunk.tolist())
    return [np.asarray(sorted(fold), dtype=int) for fold in folds]


def flatten_samples(samples: list[np.ndarray]) -> np.ndarray:
    shapes = {sample.shape for sample in samples}
    if len(shapes) != 1:
        raise ValueError(
            "Linear SVM requires same-shape samples. "
            f"Got shapes: {sorted(shapes)}. Convert raw variable-length data to fixed slots first."
        )
    return np.vstack([sample.ravel() for sample in samples])


def standardize_train_test(x_train: np.ndarray, x_test: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    mu = x_train.mean(axis=0)
    sigma = x_train.std(axis=0)
    sigma[sigma < 1e-12] = 1.0
    return (x_train - mu) / sigma, (x_test - mu) / sigma


def svm_ovr_predict(
    x_train: np.ndarray,
    y_train: np.ndarray,
    x_test: np.ndarray,
    labels: list[int],
    c_value: float,
    epochs: int,
    lr: float,
) -> np.ndarray:
    x_train_b = np.c_[np.ones(x_train.shape[0]), x_train]
    x_test_b = np.c_[np.ones(x_test.shape[0]), x_test]
    reg_mask = np.ones(x_train_b.shape[1])
    reg_mask[0] = 0.0

    weights = np.zeros((len(labels), x_train_b.shape[1]))
    n_train = x_train_b.shape[0]

    for class_idx, label in enumerate(labels):
        y_binary = np.where(y_train == label, 1.0, -1.0)
        w = np.zeros(x_train_b.shape[1])
        for _ in range(epochs):
            margin = y_binary * (x_train_b @ w)
            active = margin < 1.0
            grad = w * reg_mask
            if np.any(active):
                grad += c_value * (-2.0 / n_train) * (
                    x_train_b[active].T @ (y_binary[active] * (1.0 - margin[active]))
                )
            w -= lr * grad
        weights[class_idx] = w

    scores = x_test_b @ weights.T
    return np.asarray([labels[i] for i in scores.argmax(axis=1)], dtype=int)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", required=True, type=Path)
    parser.add_argument("--size", required=True, type=Path)
    parser.add_argument("--selected-speakers", default="1-8")
    parser.add_argument("--folds", type=int, default=5)
    parser.add_argument("--seed", type=int, default=20260501)
    parser.add_argument("--c", type=float, default=1.0)
    parser.add_argument("--epochs", type=int, default=400)
    parser.add_argument("--lr", type=float, default=0.05)
    args = parser.parse_args()

    samples, labels = read_labeled_samples(args.data, args.size, parse_speakers(args.selected_speakers))
    x_all = flatten_samples(samples)
    folds = make_folds(labels, args.folds, args.seed)
    class_labels = sorted(set(labels.tolist()))

    accuracies: list[float] = []
    for fold_id, test_idx in enumerate(folds, start=1):
        train_idx = np.asarray([i for k, fold in enumerate(folds, start=1) if k != fold_id for i in fold], dtype=int)
        x_train, x_test = standardize_train_test(x_all[train_idx], x_all[test_idx])
        pred = svm_ovr_predict(x_train, labels[train_idx], x_test, class_labels, args.c, args.epochs, args.lr)
        acc = float(np.mean(pred == labels[test_idx]))
        accuracies.append(acc)

    print(f"n_samples,{len(samples)}")
    print(f"n_classes,{len(class_labels)}")
    print(f"folds,{args.folds}")
    print(f"c,{args.c}")
    print(f"mean_accuracy,{np.mean(accuracies):.6f}")
    print("fold_accuracies," + ",".join(f"{value:.6f}" for value in accuracies))


if __name__ == "__main__":
    main()
