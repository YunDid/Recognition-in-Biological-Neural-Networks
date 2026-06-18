# edge_hub_stats.py
# 任务1：边层面"hub 节点"的统计学计算 —— 对缩放免疫的 hub 重组证据
#   (A) 节点卷入重连数：每个节点参与多少条"变了的边"，实测臂 vs 缩放对照臂，配对检验
#   (B) 仅结构类(新增/修剪)的节点卷入：缩放天生造不出 new/pruned，最干净的"重连 hub"
#   (C) hub 身份周转：用每盘自身阈值定 hub(对缩放免疫)，比较 pre vs post 的 hub 节点集合变化
# 复用 param_sweep_analysis.py 已验证的 node_metrics。运行：python edge_hub_stats.py
import numpy as np
import scipy.io as sio
from scipy.stats import wilcoxon, binomtest
from param_sweep_analysis import node_metrics, DESIGNATION, ORDER, MERGED

TAU, DELTA = 0.35, 0.10

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

def classify_involvement(Wpre, Wpost, common):
    """返回 (node_changed_all, node_changed_struct, counts)。common=1-based 电极号。"""
    idx = np.array(common, int) - 1
    a = Wpre[np.ix_(idx, idx)]; b = Wpost[np.ix_(idx, idx)]; m = idx.size
    nc = np.zeros(m); ncs = np.zeros(m)
    cnt = dict(enh=0, wkn=0, new=0, prn=0)
    for ii in range(m - 1):
        for jj in range(ii + 1, m):
            av, bv = a[ii, jj], b[ii, jj]; ppre, ppost = av >= TAU, bv >= TAU
            if not ppre and not ppost:
                continue
            cat = 'stable'
            if ppre and ppost:
                if bv - av > DELTA: cat = 'enh'
                elif av - bv > DELTA: cat = 'wkn'
            elif (not ppre) and ppost and bv >= TAU + DELTA: cat = 'new'
            elif ppre and (not ppost) and av >= TAU + DELTA: cat = 'prn'
            if cat != 'stable':
                nc[ii] += 1; nc[jj] += 1; cnt[cat] += 1
                if cat in ('new', 'prn'):
                    ncs[ii] += 1; ncs[jj] += 1
    return nc, ncs, cnt

def ge(nc, k):
    return int((nc >= k).sum())

def hub_set(Wfull, common, third='cloc', top=0.40, cut=2):
    """common 子网上、用本网自身阈值(对缩放免疫)定 hub 节点集合。"""
    idx = np.array(common, int) - 1
    sub = Wfull[np.ix_(idx, idx)].copy(); sub[sub < TAU] = 0.0
    nm = node_metrics(sub)
    def thr_(x):
        g = int(min(max(round(top * len(x)), 1), len(x))); return np.sort(x)[::-1][g - 1]
    h = ((nm['mean_str'] >= thr_(nm['mean_str'])).astype(int)
         + (nm['eloc'] >= thr_(nm['eloc'])).astype(int)
         + (nm[third] >= thr_(nm[third])).astype(int))
    return set(np.where(h >= cut)[0]), idx.size

