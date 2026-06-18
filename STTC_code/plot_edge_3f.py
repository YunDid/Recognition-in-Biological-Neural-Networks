# -*- coding: utf-8 -*-
# plot_edge_3f.py —— STTC 边层面四类计数柱状图（郭峰 Brainoware 图 3f 风格）
#
# 出两张：
#   (A) edge_3f_maintext.png —— 【正文版】只画实测，pre→post1 vs pre→post2 按四类分组对比（正文不放对照组）。
#   (B) edge_3f_response.png —— 【回复版】实测 vs 缩放对照(null)，双面板 post1/post2（缩放对照只进 Response Letter）。
# 数据：下方 P1_OBS/P2_OBS 硬编码自 main_edge_change.m 复刻结果（= edge_change_summary - end.xlsx）。
#       MATLAB 版改读 edge_change_3stage.xlsx（列 p1_*/p1null_*/p2_*/p2null_*）后同样作图。
# 配色：增强红/减弱蓝/新增绿/修剪灰 —— 与空间图 plot_edge_3e 四类色一致。
import numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
from scipy.stats import wilcoxon

CELLS = ['0117-1','0206-1','0206-2','0206-3','0206-4','0928-3','1108-1','1213-5','1227-1']
P1_OBS = np.array([[56,21,2,1],[406,0,1,0],[360,36,4,2],[13,0,1,0],[172,1,5,0],[0,8,0,2],[98,153,0,16],[21,2,27,0],[5,0,0,0]])
P2_OBS = np.array([[40,2,24,0],[474,0,3,0],[533,41,5,2],[55,3,1,0],[198,52,41,0],[170,70,10,5],[505,291,36,76],[98,17,15,29],[58,14,1,0]])
P1_NULL = np.zeros((9,4), int)
P2_NULL = np.zeros((9,4), int); P2_NULL[2,0] = 271
CATS = ['Strengthened','Weakened','New','Pruned']
COLORS = ['#D81B1B','#1A4DD8','#1AB332','#7F7F7F']
NULLCOLOR = '#DADADA'

def sem(a): return a.std(0, ddof=1)/np.sqrt(a.shape[0])
def lighten(hexc, f=0.55):
    h=hexc.lstrip('#'); r,g,b=[int(h[i:i+2],16) for i in (0,2,4)]
    return '#%02x%02x%02x' % (int(r+(255-r)*f), int(g+(255-g)*f), int(b+(255-b)*f))
def star(o, n, alt='two-sided'):
    if np.all(o-n == 0): return 'n/a'
    try: p = wilcoxon(o, n, zero_method='wilcox', alternative=alt).pvalue
    except Exception: return 'ns'
    return '***' if p<0.001 else '**' if p<0.01 else '*' if p<0.05 else 'ns'
def sigbar(ax, x1, x2, y, s):
    h = y*0.03 + 1
    ax.plot([x1,x1,x2,x2], [y,y+h,y+h,y], lw=1.0, c='k')
    ax.text((x1+x2)/2, y+h, s, ha='center', va='bottom', fontsize=10)

# ========== (A) 正文版：实测 post1 vs post2 ==========
p1m, p2m = P1_OBS.mean(0), P2_OBS.mean(0)
p1e, p2e = sem(P1_OBS), sem(P2_OBS)
fig, ax = plt.subplots(figsize=(7.2, 5))
x = np.arange(4); w = 0.38
ax.bar(x-w/2, p1m, w, yerr=p1e, capsize=3, color=[lighten(c) for c in COLORS],
       edgecolor='black', linewidth=0.8, zorder=3)
ax.bar(x+w/2, p2m, w, yerr=p2e, capsize=3, color=COLORS,
       edgecolor='black', linewidth=0.8, zorder=3)
gtop = max((p1m+p1e).max(), (p2m+p2e).max())
for k in range(4):
    ytop = max(p1m[k]+p1e[k], p2m[k]+p2e[k])
    sigbar(ax, x[k]-w/2, x[k]+w/2, ytop + gtop*0.03, star(P1_OBS[:,k], P2_OBS[:,k]))
ax.set_xticks(x); ax.set_xticklabels(CATS, rotation=12)
ax.set_ylabel('Number of changed edges\n(mean ± s.e.m., n = 9 cultures)')
ax.set_ylim(0, gtop*1.22)
ax.spines[['top','right']].set_visible(False)
ax.legend(handles=[Patch(facecolor='#bdbdbd', edgecolor='k', label='pre → post1 (after train 1)'),
                   Patch(facecolor='#6d6d6d', edgecolor='k', label='pre → post2 (after train 1+2)')],
          fontsize=9, frameon=False, loc='upper right')
ax.set_title('Training-induced edge-level connectivity changes', fontsize=12)
plt.tight_layout()
outA = r'E:\Recognition-in-Biological-Neural-Networks\Data\merged\edge_3f_maintext.png'
plt.savefig(outA, dpi=160); plt.close(fig); print('WROTE:', outA)

# ========== (B) 回复版：实测 vs 缩放对照（留档，回复用）==========
panels = [(P1_OBS,P1_NULL,'pre → post1  (after train 1)'),(P2_OBS,P2_NULL,'pre → post2  (after train 1+2)')]
gtop = max(max((o.mean(0)+sem(o)).max(), (n.mean(0)+sem(n)).max()) for o,n,_ in panels)
fig, axes = plt.subplots(1,2, figsize=(10,4.6), sharey=True)
for ax,(obs,null,ttl) in zip(axes, panels):
    om,nm = obs.mean(0), null.mean(0); oe,ne = sem(obs), sem(null)
    ax.bar(x-w/2, om, w, yerr=oe, capsize=3, color=COLORS, edgecolor='black', linewidth=0.8, zorder=3)
    ax.bar(x+w/2, nm, w, yerr=ne, capsize=3, color=NULLCOLOR, edgecolor='gray', hatch='//', zorder=3)
    for k in range(4):
        ytop=max(om[k]+oe[k], nm[k]+ne[k]); ax.text(x[k]-w/2, ytop+gtop*0.02, star(obs[:,k],null[:,k]), ha='center', va='bottom', fontsize=11)
    ax.set_xticks(x); ax.set_xticklabels(CATS, rotation=12); ax.set_title(ttl, fontsize=11)
    ax.spines[['top','right']].set_visible(False); ax.set_ylim(0, gtop*1.20)
axes[0].set_ylabel('Number of changed edges\n(mean ± s.e.m., n = 9)')
axes[1].legend(handles=[Patch(facecolor='#9A9A9A', edgecolor='black', label='Measured (color = type)'),
                        Patch(facecolor=NULLCOLOR, edgecolor='gray', hatch='//', label='Scaling control (null)')],
               fontsize=9, frameon=False, loc='upper right')
fig.suptitle('Edge-level changes vs. uniform-scaling control (Response Letter)', fontsize=12)
plt.tight_layout(rect=[0,0,1,0.96])
outB = r'E:\Recognition-in-Biological-Neural-Networks\Data\merged\edge_3f_response.png'
plt.savefig(outB, dpi=160); print('WROTE:', outB)

print('\npost1 vs post2 趋势检验（正文版星号）:')
for k in range(4):
    two = star(P1_OBS[:,k], P2_OBS[:,k])
    one = star(P1_OBS[:,k], P2_OBS[:,k], 'less')
    print('  %-13s post1=%6.1f post2=%6.1f | 双侧%s 单侧%s' % (CATS[k], p1m[k], p2m[k], two, one))
