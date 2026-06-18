#!/usr/bin/env python3
"""
用途：Japanese Vowels 八分类「人工储备池（ESN，回声状态网络）基线」的集中配置。
      被 run_esn_baseline.py import；调实验参数只动本文件。
输入：无（纯参数）。下方写死的是已生成的特征产物与 size 文件的物理路径。
输出：无（提供常量与字典供主脚本读取）。
数据流：本文件 → run_esn_baseline.py 取路径与超参数 → 加载特征文本 → ESN → 读出 → results/。
操作流：迁机器只改 REPO 一处 → 跑 run_esn_baseline.py。
"""
from pathlib import Path

# —— 路径（迁机器只改这一处）——
REPO = Path(r"E:\Recognition-in-Biological-Neural-Networks")
FC_DIR = REPO / "Code" / "BRC_revision" / "japanese_vowels_feature_check"
SIZE_FILE = REPO / "Data" / "japanese+vowels" / "size_ae.train"
RESULT_DIR = Path(__file__).resolve().parent / "results"

# speaker 1-8 → 240 条样本、8 类、每类 30 条
SELECTED_SPEAKERS = "1-8"

# ESN 输入变体：标签 → (特征文本文件, 中文名)
# 六位点变体与类器官（六刺激位点）实际收到的输入同形；12 位点变体每个 LPC 通道各占一个刺激位点（近郭峰 12 电极）；
# raw12 作信息上界参照。12 位点文本由 make_12site_inputs.py 生成。
INPUT_VARIANTS = {
    "raw12": (FC_DIR / "standardized_12slot.txt", "原始12维LPC(信息上界)"),
    "site6": (FC_DIR / "score6_12slot.txt", "六位点连续得分"),
    "top1_6": (FC_DIR / "top1_6site.txt", "六位点top-1"),
    "top2_6": (FC_DIR / "top2_6site.txt", "六位点top-2"),
    "top1_12": (FC_DIR / "top1_12site.txt", "12位点top-1"),
    "top2_12": (FC_DIR / "top2_12site.txt", "12位点top-2"),
}

# —— ESN 超参数（reservoir 部分对齐 Brainoware 所用 PyRCN 库的默认配置）——
# 经 run_pyrcn_compare.py 核验：PyRCN 式（ridge 读出 + 下列 PyRCN 默认 reservoir）与我们的（SVM 读出）结果基本一致
# （多数编码差异 ≤1%），故不实际采用 PyRCN，仅在我们的透明实现里对齐 reservoir 基本参数。
ESN = {
    # 32 对齐本文生物侧读出通道数（活跃电极 16 上 + 16 下）+ 同 Brainoware 的 32；其余作敏感性扫描
    "reservoir_sizes": [16, 32, 64, 128],
    "spectral_radius": 1.0,                  # 谱半径（PyRCN 默认）
    "input_scaling": 1.0,                    # 输入注入幅度（PyRCN 默认）
    "leak_rate": 1.0,                        # 漏积分率（PyRCN 默认 leakage=1.0，无泄漏）
    "density": 1.0,                          # reservoir 连接密度（PyRCN 默认 sparsity=1.0，稠密）
    "reservoir_seeds": [0, 1, 2, 3, 4],      # 多个随机 reservoir → 取 mean±std
}

# —— 交叉验证（与 05_classify_svm.py 完全一致，结果可直接并排对比）——
CV = {"n_fold": 5, "seed": 20260501}

# —— 读出层 ——
# 一对多线性 SVM：scikit-learn 的 SVC(kernel='linear')，libsvm/SMO 后端，与生物侧 MATLAB SVM 同底层，
# 在「特征多于样本」的高维 reservoir 状态上收敛稳定。
# 注：05_classify_svm.py 里手写的定步长梯度下降 SVM 在高维状态上数值发散（权重溢出成 NaN、准确率塌到随机水平），
# 且只是 feature_check 的 numpy 替身、并非生物侧实际读出；LinearSVC（liblinear）在此高维下不收敛（数偏移~12%）。
# 两者均已弃用，统一用 SVC(kernel='linear')，模型同为线性 SVM。
READOUT = {"c": 1.0}
