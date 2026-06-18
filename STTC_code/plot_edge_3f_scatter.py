# -*- coding: utf-8 -*-
# plot_edge_3f_scatter.py —— STTC 边层面四类计数【配对散点图】（郭峰 Brainoware 图 3f 排版）
#
# 出两版（数据=正文版 实测 post1 vs post2，配对、无对照组）：
#   (1) edge_3f_scatter_single.png —— 单面板，四类同一 y 轴（照郭峰排版；本数据量级差大，新增/修剪会贴地）
#   (2) edge_3f_scatter_panels.png —— 四类各一格、各自 y 轴（点看得清，推荐）
# 每盘一对点：post1(青圆)→post2(红方)，虚线相连；星号=post1 vs post2 配对 Wilcoxon。
# 数据硬编码自 main_edge_change.m 复刻结果；MATLAB 版改读 edge_change_3stage.xlsx 同样作图。
import numpy as np
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy.stats import wilcoxon

P1 = np.array([[56,21,2,1],[406,0,1,0],[360,36,4,2],[13,0,1,0],[172,1,5,0],[0,8,0,2],[98,153,0,16],[21,2,27,0],[5,0,0,0]])
P2 = np.array([[40,2,24,0],[474,0,3,0],[533,41,5,2],[55,3,1,0],[198,52,41,0],[170,70,10,5],[505,291,36,76],[98,17,15,29],[58,14,1,0]])
CATS = ['Strengthened','Weakened','New','Pruned']
CYAN, RED = '#1CA9C9', '#E8302A'
N = P1.shape[0]
# 固定抖动（不用随机，保证可复现）：9 个点的小横向偏移
JIT = (np.arange(N)-(N-1)/2)/ (N-1) * 0.16

def star(a, b, alt='two-sided'):
    if np.all(a-b == 0): return 'n/a'
    try: p = wilcoxon(a, b, zero_method='wilcox', alternative=alt).pvalue
    except Exception: return 'ns'
    return '***' if p<0.001 else '**' if p<0.01 else '*' if p<0.05 else 'ns'

# ===== (1) 单面板 =====
fig, ax = plt.subplots(figsize=(7.4,5))
for k in range(4):
    xa = k + 1 - 0.18 + JIT*0.5
    xb = k + 1 + 0.18 + JIT*0.5
    for d in range(N):
        ax.plot([xa[d], xb[d]], [P1[d,k], P2[d,k]], '--', color='0.6', lw=0.6, zorder=1)
    ax.scatter(xa, P1[:,k], marker='o', s=42, color=CYAN, edgecolor='k', linewidth=0.4, zorder=3)
    ax.scatter(xb, P2[:,k], marker='s', s=40, color=RED, edgecolor='k', linewidth=0.4, zorder=3)
    ymax = max(P1[:,k].max(), P2[:,k].max())
    ax.text(k+1, ymax+18, star(P1[:,k],P2[:,k]), ha='center', fontsize=12)
ax.set_xticks(range(1,5)); ax.set_xticklabels(CATS, rotation=12)
ax.set_ylabel('Connectivity changes (edges)')
ax.set_title('Edge changes  post1 (circle) → post2 (square),  n = 9', fontsize=11)
ax.scatter([],[],marker='o',color=CYAN,edgecolor='k',label='pre→post1'); ax.scatter([],[],marker='s',color=RED,edgecolor='k',label='pre→post2')
ax.legend(fontsize=9, frameon=False, loc='upper right')
ax.spines[['top','right']].set_visible(False)
plt.tight_layout()
o1=r'E:\Recognition-in-Biological-Neural-Networks\Data\merged\edge_3f_scatter_single.png'
plt.savefig(o1,dpi=160); plt.close(fig); print('WROTE:',o1)

# ===== (2) 四格，各自 y 轴 =====
fig, axes = plt.subplots(1,4, figsize=(11,4.2))
for k, ax in enumerate(axes):
    xa = 1 + JIT; xb = 2 + JIT
    for d in range(N):
        ax.plot([xa[d], xb[d]], [P1[d,k], P2[d,k]], '--', color='0.6', lw=0.7, zorder=1)
    ax.scatter(xa, P1[:,k], marker='o', s=46, color=CYAN, edgecolor='k', linewidth=0.4, zorder=3)
    ax.scatter(xb, P2[:,k], marker='s', s=44, color=RED, edgecolor='k', linewidth=0.4, zorder=3)
    ymax = max(P1[:,k].max(), P2[:,k].max())
    ax.text(1.5, ymax*1.06+1, star(P1[:,k],P2[:,k]), ha='center', fontsize=12)
    ax.set_xlim(0.5,2.5); ax.set_xticks([1,2]); ax.set_xticklabels(['post1','post2'])
    ax.set_ylim(-ymax*0.06, ymax*1.20+1); ax.set_title(CATS[k], fontsize=11)
    ax.spines[['top','right']].set_visible(False)
axes[0].set_ylabel('Connectivity changes (edges)')
fig.suptitle('Edge-level changes per category  (post1 → post2, n = 9, own y-axis)', fontsize=12)
plt.tight_layout(rect=[0,0,1,0.95])
o2=r'E:\Recognition-in-Biological-Neural-Networks\Data\merged\edge_3f_scatter_panels.png'
plt.savefig(o2,dpi=160); print('WROTE:',o2)

print('\npost1 vs post2 星号：')
for k in range(4):
    print('  %-13s 双侧%s 单侧%s' % (CATS[k], star(P1[:,k],P2[:,k]), star(P1[:,k],P2[:,k],'less')))