def main():
    obs = {1: {1: [], 3: [], 5: []}, 2: {1: [], 3: [], 5: []}}
    scl = {1: {1: [], 3: [], 5: []}, 2: {1: [], 3: [], 5: []}}
    obs_s = {1: {1: [], 3: []}, 2: {1: [], 3: []}}     # 结构类卷入
    turn_rows = []
    print('=' * 72)
    print('逐盘明细（实测臂 | 缩放对照臂；卷入≥k 条变化边的节点数）')
    print('=' * 72)
    for cell in ORDER:
        pre, posts = DESIGNATION[cell]
        Wpre, actPre = load_symm(cell, pre)
        for k, t in enumerate(posts, 1):
            Wpost, actPost = load_symm(cell, t)
            common = np.intersect1d(actPre, actPost)
            common = common[(common >= 1) & (common <= Wpre.shape[0])]
            kS = mean_nz(Wpost) / max(mean_nz(Wpre), 1e-12)
            scaled = Wpre * kS
            nc_o, ncs_o, c_o = classify_involvement(Wpre, Wpost, common)
            nc_s, ncs_s, c_s = classify_involvement(Wpre, scaled, common)
            for K in (1, 3, 5):
                obs[k][K].append(ge(nc_o, K)); scl[k][K].append(ge(nc_s, K))
            for K in (1, 3):
                obs_s[k][K].append(ge(ncs_o, K))
            # hub 身份周转（每盘自身阈值，对缩放免疫）
            hpre, n1 = hub_set(Wpre, common); hpost, _ = hub_set(Wpost, common)
            union = hpre | hpost; inter = hpre & hpost
            turnover = 1 - (len(inter) / len(union)) if union else 0.0
            turn_rows.append(dict(cell=cell, post=k, n_common=int(common.size),
                                  hub_pre=len(hpre), hub_post=len(hpost),
                                  stayed=len(inter), changed=len(union) - len(inter), turnover=turnover))
            print(f'{cell} p{k}(spon{pre}->{t}) kS={kS:.3f} 公共{common.size:3d} | '
                  f'实测 ge1={ge(nc_o,1):2d} ge3={ge(nc_o,3):2d} ge5={ge(nc_o,5):2d} | '
                  f'缩放 ge1={ge(nc_s,1):2d} ge3={ge(nc_s,3):2d} ge5={ge(nc_s,5):2d} | '
                  f'结构卷入 ge1={ge(ncs_o,1):2d} | hub周转={turnover:.2f}')

    print('\n' + '=' * 72)
    print('(A) 节点卷入重连数：实测 vs 缩放对照，配对 Wilcoxon（单侧 实测>缩放）')
    print('=' * 72)
    for k in (1, 2):
        for K in (1, 3, 5):
            o = np.array(obs[k][K], float); s = np.array(scl[k][K], float); d = o - s
            nz = d[d != 0]
            try:
                p = wilcoxon(nz, alternative='greater').pvalue if nz.size else np.nan
            except Exception:
                p = np.nan
            pos = int((d > 0).sum()); neg = int((d < 0).sum())
            bp = binomtest(pos, pos + neg, 0.5, alternative='greater').pvalue if pos + neg else np.nan
            print(f'  post{k} ge{K}: 实测均={o.mean():5.2f} 缩放均={s.mean():4.2f} 正/负={pos}/{neg} '
                  f'Wilcoxon单侧p={p:.4f} 符号p={bp:.4f}')

    print('\n' + '=' * 72)
    print('(B) 仅结构类(新增/修剪)卷入节点数：缩放臂≡0（构造上造不出 new/pruned），检验实测>0')
    print('=' * 72)
    for k in (1, 2):
        for K in (1, 3):
            o = np.array(obs_s[k][K], float)
            try:
                p = wilcoxon(o, alternative='greater').pvalue if (o != 0).any() else np.nan
            except Exception:
                p = np.nan
            nzero = int((o > 0).sum())
            print(f'  post{k} 结构卷入ge{K}: 各盘={o.astype(int).tolist()} 均={o.mean():.2f} '
                  f'>0盘数={nzero}/9 Wilcoxon(>0)p={p:.4f}')

    print('\n' + '=' * 72)
    print('(C) hub 身份周转（每盘自身阈值→对缩放严格免疫；纯放大预测周转=0）')
    print('=' * 72)
    for k in (1, 2):
        tv = np.array([r['turnover'] for r in turn_rows if r['post'] == k])
        ch = np.array([r['changed'] for r in turn_rows if r['post'] == k])
        try:
            p = wilcoxon(tv, alternative='greater').pvalue if (tv != 0).any() else np.nan
        except Exception:
            p = np.nan
        print(f'  post{k}: 平均周转率={tv.mean():.3f}  平均换掉hub数={ch.mean():.1f}  '
              f'有周转盘数={(tv>0).sum()}/9  Wilcoxon(>0)p={p:.4f}')
    print('\n说明：缩放对照对(A)是构造性≈0(kS≈1+δ地板)，故(A)的"实测>缩放"含同义反复成分；')
    print('     (B)结构卷入与(C)身份周转才是缩放无法伪造的干净证据。')

if __name__ == '__main__':
    main()
