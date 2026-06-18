# edge_proportions_thr05.py
# 任务3：在 τ=0.5 边权重阈值下重算四类变化边(增强/减弱/新增/修剪)，并额外给出占比。
# 口径对齐 main_edge_change.m / edge_change_summary - end.xlsx（实测臂 + 缩放对照臂），δ=0.10 不变，
# 只把"边存在阈值"从 0.35 改为 0.50。新建一个 Excel：每对比一个 sheet + 合计行。
# 运行：python edge_proportions_thr05.py
import os
import numpy as np
import scipy.io as sio
import pandas as pd
from param_sweep_analysis import DESIGNATION, ORDER, MERGED

TAU, DELTA = 0.50, 0.10
OUT = os.path.join(MERGED, 'param_sweep', 'edge_category_proportions_thr0.5.xlsx')

def load_symm(cell, s):
    d = sio.loadmat(f'{MERGED}\\{cell}\\sttc\\sttc-spikes_spon{s}.mat')
    A = np.array(d['adjM'], float); A[np.isnan(A)] = 0.0; A[A < 0] = 0.0
    A = (A + A.T) / 2.0; np.fill_diagonal(A, 0.0)
    if 'activeElectrode' in d and np.size(d['activeElectrode']) > 0:
        active = np.array(d['activeElectrode']).ravel().astype(int)
    else:
        active = np.where((A > 0).any(1))[0] + 1
    return A, active

def mean_nz(W):
    Wt = W.copy(); Wt[Wt < TAU] = 0.0; off = ~np.eye(W.shape[0], dtype=bool)
    v = Wt[off]; v = v[v > 0]; return v.mean() if v.size else 0.0

def classify(Wpre, Wpost, common):
    idx = np.array(common, int) - 1
    a = Wpre[np.ix_(idx, idx)]; b = Wpost[np.ix_(idx, idx)]; m = idx.size
    c = dict(enh=0, wkn=0, new=0, prn=0)
    for ii in range(m - 1):
        for jj in range(ii + 1, m):
            av, bv = a[ii, jj], b[ii, jj]; ppre, ppost = av >= TAU, bv >= TAU
            if not ppre and not ppost:
                continue
            if ppre and ppost:
                if bv - av > DELTA: c['enh'] += 1
                elif av - bv > DELTA: c['wkn'] += 1
            elif (not ppre) and ppost and bv >= TAU + DELTA: c['new'] += 1
            elif ppre and (not ppost) and av >= TAU + DELTA: c['prn'] += 1
    return c

def pct(x, t):
    return round(100.0 * x / t, 1) if t else 0.0

def build(post_k):
    rows = []
    for cell in ORDER:
        pre, posts = DESIGNATION[cell]
        t = posts[post_k - 1]
        Wpre, actPre = load_symm(cell, pre)
        Wpost, actPost = load_symm(cell, t)
        common = np.intersect1d(actPre, actPost)
        common = common[(common >= 1) & (common <= Wpre.shape[0])]
        o = classify(Wpre, Wpost, common)
        kS = mean_nz(Wpost) / max(mean_nz(Wpre), 1e-12)
        nul = classify(Wpre, Wpre * kS, common)
        ch = o['enh'] + o['wkn'] + o['new'] + o['prn']
        rows.append(dict(
            盘=cell, 对比=f'spon{pre}→spon{t}', 公共电极=int(common.size), kS=round(kS, 4),
            增强_实测=o['enh'], 减弱_实测=o['wkn'], 新增_实测=o['new'], 修剪_实测=o['prn'], 变化边合计=ch,
            增强占比=pct(o['enh'], ch), 减弱占比=pct(o['wkn'], ch), 新增占比=pct(o['new'], ch), 修剪占比=pct(o['prn'], ch),
            幅值类占比=pct(o['enh'] + o['wkn'], ch), 结构类占比=pct(o['new'] + o['prn'], ch),
            增强_缩放=nul['enh'], 减弱_缩放=nul['wkn'], 新增_缩放=nul['new'], 修剪_缩放=nul['prn']))
    df = pd.DataFrame(rows)
    s = {k: int(df[k].sum()) for k in ['公共电极', '增强_实测', '减弱_实测', '新增_实测', '修剪_实测', '变化边合计',
                                       '增强_缩放', '减弱_缩放', '新增_缩放', '修剪_缩放']}
    ch = s['变化边合计']
    tot = dict(盘='合计(9盘)', 对比='', kS='', **{k: s[k] for k in s},
               增强占比=pct(s['增强_实测'], ch), 减弱占比=pct(s['减弱_实测'], ch),
               新增占比=pct(s['新增_实测'], ch), 修剪占比=pct(s['修剪_实测'], ch),
               幅值类占比=pct(s['增强_实测'] + s['减弱_实测'], ch), 结构类占比=pct(s['新增_实测'] + s['修剪_实测'], ch))
    order_cols = ['盘', '对比', '公共电极', 'kS', '增强_实测', '减弱_实测', '新增_实测', '修剪_实测', '变化边合计',
                  '增强占比', '减弱占比', '新增占比', '修剪占比', '幅值类占比', '结构类占比',
                  '增强_缩放', '减弱_缩放', '新增_缩放', '修剪_缩放']
    return pd.concat([df, pd.DataFrame([tot])], ignore_index=True)[order_cols]

def main():
    with pd.ExcelWriter(OUT) as w:
        for k in (1, 2):
            build(k).to_excel(w, sheet_name=f'pre→post{k}(τ=0.5)', index=False)
    print('已写出：', OUT)
    for k in (1, 2):
        df = build(k)
        print(f'\n=== pre→post{k} (τ=0.5) 合计 ===')
        print(df.iloc[-1][['增强_实测', '减弱_实测', '新增_实测', '修剪_实测', '变化边合计',
                            '增强占比', '减弱占比', '新增占比', '修剪占比', '幅值类占比', '结构类占比']].to_string())

if __name__ == '__main__':
    main()
