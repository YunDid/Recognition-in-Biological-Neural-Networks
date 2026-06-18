#!/usr/bin/env python3
"""
用途：ESN 基线的数据读取与划分工具。函数逻辑与 ../japanese_vowels_feature_check/05_classify_svm.py
      逐字一致（同样的分层折与同样的 seed），确保 ESN 结果与既有线性 SVM 地板线落在同一划分上、可直接对比。
输入：块文本特征文件（每条样本=若干行，样本间用空行分隔，每行=一个时间步的特征向量）+ size_ae.train。
输出：read_labeled_samples → (samples:list[np.ndarray(T,F)], labels:np.ndarray)；
      make_folds → 折索引列表；standardize_train_test → 标准化后的训练/测试矩阵。
数据流：特征文本 → read_labeled_samples → make_folds → run_esn_baseline.evaluate。
操作流：被 run_esn_baseline.py import，无需单独运行。
"""
from __future__ import annotations

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


def read_labeled_samples(
    data_path: Path, size_path: Path, selected: set[int]
) -> tuple[list[np.ndarray], np.ndarray]:
    blocks = read_block_data(data_path)
    sizes = [int(x) for x in size_path.read_text(encoding="utf-8").split()]
    if len(blocks) != sum(sizes):
        raise ValueError(f"解析到 {len(blocks)} 条样本，但 size 文件期望 {sum(sizes)} 条。")

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


def standardize_train_test(
    x_train: np.ndarray, x_test: np.ndarray
) -> tuple[np.ndarray, np.ndarray]:
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
    """项目既有的一对多线性 SVM（squared hinge 损失、全批量梯度），逐字复用自 05_classify_svm.py，
    即生物侧八分类分析使用的同一读出层。输入需已标准化。"""
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
