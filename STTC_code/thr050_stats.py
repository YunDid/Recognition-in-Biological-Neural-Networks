# thr050_stats.py
# 用户观察：thr=0.50、post2 下"实测>缩放"趋势冒头。逐指标(CC/CPL/Eglob/Hub)、分 post1/post2
# 做配对检验，并与 thr=0.35 对照（看 0.50 是否只是阈值挑选）。
# 方向性假设：CC/Eglob/Hub 重组→实测>缩放(res>0)；CPL→实测<缩放(res<0,路径更短)。
import numpy as np
from scipy.stats import wilcoxon, binomtest
from param_sweep_analysis import compute_dish, ORDER

def collect(thr, metric, post):
    return np.array([compute_dish(c, thr, False, 'cloc')[f'{metric}_p{post}_res'] for c in ORDER], float)

# 复用一次 compute_dish 结果（避免每指标重算）
def all_res(thr):
    rows = [compute_dish(c, thr, False, 'cloc') for c in ORDER]
    return rows

def test(d, direction):
    """direction='greater'(res>0 为重组) 或 'less'(res<0 为重组)。返回 (均值, 正, 负, Wilcoxon单侧p, 符号p)。"""
    d = d[np.isfinite(d)]
    nz = d[d != 0]
    pos = int((d > 0).sum()); neg = int((d < 0).sum())
    try:
        wp = wilcoxon(nz, alternative=direction).pvalue if nz.size else np.nan
    except Exception:
        wp = np.nan
    # 符号检验方向
    if direction == 'greater':
        bp = binomtest(pos, pos + neg, 0.5, alternative='greater').pvalue if pos + neg else np.nan
    else:
        bp = binomtest(neg, pos + neg, 0.5, alternative='greater').pvalue if pos + neg else np.nan
    return d.mean(), pos, neg, wp, bp

METRICS = [('CC', 'greater'), ('Eglob', 'greater'), ('CPL', 'less'), ('Hub', 'greater')]

for thr in [0.35, 0.50]:
    rows = all_res(thr)
    print('=' * 78)
    print(f'thr = {thr:.2f}   (重组方向：CC/Eglob/Hub 实测>缩放; CPL 实测<缩放)')
    print('=' * 78)
    for post in (1, 2):
        print(f'  -- post{post} --')
        for metric, direction in METRICS:
            d = np.array([r[f'{metric}_p{post}_res'] for r in rows], float)
            mean, pos, neg, wp, bp = test(d, direction)
            flag = '  <== 趋势显著' if (wp == wp and wp < 0.05) else ('  (擦边)' if (wp==wp and wp<0.10) else '')
            print(f'    {metric:6} 残差均={mean:+.4f}  正/负={pos}/{neg}  '
                  f'Wilcoxon单侧({direction})p={wp:.4f}  符号p={bp:.4f}{flag}')

# thr=0.50 post2 逐盘 CC/Eglob 残差明细
print('\n' + '=' * 78)
print('thr=0.50 post2 逐盘残差明细（看趋势是否一致、是否靠个别盘）')
print('=' * 78)
rows = all_res(0.50)
print(f'{"盘":8}{"CC残差":>10}{"Eglob残差":>11}{"CPL残差":>10}{"Hub残差":>10}{"kS_p2":>8}')
for r in rows:
    print(f'{r["cell"]:8}{r["CC_p2_res"]:>10.4f}{r["Eglob_p2_res"]:>11.4f}{r["CPL_p2_res"]:>10.4f}{r["Hub_p2_res"]:>10.4f}{r["kS_p2"]:>8.3f}')
