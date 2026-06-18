# ESN 人工储备池基线（回应审稿人 3：缺人工储备池对照）

把 Japanese Vowels 八分类任务喂进一个回声状态网络（ESN，artificial reservoir），与生物储备池在
**同一份输入、同一套标签、同一 5 折划分、同一读出层**下对比，只把中间的 reservoir 从「生物」换成「人工」。
这一版先离线跑出 ESN 这一侧的基准数；生物侧（湿实验诱发响应）后续补齐后再拼成直接对比。

## 对比的三级阶梯

| 层级 | 配置 | 作用 |
| --- | --- | --- |
| 随机水平 | 1/类别数 | 下界参照（图中虚线） |
| 地板线 | 输入展平 → 线性 SVM（无 reservoir） | 任务非平凡的下界、留出 reservoir 证明价值的空间 |
| 人工参照 | 输入 → ESN → 线性 SVM | 标准人工储备池（本目录产出，图中虚线） |
| 本文主体 | 输入 → 类器官 → 诱发响应 → 线性 SVM | 生物储备池（湿实验后接入，图中学习曲线） |

ESN 喂的是「类器官实际收到的同一份输入」，不是类器官的响应。响应是生物 reservoir 对输入的高维投影，
属于生物那条路的读出底物，不作为 ESN 的输入。

## 输入变体（四种，一次跑全）

| 标签 | 文件 | 含义 |
| --- | --- | --- |
| raw12 | `standardized_12slot.txt` | 原始 12 维 LPC（信息上界参照） |
| site6 | `score6_12slot.txt` | 六位点连续得分（相邻均值路线，与类器官同输入） |
| top1 | `top1_6site.txt` | 六位点 top-1（与类器官同输入） |
| top2 | `top2_6site.txt` | 六位点 top-2（与类器官同输入） |

输入文本由 `../japanese_vowels_feature_check/` 的 02/03/04 脚本生成。当前六位点用的是**相邻均值（取绝对值）**
压缩路线；若 M3 最终锁定别的编码路线（前 6 系数 / 平均绝对值 top6），需重新生成对应文本再跑，
保证 ESN 与湿实验用同一条编码路线。

## 方法与超参数（写进 Response Letter 用）

- ESN：漏积分 tanh 神经元 + 谱半径缩放的稀疏随机递归连接（与 PyRCN 的 ESN 方法一致，纯 numpy 透明实现）。
- reservoir 规模：32 对齐**本文生物侧读出通道数**（活跃电极 16 上 + 16 下，与既有八分类 SVM 分析一致），
  另扫 16/64/128 作敏感性，避免"手挑弱 ESN"质疑。
- 谱半径 0.9、输入幅度 1.0、漏积分率 0.3、连接稀疏度 0.1；逐时间步状态拼接后送读出。
- 读出层：一对多线性 SVM（scikit-learn `SVC(kernel='linear')`，libsvm 后端，C=1.0），与生物侧 MATLAB 八分类 SVM
  同底层（libsvm/SMO），在「特征多于样本」的高维 reservoir 状态上收敛稳定；多个随机 reservoir（5 个种子）取 mean±std。
  注：05 里手写的定步长梯度下降 SVM 在高维状态上数值发散（NaN→塌到随机水平）、LinearSVC 又不收敛（数偏移~12%），均已弃用。
- 交叉验证：分层 5 折，seed=20260501，与既有 `05_classify_svm.py` 完全一致 → ESN、地板线、生物侧三者可直接并排比。

## 学习曲线与 epoch（方案 A）

ESN 没有 epoch 概念（reservoir 固定，读出层一次性求解）。生物储备池才有 epoch（训练期多轮）。
最终图采用方案 A：只画**生物储备池**随训练 epoch 的学习曲线，ESN 与随机水平各画一条**水平虚线**作参照。
本目录只产出 ESN 与随机水平这两个固定参照值；生物学习曲线由湿实验（建议 3–4 个测量点 / 2–3 轮训练）提供。
加药实验无 epoch，只对比加药前后两点。

## 运行

```powershell
cd E:\Recognition-in-Biological-Neural-Networks\Code\BRC_revision\esn_baseline
$env:PYTHONIOENCODING='utf-8'   # 让终端中文不乱码（不影响数据文件）
python run_esn_baseline.py
```

依赖：numpy、scikit-learn、pandas、openpyxl（已装入系统 Python 3.13）。

## 产物

- `results/esn_baseline_summary.xlsx`（中文表头）、`results/esn_baseline_summary.csv`
- 列：输入类型、reservoir 规模、谱半径、泄漏率、ESN 平均准确率、ESN 准确率标准差、
  无 reservoir 地板准确率、ESN 相对地板增益、随机水平准确率、折数、种子数、样本数、类别数。

## 文件

| 文件 | 职责 |
| --- | --- |
| `config.py` | 路径与超参数集中配置（迁机器只改 REPO 一处） |
| `data_io.py` | 数据读取与分层折划分（逻辑与 05_classify_svm.py 一致） |
| `esn_core.py` | ESN 本体（reservoir 投影） |
| `run_esn_baseline.py` | 主脚本：四变体 × 多规模 × 多种子 → 汇总表 |
