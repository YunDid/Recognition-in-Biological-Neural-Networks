#!/usr/bin/env python3
"""
用途：对比「读出层(ridge=PyRCN式 vs 线性SVM=我们的)」与「reservoir 参数(我们当前 vs PyRCN默认)」对 ESN
      准确率的影响，判断是否需要真正采用 PyRCN——若 C(PyRCN式) 与 A(我们的) 基本一致，则无需 PyRCN，
      回复信文字说明参数与郭峰一致即可。reservoir 固定 32 单元（对齐生物读出通道）。
      PyRCN 的 ESNClassifier 在 sklearn 1.9 上 .fit() 不通，故用 sklearn 的 ridge 作其读出的等价实现。
输入：config.py 的六个输入变体 + size_ae.train。
输出：终端三列对照 + results/pyrcn_compare.xlsx / .csv。
三种配置（均 reservoir=32、5 个随机种子取 mean±std、分层 5 折、同一划分 seed）：
  A 我们当前      = reservoir(谱半径0.9, 泄漏0.3, 稀疏0.1) + 线性SVM 读出
  B 对齐reservoir = reservoir(谱半径1.0, 泄漏1.0, 稠密1.0 = PyRCN默认) + 线性SVM 读出
  C PyRCN式       = reservoir(=PyRCN默认) + ridge 读出(RidgeClassifierCV 自动选正则)
操作流：python run_pyrcn_compare.py
"""
from __future__ import annotations

import numpy as np
import pandas as pd
from sklearn.linear_model import RidgeClassifierCV
from sklearn.svm import SVC

import config
from data_io import (
    make_folds,
    parse_speakers,
    read_labeled_samples,
    standardize_train_test,
)
from esn_core import ESN

SIZE = 32
SEEDS = config.ESN["reservoir_seeds"]


def evaluate(features, labels, folds, clf_factory):
    accs = []
    for fold_id, test_idx in enumerate(folds):
        train_idx = np.asarray(
            [i for k, f in enumerate(folds) if k != fold_id for i in f], dtype=int
        )
        x_tr, x_te = standardize_train_test(features[train_idx], features[test_idx])
        clf = clf_factory()
        clf.fit(x_tr, labels[train_idx])
        accs.append(float(np.mean(clf.predict(x_te) == labels[test_idx])))
    return float(np.mean(accs))


def esn_acc(samples, labels, folds, rho, leak, density, clf_factory):
    n_in = samples[0].shape[1]
    seed_accs = []
    for seed in SEEDS:
        esn = ESN(n_in, SIZE, rho, 1.0, leak, density, seed)
        feats = esn.transform(samples)
        seed_accs.append(evaluate(feats, labels, folds, clf_factory))
    return float(np.mean(seed_accs)), float(np.std(seed_accs))


def svm_factory():
    return SVC(kernel="linear", C=1.0)


def ridge_factory():
    return RidgeClassifierCV(alphas=np.logspace(-2, 3, 10))


def main():
    config.RESULT_DIR.mkdir(parents=True, exist_ok=True)
    selected = parse_speakers(config.SELECTED_SPEAKERS)
    folds = None
    rows = []
    for tag, (path, cn) in config.INPUT_VARIANTS.items():
        samples, labels = read_labeled_samples(path, config.SIZE_FILE, selected)
        if folds is None:
            folds = make_folds(labels, config.CV["n_fold"], config.CV["seed"])
        aA, sA = esn_acc(samples, labels, folds, 0.9, 0.3, 0.1, svm_factory)
        aB, sB = esn_acc(samples, labels, folds, 1.0, 1.0, 1.0, svm_factory)
        aC, sC = esn_acc(samples, labels, folds, 1.0, 1.0, 1.0, ridge_factory)
        print(f"[{cn}]  A我们 {aA:.4f}±{sA:.4f} | B对齐reservoir+SVM {aB:.4f}±{sB:.4f} | C PyRCN式 {aC:.4f}±{sC:.4f}  (C−A {aC - aA:+.4f})")
        rows.append({
            "输入类型": cn,
            "A_我们当前(rho0.9_leak0.3_SVM)": round(aA, 4),
            "B_对齐reservoir_SVM(rho1.0_leak1.0)": round(aB, 4),
            "C_PyRCN式(对齐reservoir_ridge)": round(aC, 4),
            "C减A": round(aC - aA, 4),
            "reservoir规模": SIZE,
        })
    df = pd.DataFrame(rows)
    df.to_csv(config.RESULT_DIR / "pyrcn_compare.csv", index=False, encoding="utf-8-sig")
    df.to_excel(config.RESULT_DIR / "pyrcn_compare.xlsx", index=False)
    print("\n=== 对照(reservoir=32) ===")
    print(df.to_string(index=False))


if __name__ == "__main__":
    main()
