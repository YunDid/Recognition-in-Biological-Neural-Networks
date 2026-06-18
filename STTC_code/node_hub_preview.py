# node_hub_preview.py —— 把 main_edge_change.m 的 node_changed（图3e 节点大小）量化为节点级指标
#
# 目的：回应 R1 主要意见4——节点得分(Fig2E-F)对幅值敏感、被缩放完全解释。
#   改用"边层面重连参与度"量化节点："卷入选择性重连的功能节点数"随训练(pre->post1->post2)的趋势，
#   且缩放对照(scaled_pre=Wpre*kS)的同一指标≈0，证明这不是整体放大的算术后果。
#
# 与 main_edge_change.m 严格同口径：load_stage 清理、τ=0.35/δ=0.10 固定、公共活跃限制、
#   mean_nz 缩放臂、9 盘 cfg.designation。仅做"实测 vs 缩放对照"，不引入新方法。
#   纯预览：只 print 趋势，不写文件、不出图。

import os
import numpy as np
import scipy.io as sio

MERGED = r'E:\Recognition-in-Biological-Neural-Networks\Data\merged'
TAU = 0.35
DELTA = 0.10

# 9 盘 pre/post1/post2，照抄 main_edge_change.m 的 cfg.designation
DESIGNATION = {
    '0117-1': (1, [2, 6]),
    '0206-1': (2, [4, 5]),
    '0206-2': (3, [4, 5]),
    '0206-3': (2, [3, 5]),
    '0206-4': (1, [3, 5]),
    '0928-3': (2, [3, 6]),
    '1108-1': (2, [3, 6]),
    '1213-5': (3, [4, 5]),
    '1227-1': (3, [4, 6]),
}

# "枢纽节点"计数阈值（参与多少条变了的边）
HUB_CUTS = [1, 3, 5]


def load_stage(sttcdir, s):
    f = os.path.join(sttcdir, f'sttc-spikes_spon{s}.mat')
    if not os.path.exists(f):
        return None, None
    d = sio.loadmat(f)
    A = np.array(d['adjM'], dtype=float)
    A[np.isnan(A)] = 0.0
    A[A < 0] = 0.0
    A = (A + A.T) / 2.0
    np.fill_diagonal(A, 0.0)
    if 'activeElectrode' in d and np.size(d['activeElectrode']) > 0:
        active = np.array(d['activeElectrode']).ravel().astype(int)
    else:
        active = np.where((A > 0).any(axis=1))[0] + 1  # 1-based 电极号
    return A, active


def mean_nz_thr(W, thr):
    Wt = W.copy()
    Wt[Wt < thr] = 0.0
    N = W.shape[0]
    off = ~np.eye(N, dtype=bool)
    v = Wt[off]
    v = v[v > 0]
    return v.mean() if v.size else 0.0


def classify_edges(Wpre, Wpost, common, tau, delta):
    idx = np.array(common, dtype=int) - 1  # 0-based
    m = idx.size
    a = Wpre[np.ix_(idx, idx)]
    b = Wpost[np.ix_(idx, idx)]
    cnt = dict(enhanced=0, weakened=0, new=0, pruned=0, stable=0)
    node_changed = np.zeros(m)
    for ii in range(m - 1):
        for jj in range(ii + 1, m):
            av = a[ii, jj]
            bv = b[ii, jj]
            ppre = av >= tau
            ppost = bv >= tau
            if not ppre and not ppost:
                continue
            if ppre and ppost:
                if (bv - av) > delta:
                    cat = 'enhanced'
                elif (av - bv) > delta:
                    cat = 'weakened'
                else:
                    cat = 'stable'
            elif (not ppre) and ppost and bv >= tau + delta:
                cat = 'new'
            elif ppre and (not ppost) and av >= tau + delta:
                cat = 'pruned'
            else:
                cat = 'stable'
            cnt[cat] += 1
            if cat != 'stable':
                node_changed[ii] += 1
                node_changed[jj] += 1
    return cnt, node_changed


def node_metrics(node_changed):
    nc = node_changed
    out = {f'ge{c}': int((nc >= c).sum()) for c in HUB_CUTS}
    out['mean'] = float(nc.mean()) if nc.size else 0.0
    out['max'] = int(nc.max()) if nc.size else 0
    return out


