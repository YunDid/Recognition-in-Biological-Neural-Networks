# unweighted_cc_curve.py
# 无权(Watts-Strogatz)CC 的 pre / post1 / post2 三点曲线 + 三段配对检验(对齐图2C的三根星号)。
# 无权 CC 对整体权重缩放严格免疫，其上升=新三角形形成=结构重组（排除幅值依赖）。
# 多阈值对比：0.35(图2C阈值,近全连接易封顶) vs 强连接骨架 0.45/0.50/0.55。
# 产出 Excel：每阈值一 sheet(逐盘 pre/post1/post2，供 GraphPad 画配对点图) + 统计汇总 sheet。
import os
import numpy as np
from scipy.stats import wilcoxon
import pandas as pd
from param_sweep_analysis import w1_subgraph, load_full, cc_onnela, DESIGNATION, ORDER, MERGED

OUT = os.path.join(MERGED, 'param_sweep', 'unweighted_CC_pre_post1_post2.xlsx')
THRS = [0.35, 0.45, 0.50, 0.55]

def ucc(W):
    return cc_onnela((W > 0).astype(float))   # 二值化后的 Onnela = 无权 CC

def stars(p):
    if p != p: return 'ns'
    if p < 0.001: return '***'
    if p < 0.01: return '**'
    if p < 0.05: return '*'
    if p < 0.10: return '·'
    return 'ns'

def pair(a, b):  # b 相对 a 是否升高
    d = np.array(b) - np.array(a); nz = d[d != 0]
    p = wilcoxon(nz, alternative='greater').pvalue if nz.size else np.nan
    return d.mean(), p, int((d > 0).sum()), int((d < 0).sum())

def main():
    stat_rows = []
    with pd.ExcelWriter(OUT) as writer:
        for thr in THRS:
            rows = []
            for c in ORDER:
                pre, posts = DESIGNATION[c]
                up = ucc(w1_subgraph(load_full(c, pre)[0], thr))
                u1 = ucc(w1_subgraph(load_full(c, posts[0])[0], thr))
                u2 = ucc(w1_subgraph(load_full(c, posts[1])[0], thr))
                rows.append(dict(盘=c, 无权CC_pre=round(up, 4), 无权CC_post1=round(u1, 4), 无权CC_post2=round(u2, 4)))
            df = pd.DataFrame(rows)
            df.to_excel(writer, sheet_name=f'thr_{thr:.2f}', index=False)
            pre = df['无权CC_pre'].values; p1 = df['无权CC_post1'].values; p2 = df['无权CC_post2'].values
            for lab, a, b in [('pre→post1', pre, p1), ('pre→post2', pre, p2), ('post1→post2', p1, p2)]:
                m, p, pos, neg = pair(a, b)
                stat_rows.append(dict(阈值=thr, 对比=lab, Δ均=round(m, 4),
                                      pre均=round(np.mean(a), 4), post均=round(np.mean(b), 4),
                                      正负=f'{pos}/{neg}', p单侧=round(p, 4) if p == p else None, 显著=stars(p)))
        pd.DataFrame(stat_rows).to_excel(writer, sheet_name='配对检验汇总', index=False)
    print('已写出：', OUT)
    print(f'\n{"阈值":>5}{"对比":>12}{"pre均":>8}{"post均":>8}{"Δ均":>9}{"正/负":>7}{"p单侧":>9}{"显著":>5}')
    for r in stat_rows:
        print(f'{r["阈值"]:>5.2f}{r["对比"]:>12}{r["pre均"]:>8.4f}{r["post均"]:>8.4f}{r["Δ均"]:>+9.4f}{r["正负"]:>7}{(r["p单侧"] if r["p单侧"] is not None else float("nan")):>9.4f}{r["显著"]:>5}')

if __name__ == '__main__':
    main()
