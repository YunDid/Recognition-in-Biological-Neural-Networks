# hub_rescue_stats.py
# 任务B：当下数据上 hub 节点指标的统计学差异 + 参数扫描（能否调出更显著趋势以保留 hub 内容）
# 复用 param_sweep_analysis.py 已验证的指标函数（baseline 已对截图逐数核验通过）。
# 运行：python hub_rescue_stats.py
import numpy as np
from scipy.stats import wilcoxon, binomtest
from param_sweep_analysis import (load_full, w1_subgraph, mean_nz_full, node_metrics,
                                   DESIGNATION, ORDER)

THR = 0.35

def thr_of(a, top):
    g = int(min(max(round(top * len(a)), 1), len(a)))
    return np.sort(a)[::-1][g - 1]

def hub_avg(target, pool, third, top):
    aS = np.concatenate([p['mean_str'] for p in pool])
    aE = np.concatenate([p['eloc'] for p in pool])
    a3 = np.concatenate([p[third] for p in pool])
    thS, thE, th3 = thr_of(aS, top), thr_of(aE, top), thr_of(a3, top)
    h = (target['mean_str'] >= thS).astype(int) + (target['eloc'] >= thE).astype(int) + (target[third] >= th3).astype(int)
    return h.sum() / len(target['mean_str'])

def compute_hub_table(third, top):
    """返回每盘每 post 的 (hub_pre, hub_act, hub_scl)。"""
    rows = []
    for cell in ORDER:
        pre, posts = DESIGNATION[cell]
        nm = {}; W1 = {}; mnz = {}
        for s in [pre] + posts:
            A, _ = load_full(cell, s)
            W1[s] = w1_subgraph(A, THR); mnz[s] = mean_nz_full(A, THR)
            nm[s] = node_metrics(W1[s])
        pool = [nm[s] for s in [pre] + posts]
        hub_pre = hub_avg(nm[pre], pool, third, top)
        for k, t in enumerate(posts, 1):
            kS = mnz[t] / mnz[pre] if mnz[pre] > 0 else 1.0
            nm_scl = node_metrics(W1[pre] * kS)
            rows.append(dict(cell=cell, post=k, hub_pre=hub_pre,
                             hub_act=hub_avg(nm[t], pool, third, top),
                             hub_scl=hub_avg(nm_scl, pool, third, top), kS=kS))
    return rows

def paired_report(label, x, y, alt_greater=True):
    """x=实测, y=对照; 检验 x-y 的方向与显著性。"""
    d = np.array(x) - np.array(y)
    pos = int((d > 0).sum()); neg = int((d < 0).sum()); zero = int((d == 0).sum())
    nz = d[d != 0]
    out = f'{label}: n={len(d)}  实测−对照 均值={d.mean():+.4f}  正/负/零={pos}/{neg}/{zero}'
    try:
        w2 = wilcoxon(nz, alternative='two-sided').pvalue
        out += f'  Wilcoxon双侧 p={w2:.4f}'
        if alt_greater:
            wg = wilcoxon(nz, alternative='greater').pvalue
            out += f'  单侧(实测>对照) p={wg:.4f}'
    except Exception as e:
        out += f'  [Wilcoxon 失败: {e}]'
    # 符号检验（二项）
    if pos + neg > 0:
        bp = binomtest(pos, pos + neg, 0.5, alternative='greater' if alt_greater else 'two-sided').pvalue
        out += f'  符号检验 p={bp:.4f}'
    return out

def main():
    print('=' * 70)
    print('A) 当下数据 hub 残差(实测−缩放) 统计检验  [hub_top=0.40]')
    print('=' * 70)
    for third in ['cloc', 'bc']:
        rows = compute_hub_table(third, 0.40)
        act = [r['hub_act'] for r in rows]; scl = [r['hub_scl'] for r in rows]
        pre = [r['hub_pre'] for r in rows]
        print(f'\n--- node_3rd = {third} ---')
        print(paired_report('  实测 vs 缩放(全18对)', act, scl))
        # 分 post
        a1 = [r['hub_act'] for r in rows if r['post'] == 1]; s1 = [r['hub_scl'] for r in rows if r['post'] == 1]
        a2 = [r['hub_act'] for r in rows if r['post'] == 2]; s2 = [r['hub_scl'] for r in rows if r['post'] == 2]
        print(paired_report('  实测 vs 缩放(post1,9盘)', a1, s1))
        print(paired_report('  实测 vs 缩放(post2,9盘)', a2, s2))
        # hub 到底有没有随训练变（实测 post vs pre）
        print(paired_report('  实测post vs pre(hub有无变化)', act, pre, alt_greater=False))

    print('\n' + '=' * 70)
    print('B) 参数扫描：node_3rd × hub_top 对 实测>缩放 残差显著性的影响')
    print('   (看是否存在能把 hub 调显著的参数；同时警惕多重比较钓 p 值)')
    print('=' * 70)
    print(f'{"node_3rd":8} {"hub_top":7} {"残差均值":>9} {"正/负":>7} {"Wilcoxon单侧p":>14} {"符号检验p":>10}')
    for third in ['cloc', 'bc']:
        for top in [0.20, 0.30, 0.40, 0.50]:
            rows = compute_hub_table(third, top)
            d = np.array([r['hub_act'] for r in rows]) - np.array([r['hub_scl'] for r in rows])
            pos = int((d > 0).sum()); neg = int((d < 0).sum()); nz = d[d != 0]
            try:
                wg = wilcoxon(nz, alternative='greater').pvalue
            except Exception:
                wg = np.nan
            bp = binomtest(pos, pos + neg, 0.5, alternative='greater').pvalue if pos + neg else np.nan
            print(f'{third:8} {top:<7.2f} {d.mean():>+9.4f} {f"{pos}/{neg}":>7} {wg:>14.4f} {bp:>10.4f}')

if __name__ == '__main__':
    main()
