# scaling_kS_variants.py
# 任务2：重跑 main_network_scaling_control.m 的指标，但把"一开始 kS 的计算"按不同预处理变体分别出表。
#   整体管线不变（W1 子图 → scaled=W1pre×kS → CC/CPL/Eglob/Hub + 残差），只动 kS 口径：
#     · 负值处理 neg : zero(清零,现口径) | abs(取绝对值) | signed(带符号,仅入均值;指标矩阵仍清负)
#     · 零值处理 zero: nz(非零边均值=k2,现口径) | all(含被清零边的全阵均值=k1)
#     · 阈值 thr     : 0.10 / 0.20 / 0.35 / 0.50 多个
#   负值+零值合成 4 个"配方"(recipe)，每配方一个 Excel(阈值=各 sheet)，外加 1 个 master 汇总。
# 复用 param_sweep_analysis.py 已对截图核验的指标函数。运行：python scaling_kS_variants.py
import os
import numpy as np
import scipy.io as sio
from openpyxl import Workbook
from param_sweep_analysis import (w1_subgraph, node_metrics, cc_onnela, cpl, eglob,
                                   write_metrics_sheet, rnd, DESIGNATION, ORDER, MERGED, HUB_TOP)

OUTDIR = os.path.join(MERGED, 'param_sweep', 'kS_variants')
os.makedirs(OUTDIR, exist_ok=True)

# 配方：负值+零值作为一个分类变量的 4 个水平
RECIPES = {
    'clip0_nz':  dict(metric_neg='zero', mean_neg='zero',   mean_zero='nz',  desc='清零+非零均值(现口径k2)'),
    'clip0_all': dict(metric_neg='zero', mean_neg='zero',   mean_zero='all', desc='清零+含零全阵均值(k1)'),
    'abs_nz':    dict(metric_neg='abs',  mean_neg='abs',    mean_zero='nz',  desc='绝对值+非零均值'),
    'signed_nz': dict(metric_neg='zero', mean_neg='signed', mean_zero='nz',  desc='带符号均值(指标仍清负)'),
}
THRS = [0.10, 0.20, 0.35, 0.50]

def load_raw(cell, s):
    d = sio.loadmat(f'{MERGED}\\{cell}\\sttc\\sttc-spikes_spon{s}.mat')
    A = np.array(d['adjM'], float); A[np.isnan(A)] = 0.0
    return A   # 不清负，由配方决定

def metric_W1(A_raw, neg, thr):
    A = A_raw.copy()
    if neg == 'zero':
        A[A < 0] = 0.0
    elif neg == 'abs':
        A = np.abs(A)
    return w1_subgraph(A, thr)

def k_mean(A_raw, thr, mean_neg, mean_zero):
    A = A_raw.copy()
    if mean_neg == 'zero':
        A[A < 0] = 0.0; mag = A; val = A
    elif mean_neg == 'abs':
        A = np.abs(A); mag = A; val = A
    else:  # signed：存在性按 |值| 判，入均值用带符号值
        mag = np.abs(A); val = A
    N = A.shape[0]; off = ~np.eye(N, dtype=bool)
    present = (mag >= thr) & off
    if mean_zero == 'nz':
        v = val[present]
        return v.mean() if v.size else 0.0
    else:  # all：含被清零边(=0)的全阵非对角均值
        m = np.where(present, val, 0.0)
        return m[off].mean()

def hub_avg(target, pool, third='cloc'):
    aS = np.concatenate([p['mean_str'] for p in pool])
    aE = np.concatenate([p['eloc'] for p in pool])
    a3 = np.concatenate([p[third] for p in pool])
    def thr_(a):
        g = int(min(max(round(HUB_TOP * len(a)), 1), len(a))); return np.sort(a)[::-1][g - 1]
    thS, thE, th3 = thr_(aS), thr_(aE), thr_(a3)
    h = (target['mean_str'] >= thS).astype(int) + (target['eloc'] >= thE).astype(int) + (target[third] >= th3).astype(int)
    return h.sum() / len(target['mean_str'])

