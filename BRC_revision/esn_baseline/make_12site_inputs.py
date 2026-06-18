#!/usr/bin/env python3
"""
用途：从 standardized_12slot.txt 生成「12 位点 top-1 / top-2」刺激编码文本，作为 ESN 基线的新增输入变体。
      12 个 LPC 通道各对应一个刺激位点（不压缩到 6，更接近郭峰 Brainoware 的 12 电极方案），逐时间步取绝对值后
      选 top-k 位点置 1。与六位点编码同源（同一份 standardized_12slot），仅位点数与是否压缩不同。
输入：FC_DIR/standardized_12slot.txt（240 样本 × 12 步 × 12 维，已 z-score）。
输出：FC_DIR/top1_12site.txt、FC_DIR/top2_12site.txt（每样本 12 步 × 12 位点的 0/1 编码；padding 步全 0）。
数据流：standardized_12slot → 取绝对值 → 逐时间步 top-k 置 1 → 写块文本。
操作流：python make_12site_inputs.py（跑一次生成文本；之后 run_esn_baseline.py 直接读）。
"""
from __future__ import annotations

import numpy as np

import config
from data_io import read_block_data


def topk_abs_block(block: np.ndarray, k: int) -> np.ndarray:
    """逐行（时间步）取绝对值后选 top-k 位点置 1，其余 0；全零行（padding）保持全 0。"""
    out = np.zeros(block.shape, dtype=int)
    mag = np.abs(block)
    for i, row in enumerate(mag):
        if np.all(row < 1e-12):
            continue
        order = np.argsort(row)[::-1]
        out[i, order[:k]] = 1
    return out


def write_blocks(blocks: list[np.ndarray], path) -> None:
    lines: list[str] = []
    for b in blocks:
        for row in b:
            lines.append(" ".join(str(int(v)) for v in row))
        lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    src = config.FC_DIR / "standardized_12slot.txt"
    blocks = read_block_data(src)
    for k, name in [(1, "top1_12site.txt"), (2, "top2_12site.txt")]:
        out = [topk_abs_block(b, k) for b in blocks]
        write_blocks(out, config.FC_DIR / name)
        print(f"wrote {name}: {len(out)} samples, sites={out[0].shape[1]}, k={k}")


if __name__ == "__main__":
    main()
