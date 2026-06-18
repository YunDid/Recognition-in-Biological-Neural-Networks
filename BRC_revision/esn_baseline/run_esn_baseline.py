#!/usr/bin/env python3
"""
用途：跑 Japanese Vowels 八分类的「ESN 人工储备池基线」，与「无 reservoir 地板线」「随机水平」并排对比。
      对四种输入变体 × 多个 reservoir 规模 × 多个随机 reservoir，做分层 5 折；读出层用一对多线性 SVM
      （scikit-learn SVC(kernel='linear')，libsvm 后端，与生物侧 MATLAB SVM 同底层，只差中间的 reservoir），
      报告 mean±std 准确率。
输入：config.py 指定的四个特征文本（raw12 / site6 / top1 / top2）+ size_ae.train。
输出：results/esn_baseline_summary.xlsx（中文表头）+ results/esn_baseline_summary.csv + 终端摘要表。
数据流：特征文本 → ESN 投影 → 拼接状态 → 标准化 → 线性 SVM 读出 → 5 折准确率 → 汇总表。
操作流：python run_esn_baseline.py
"""
from __future__ import annotations

import numpy as np
import pandas as pd
from sklearn.svm import SVC

import config
from data_io import (
    make_folds,
    parse_speakers,
    read_labeled_samples,
    standardize_train_test,
)
from esn_core import ESN


def evaluate(features, labels, folds, readout):
    """分层 5 折 + 一对多线性 SVM（SVC kernel=linear，libsvm）读出，返回 (平均准确率, 各折准确率)。"""
    accs: list[float] = []
    for fold_id, test_idx in enumerate(folds):
        train_idx = np.asarray(
            [i for k, fold in enumerate(folds) if k != fold_id for i in fold], dtype=int
        )
        x_tr, x_te = standardize_train_test(features[train_idx], features[test_idx])
        clf = SVC(kernel="linear", C=readout["c"])
        clf.fit(x_tr, labels[train_idx])
        pred = clf.predict(x_te)
        accs.append(float(np.mean(pred == labels[test_idx])))
    return float(np.mean(accs)), accs


def flatten(samples: list[np.ndarray]) -> np.ndarray:
    return np.vstack([s.ravel() for s in samples])


def main() -> None:
    config.RESULT_DIR.mkdir(parents=True, exist_ok=True)
    selected = parse_speakers(config.SELECTED_SPEAKERS)

    # 载入四个变体，校验样本顺序/标签一致（保证折划分在各变体间对齐）
    variants: dict[str, tuple[list[np.ndarray], np.ndarray, str]] = {}
    ref_labels: np.ndarray | None = None
    for tag, (path, cn) in config.INPUT_VARIANTS.items():
        samples, labels = read_labeled_samples(path, config.SIZE_FILE, selected)
        if ref_labels is None:
            ref_labels = labels
        elif not np.array_equal(labels, ref_labels):
            raise ValueError(f"变体 {tag} 的标签顺序与其它变体不一致，折划分无法对齐。")
        variants[tag] = (samples, labels, cn)

    assert ref_labels is not None
    labels = ref_labels
    class_labels = sorted(set(labels.tolist()))
    n_classes = len(class_labels)
    chance = 1.0 / n_classes
    folds = make_folds(labels, config.CV["n_fold"], config.CV["seed"])
    p = config.ESN
    readout = config.READOUT

    print(f"随机水平 = {chance:.4f}（{n_classes} 类）；读出层 = 线性SVM SVC(kernel=linear, C={readout['c']})")
    rows: list[dict] = []
    for tag, (samples, lab, cn) in variants.items():
        n_in = samples[0].shape[1]
        floor_mean, _ = evaluate(flatten(samples), lab, folds, readout)
        print(f"[{cn}] 样本={len(samples)} 步×维={samples[0].shape}  无reservoir地板 = {floor_mean:.4f}")
        for size in p["reservoir_sizes"]:
            seed_accs: list[float] = []
            for seed in p["reservoir_seeds"]:
                esn = ESN(
                    n_in, size, p["spectral_radius"], p["input_scaling"],
                    p["leak_rate"], p["density"], seed,
                )
                feats = esn.transform(samples)
                acc, _ = evaluate(feats, lab, folds, readout)
                seed_accs.append(acc)
            mean_acc = float(np.mean(seed_accs))
            std_acc = float(np.std(seed_accs))
            print(f"    reservoir={size:>3}  ESN = {mean_acc:.4f} ± {std_acc:.4f}  (相对地板 {mean_acc - floor_mean:+.4f})")
            rows.append({
                "输入类型": cn,
                "reservoir规模": size,
                "谱半径": p["spectral_radius"],
                "泄漏率": p["leak_rate"],
                "ESN平均准确率": round(mean_acc, 4),
                "ESN准确率标准差": round(std_acc, 4),
                "无reservoir地板准确率": round(floor_mean, 4),
                "ESN相对地板增益": round(mean_acc - floor_mean, 4),
                "随机水平准确率": round(chance, 4),
                "折数": config.CV["n_fold"],
                "reservoir随机种子数": len(p["reservoir_seeds"]),
                "样本数": len(samples),
                "类别数": n_classes,
            })

    df = pd.DataFrame(rows)
    xlsx = config.RESULT_DIR / "esn_baseline_summary.xlsx"
    csv = config.RESULT_DIR / "esn_baseline_summary.csv"
    df.to_csv(csv, index=False, encoding="utf-8-sig")
    try:
        df.to_excel(xlsx, index=False)
    except PermissionError:
        xlsx = xlsx.with_name(xlsx.stem + "_new.xlsx")
        df.to_excel(xlsx, index=False)
        print(f"[警告] esn_baseline_summary.xlsx 被占用（可能在 Excel 打开），已改写 {xlsx.name}；CSV 已正常更新。")
    print("\n=== 汇总 ===")
    print(df.to_string(index=False))
    print(f"\n已写出: {xlsx}\n已写出: {csv}")


if __name__ == "__main__":
    main()