def run():
    rows = []
    for cell, (pre, posts) in DESIGNATION.items():
        sttcdir = os.path.join(MERGED, cell, 'sttc')
        Wpre, actPre = load_stage(sttcdir, pre)
        if Wpre is None:
            print(f'[skip] {cell} 缺 pre spon{pre}')
            continue
        for pi, t in enumerate(posts, start=1):
            Wpost, actPost = load_stage(sttcdir, t)
            if Wpost is None:
                print(f'[skip] {cell} 缺 post spon{t}')
                continue
            common = np.intersect1d(actPre, actPost)
            common = common[(common >= 1) & (common <= Wpre.shape[0])]
            if common.size < 3:
                print(f'[skip] {cell} spon{t} 公共活跃<3')
                continue
            # 实测臂
            obs, nc_obs = classify_edges(Wpre, Wpost, common, TAU, DELTA)
            # 缩放对照模型臂
            kS = mean_nz_thr(Wpost, TAU) / max(mean_nz_thr(Wpre, TAU), 1e-12)
            scaled = Wpre * kS
            nul, nc_nul = classify_edges(Wpre, scaled, common, TAU, DELTA)

            mo = node_metrics(nc_obs)
            mn = node_metrics(nc_nul)
            rows.append(dict(
                cell=cell, post_idx=pi, pre=pre, post=t,
                common_n=int(common.size), kS=kS,
                enh=obs['enhanced'], wkn=obs['weakened'], new=obs['new'], prn=obs['pruned'],
                o_ge1=mo['ge1'], o_ge3=mo['ge3'], o_ge5=mo['ge5'], o_mean=mo['mean'], o_max=mo['max'],
                n_ge1=mn['ge1'], n_ge3=mn['ge3'], n_ge5=mn['ge5'], n_mean=mn['mean'],
            ))
    return rows


def main():
    rows = run()

    # ---- 逐盘明细 ----
    print('\n================ 逐盘节点级指标（实测臂 | 缩放对照臂）================')
    hdr = (f'{"盘":7} {"对比":11} {"公共":4} {"kS":5} | '
           f'{"增":3}{"减":3}{"新":3}{"剪":3} | '
           f'{"实ge1":5}{"实ge3":5}{"实ge5":5}{"实均":6}{"实峰":4} | '
           f'{"缩ge1":5}{"缩ge3":5}{"缩ge5":5}')
    print(hdr)
    for r in rows:
        tag = f'spon{r["pre"]}->spon{r["post"]}(p{r["post_idx"]})'
        print(f'{r["cell"]:7} {tag:11} {r["common_n"]:4d} {r["kS"]:5.2f} | '
              f'{r["enh"]:3d}{r["wkn"]:3d}{r["new"]:3d}{r["prn"]:3d} | '
              f'{r["o_ge1"]:5d}{r["o_ge3"]:5d}{r["o_ge5"]:5d}{r["o_mean"]:6.2f}{r["o_max"]:4d} | '
              f'{r["n_ge1"]:5d}{r["n_ge3"]:5d}{r["n_ge5"]:5d}')

    # ---- 趋势：post1 vs post2 跨盘配对 ----
    p1 = {r['cell']: r for r in rows if r['post_idx'] == 1}
    p2 = {r['cell']: r for r in rows if r['post_idx'] == 2}
    both = [c for c in p1 if c in p2]

    print('\n================ 趋势：post1 → post2（随多次训练）================')
    print(f'参与盘数 n={len(both)}')
    for key, label in [('o_ge1', '卷入重连节点数(ge1)'),
                       ('o_ge3', '中度卷入节点数(ge3)'),
                       ('o_ge5', '强卷入/枢纽节点数(ge5)'),
                       ('o_mean', '人均卷入边数(mean)')]:
        v1 = np.array([p1[c][key] for c in both], dtype=float)
        v2 = np.array([p2[c][key] for c in both], dtype=float)
        up = int((v2 > v1).sum())
        eq = int((v2 == v1).sum())
        dn = int((v2 < v1).sum())
        print(f'{label:24} post1均={v1.mean():6.2f}  post2均={v2.mean():6.2f}  '
              f'升/平/降 = {up}/{eq}/{dn}  (Δ均={v2.mean()-v1.mean():+.2f})')

    # ---- 实测 vs 缩放对照：枢纽计数是否压根不是缩放产物 ----
    print('\n========== 实测 vs 缩放对照（枢纽节点计数；缩放臂≈0 才说明非整体放大）==========')
    for pi, name in [(1, 'pre->post1'), (2, 'pre->post2')]:
        sel = [r for r in rows if r['post_idx'] == pi]
        o1 = np.array([r['o_ge1'] for r in sel], dtype=float)
        o5 = np.array([r['o_ge5'] for r in sel], dtype=float)
        n1 = np.array([r['n_ge1'] for r in sel], dtype=float)
        n5 = np.array([r['n_ge5'] for r in sel], dtype=float)
        win1 = int((o1 > n1).sum())
        win5 = int((o5 > n5).sum())
        print(f'{name}: 实测ge1均={o1.mean():5.2f} vs 缩放ge1均={n1.mean():4.2f} '
              f'(实>缩 {win1}/{len(sel)}盘) | '
              f'实测ge5均={o5.mean():5.2f} vs 缩放ge5均={n5.mean():4.2f} '
              f'(实>缩 {win5}/{len(sel)}盘)')


if __name__ == '__main__':
    main()
