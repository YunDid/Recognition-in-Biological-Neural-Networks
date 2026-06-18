#!/usr/bin/env python3
"""
用途：透明实现的回声状态网络（ESN，回声状态网络）。把一条「时间步 × 特征」的输入序列投影成 reservoir
      状态序列，方法与 PyRCN 的 ESN 一致（漏积分 tanh 神经元 + 谱半径缩放的稀疏随机递归连接），
      所有超参数显式可控、无第三方依赖（仅 numpy）。
输入：每条样本 (T, n_in) 的 numpy 数组（T=时间步数，n_in=每步特征维度）。
输出：transform() 返回 (N, T*n_res) 的特征矩阵——拼接所有时间步的 reservoir 状态，
      与生物侧「电极 × 时间」展平成读出特征的做法对齐。
数据流：输入序列 → W_in 注入 + W 递归 → 漏积分 tanh → 逐步状态 → 拼接 → 读出层。
操作流：被 run_esn_baseline.py 使用——对每个 (reservoir 规模, 随机种子) 实例化一个 ESN，再 transform 全部样本。
"""
from __future__ import annotations

import numpy as np


class ESN:
    def __init__(
        self,
        n_in: int,
        n_res: int,
        spectral_radius: float,
        input_scaling: float,
        leak_rate: float,
        density: float,
        seed: int,
    ) -> None:
        rng = np.random.default_rng(seed)
        # 输入权重：均匀分布于 [-input_scaling, input_scaling]
        self.W_in = rng.uniform(-input_scaling, input_scaling, size=(n_res, n_in))
        # 递归权重：稀疏随机，再整体缩放到指定谱半径
        W = rng.uniform(-1.0, 1.0, size=(n_res, n_res))
        W *= rng.random((n_res, n_res)) < density
        radius = float(np.max(np.abs(np.linalg.eigvals(W))))
        if radius > 0.0:
            W *= spectral_radius / radius
        self.W = W
        self.leak = float(leak_rate)
        self.n_res = int(n_res)

    def run(self, seq: np.ndarray) -> np.ndarray:
        """单条序列 (T, n_in) → reservoir 状态 (T, n_res)。"""
        h = np.zeros(self.n_res)
        states = np.empty((seq.shape[0], self.n_res))
        for t in range(seq.shape[0]):
            pre = self.W_in @ seq[t] + self.W @ h
            h = (1.0 - self.leak) * h + self.leak * np.tanh(pre)
            states[t] = h
        return states

    def transform(self, samples: list[np.ndarray]) -> np.ndarray:
        """一组样本 → (N, T*n_res) 读出特征矩阵（拼接全部时间步状态）。"""
        return np.vstack([self.run(s).ravel() for s in samples])
