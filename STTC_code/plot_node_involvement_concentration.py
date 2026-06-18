# plot_node_involvement_concentration.py
# 用途：把"电极卷入度集中在少数电极"画成集中度曲线(降序洛伦兹曲线)，配合 R1[4] 节点层面回复。
#   X = 电极占比(按卷入度从高到低排序)；Y = 这些电极累计承担的连接变化占比。
#   对角线 = 均匀参与(人人一样)。曲线鼓出对角线越多 = 越集中。曲线上 X=0.25 处的 Y 即"前25%电极占比"。
#   每盘一条细线(看离散)，9盘平均一条粗线，并标注前25%锚点与基尼系数。
# 运行：python plot_node_involvement_concentration.py   → 输出 node_involvement_concentration.png/pdf
# 输入：复用 param_sweep_analysis 的 load_full_symm/DESIGNATION/ORDER；判定口径 τ=0.35 δ=0.10，pre→post2。
import os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from param_sweep_analysis import load_full_symm, DESIGNATION, ORDER, OUTDIR

TAU, DELTA = 0.35, 0.10


def involvement(cell, t):
    Wpre, actPre = load_full_symm(cell, DESIGNATION[cell][0])
    Wpost, actPost = load_full_symm(cell, t)
    common = np.intersect1d(actPre, actPost)
    common = common[(common >= 1) & (common <= Wpre.shape[0])]
    idx = common - 1
    a = Wpre[np.ix_(idx, idx)]; b = Wpost[np.ix_(idx, idx)]
    m = idx.size; inv = np.zeros(m, int)
    for ii in range(m - 1):
        for jj in range(ii + 1, m):
            av, bv = a[ii, jj], b[ii, jj]
            ppre, ppost = av >= TAU, bv >= TAU
            ch = False
            if ppre and ppost:
                ch = abs(bv - av) > DELTA
            elif (not ppre) and ppost and bv >= TAU + DELTA:
                ch = True
            elif ppre and (not ppost) and av >= TAU + DELTA:
                ch = True
            if ch:
                inv[ii] += 1; inv[jj] += 1
    return inv


def conc_curve(inv, grid):
    """降序集中度曲线：x=电极累计占比, y=卷入累计占比，插值到 grid。"""
    v = np.sort(inv.astype(float))[::-1]
    n = v.size; s = v.sum()
    if s == 0:
        return np.zeros_like(grid)
    x = np.concatenate([[0.0], np.arange(1, n + 1) / n])
    y = np.concatenate([[0.0], np.cumsum(v) / s])
    return np.interp(grid, x, y)


def gini(inv):
    x = np.sort(inv.astype(float)); n = x.size; s = x.sum()
    if n == 0 or s == 0:
        return 0.0
    i = np.arange(1, n + 1)
    return (2.0 * (i * x).sum()) / (n * s) - (n + 1.0) / n


def main():
    grid = np.linspace(0, 1, 201)
    curves, ginis = [], []
    fig, ax = plt.subplots(figsize=(5.2, 5.0))
    for cell in ORDER:
        inv = involvement(cell, DESIGNATION[cell][1][1])   # post2
        c = conc_curve(inv, grid)
        curves.append(c); ginis.append(gini(inv))
        ax.plot(grid, c, color='0.75', lw=0.8, zorder=1)
    mean_c = np.mean(curves, axis=0)
    ax.plot(grid, mean_c, color='#c0392b', lw=2.6, zorder=3, label='Mean of 9 cultures')
    ax.plot([0, 1], [0, 1], '--', color='0.4', lw=1.2, zorder=2, label='Uniform participation')
    # 前25%锚点
    y25 = np.interp(0.25, grid, mean_c)
    ax.plot([0.25, 0.25], [0, y25], ':', color='#2c3e50', lw=1.0)
    ax.plot([0, 0.25], [y25, y25], ':', color='#2c3e50', lw=1.0)
    ax.scatter([0.25], [y25], color='#2c3e50', zorder=4, s=28)
    ax.annotate(f'top 25% of electrodes\n→ {y25*100:.0f}% of changes\n(uniform: 25%)',
                xy=(0.25, y25), xytext=(0.34, y25 - 0.20),
                fontsize=9, color='#2c3e50',
                arrowprops=dict(arrowstyle='->', color='#2c3e50', lw=0.9))
    ax.text(0.97, 0.06, f'Gini = {np.mean(ginis):.2f}', ha='right', fontsize=10, color='#c0392b')
    ax.set_xlabel('Fraction of electrodes (ranked most→least involved)')
    ax.set_ylabel('Cumulative share of connection changes')
    ax.set_title('Node involvement in rewiring is concentrated\nin a minority of electrodes (pre→post2)', fontsize=10)
    ax.set_xlim(0, 1); ax.set_ylim(0, 1)
    ax.set_aspect('equal'); ax.legend(loc='upper left', fontsize=8, frameon=False)
    ax.grid(alpha=0.25)
    fig.tight_layout()
    png = os.path.join(OUTDIR, 'node_involvement_concentration.png')
    fig.savefig(png, dpi=160); fig.savefig(png.replace('.png', '.pdf'))
    print('top25% mean =', round(y25 * 100, 1), '%   Gini mean =', round(np.mean(ginis), 3))
    print('已写出:', png)


if __name__ == '__main__':
    main()