def compute_dish(cell, thr, recipe):
    r = RECIPES[recipe]
    pre, posts = DESIGNATION[cell]
    stages = [pre] + posts
    W1 = {}; km = {}; nm = {}
    for s in stages:
        A = load_raw(cell, s)
        W1[s] = metric_W1(A, r['metric_neg'], thr)
        km[s] = k_mean(A, thr, r['mean_neg'], r['mean_zero'])
        nm[s] = node_metrics(W1[s])
    pool = [nm[s] for s in stages]
    out = dict(cell=cell, pre=pre, post1=posts[0], post2=posts[1])
    Wpre = W1[pre]
    for metric, fn in [('CC', cc_onnela), ('CPL', cpl), ('Eglob', eglob)]:
        out[metric + '_pre'] = fn(Wpre)
    out['Hub_pre'] = hub_avg(nm[pre], pool)
    out['meanSTTC_pre'] = km[pre]
    for k, t in enumerate(posts, 1):
        kS = km[t] / km[pre] if km[pre] != 0 else np.nan
        scaled = Wpre * kS if np.isfinite(kS) else Wpre
        out[f'kS_p{k}'] = kS
        out[f'meanSTTC_p{k}'] = km[t]
        for metric, fn in [('CC', cc_onnela), ('CPL', cpl), ('Eglob', eglob)]:
            act, scl = fn(W1[t]), fn(scaled)
            out[f'{metric}_p{k}_act'] = act
            out[f'{metric}_p{k}_scl'] = scl
            out[f'{metric}_p{k}_res'] = act - scl
        nm_scl = node_metrics(scaled)
        ha, hs = hub_avg(nm[t], pool), hub_avg(nm_scl, pool)
        out[f'Hub_p{k}_act'] = ha; out[f'Hub_p{k}_scl'] = hs; out[f'Hub_p{k}_res'] = ha - hs
    return out

def dish_density(cell, thr, recipe):
    A = load_raw(cell, DESIGNATION[cell][0]); w = metric_W1(A, RECIPES[recipe]['metric_neg'], thr)
    N = w.shape[0]; return (w > 0).sum() / (N * (N - 1)) if N > 1 else 0.0

def main():
    master = []
    for recipe in RECIPES:
        wb = Workbook(); first = True
        for thr in THRS:
            rows = [compute_dish(c, thr, recipe) for c in ORDER]
            ws = wb.active if first else wb.create_sheet()
            ws.title = f'thr_{thr:.2f}'; first = False
            write_metrics_sheet(ws, rows)
            # 汇总统计
            def col(metric, suf):
                v = [r[f'{metric}_p{k}_{suf}'] for r in rows for k in (1, 2)]
                return np.array([x for x in v if x is not None and np.isfinite(x)], float)
            kS_all = np.array([r[f'kS_p{k}'] for r in rows for k in (1, 2) if np.isfinite(r[f'kS_p{k}'])])
            cc_res = col('CC', 'res')
            master.append(dict(
                配方=recipe, 说明=RECIPES[recipe]['desc'], 阈值=thr,
                W1平均密度=round(np.mean([dish_density(c, thr, recipe) for c in ORDER]), 3),
                kS均值=round(kS_all.mean(), 4), kS最小=round(kS_all.min(), 4), kS最大=round(kS_all.max(), 4),
                CC残差均=round(cc_res.mean(), 4), CC残差均绝=round(np.abs(cc_res).mean(), 4),
                CC实测大于缩放=int((cc_res > 0).sum()),
                Eglob残差均绝=round(np.abs(col('Eglob', 'res')).mean(), 4),
                CPL残差均绝=round(np.abs(col('CPL', 'res')).mean(), 4),
                Hub残差均=round(col('Hub', 'res').mean(), 4),
            ))
            print(f'[{recipe:10}] thr={thr:.2f} 密度={master[-1]["W1平均密度"]:.3f} '
                  f'kS={master[-1]["kS均值"]:.3f}[{master[-1]["kS最小"]:.2f},{master[-1]["kS最大"]:.2f}] '
                  f'CC残差均绝={master[-1]["CC残差均绝"]:.4f} Hub残差均={master[-1]["Hub残差均"]:+.3f}')
        wb.save(os.path.join(OUTDIR, f'scaling_{recipe}.xlsx'))

    # master 汇总
    import pandas as pd
    df = pd.DataFrame(master)
    df.to_excel(os.path.join(OUTDIR, 'scaling_kS_master_compare.xlsx'), index=False, sheet_name='各参数对比')
    print('\n全部写到：', OUTDIR)
    print('\n=== master 汇总（不同 kS 口径 × 阈值 下的结果变化）===')
    print(df.to_string(index=False))

if __name__ == '__main__':
    main()
