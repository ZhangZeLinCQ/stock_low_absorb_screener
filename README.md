# Low Absorb Screener 3.0：卖盘枯竭低吸筛选器

这是一个用于筛选 **A 股沪深主板 10cm、非 ST、大市值股票** 的低吸观察池脚本。

核心目标不是“自动买入”，而是从大市值股票中筛出：

```text
下跌日成交量处于历史低位
+ 当前成交量也偏低
+ 没有明显破位
+ 位置相对安全
+ 初步有买盘修复迹象
+ 盈亏比相对合理
```

> 重要说明：程序只能帮助提高筛选质量，不能保证低吸正确。输出结果应作为观察池或复盘清单，不应作为自动下单依据。

---

## 1. 本版新增内容

相对 2.x 版本，本版新增：

1. **低吸综合评分**：0-100 分，综合卖盘枯竭、整体缩量、位置安全、趋势质量、确认信号、盈亏比。
2. **建议状态**：例如“观察-等待确认”“可低吸-轻仓型”“信号失效-跌破地量低点”。
3. **地量低点保护**：可要求最新收盘价不能跌破最近命中低量日的最低价。
4. **均线确认过滤**：可要求最新价站上 MA5 / MA10 / MA20。
5. **风险收益比过滤**：默认以最近低量日低点下方作为止损，以近 60 日高点作为目标价。
6. **当前成交量分位**：继续保留“最新成交量在历史全样本中的分位百分比”。

---

## 2. 安装

进入项目目录：

```bash
cd low_absorb_screener
```

创建虚拟环境：

```bash
python3 -m venv .venv
source .venv/bin/activate
```

Windows PowerShell：

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

安装依赖：

```bash
python3 -m pip install -r requirements.txt
```

基础检查：

```bash
python3 -m py_compile low_absorb_screener.py
python3 low_absorb_screener.py --help
```

---

## 3. 推荐运行命令

### 3.1 平衡观察池

适合日常先筛一批观察对象。

```bash
python3 low_absorb_screener.py \
  --min-market-cap-yi 500 \
  --lookback-days 240 \
  --recent-days 10 \
  --min-hit-days 2 \
  --lowest-down-percent 10 \
  --min-avg-amount-yi 2 \
  --recent-volume-shrink-ratio 0.7 \
  --max-20d-drop-pct 20 \
  --min-distance-from-60d-low-pct 3 \
  --max-latest-volume-percentile 30 \
  --workers 3
```

### 3.2 严格观察池

适合结果太多时使用。

```bash
python3 low_absorb_screener.py \
  --min-market-cap-yi 800 \
  --lookback-days 240 \
  --recent-days 10 \
  --min-hit-days 3 \
  --lowest-down-percent 5 \
  --min-avg-amount-yi 3 \
  --recent-volume-shrink-ratio 0.6 \
  --max-20d-drop-pct 15 \
  --min-distance-from-60d-low-pct 5 \
  --max-latest-volume-percentile 20 \
  --workers 3
```

### 3.3 评分过滤版

只保留低吸综合评分较高的股票。

```bash
python3 low_absorb_screener.py \
  --min-market-cap-yi 800 \
  --lookback-days 240 \
  --recent-days 10 \
  --min-hit-days 3 \
  --lowest-down-percent 5 \
  --min-avg-amount-yi 3 \
  --recent-volume-shrink-ratio 0.6 \
  --max-20d-drop-pct 15 \
  --min-distance-from-60d-low-pct 5 \
  --max-latest-volume-percentile 20 \
  --require-not-break-low-volume-low \
  --min-low-absorb-score 70 \
  --workers 3
```

### 3.4 确认型低吸版

更保守，要求地量后已有放量阳线确认、站回短期均线、盈亏比足够。

```bash
python3 low_absorb_screener.py \
  --min-market-cap-yi 800 \
  --lookback-days 240 \
  --recent-days 10 \
  --min-hit-days 3 \
  --lowest-down-percent 5 \
  --min-avg-amount-yi 3 \
  --recent-volume-shrink-ratio 0.65 \
  --max-20d-drop-pct 15 \
  --min-distance-from-60d-low-pct 5 \
  --max-latest-volume-percentile 25 \
  --require-not-break-low-volume-low \
  --require-price-above-ma5 \
  --require-confirm-signal \
  --min-reward-risk-ratio 2 \
  --min-low-absorb-score 75 \
  --workers 3
```

如果这套筛不到股票，先去掉：

```bash
--require-confirm-signal
```

再把：

```bash
--min-low-absorb-score 75
```

调成：

```bash
--min-low-absorb-score 70
```

---

## 4. 核心参数说明

### 4.1 股票池参数

| 参数 | 含义 | 建议 |
|---|---|---|
| `--min-market-cap-yi` | 最低总市值，单位亿元 | 稳健用 500，严格用 800 或 1000 |
| `--refresh-candidates` | 强制刷新候选股票池 | 改了市值门槛或缓存过旧时使用 |

程序默认只保留：

```text
沪深主板 10cm
非 ST / 非 *ST
总市值大于阈值
```

---

### 4.2 地量识别参数

| 参数 | 含义 | 建议 |
|---|---|---|
| `--lookback-days` | 历史统计周期 | 180 偏灵敏，240 更稳健 |
| `--recent-days` | 最近观察窗口 | 常用 7 或 10 |
| `--min-hit-days` | 最近窗口内至少命中几天 | 宽松 1-2，严格 3 |
| `--lowest-down-percent` | 下跌日成交量进入历史最低百分之几 | 严格 5，平衡 10 |
| `--down-day-mode` | 下跌日定义 | 默认 `pct`，即涨跌幅 < 0 |

示例：

```bash
--lookback-days 240 --recent-days 10 --min-hit-days 3 --lowest-down-percent 5
```

含义：

```text
过去 240 个交易日内，把所有下跌日成交量从低到高排序；
最近 10 个交易日内，至少 3 个下跌日的成交量进入历史最低 5%。
```

---

### 4.3 当前成交量分位参数

| 参数 | 含义 |
|---|---|
| `--max-latest-volume-percentile` | 最新交易日成交量必须处于历史全样本最低多少百分比以内 |

示例：

```bash
--max-latest-volume-percentile 20
```

含义：

```text
最新交易日成交量必须处于过去 lookback-days 有效样本的最低 20% 以内。
```

这个参数用于配合“命中下跌低量”一起看：

```text
最近出现过下跌地量
+ 当前成交量仍处于历史低位
```

---

### 4.4 流动性与整体缩量参数

| 参数 | 含义 | 建议 |
|---|---|---|
| `--min-avg-amount-yi` | 近 20 日平均成交额下限，单位亿元 | 平衡 2，严格 3-5 |
| `--recent-volume-shrink-ratio` | 近 5 日均量 / 近 60 日均量上限 | 平衡 0.7，严格 0.6 |

示例：

```bash
--min-avg-amount-yi 3 --recent-volume-shrink-ratio 0.6
```

含义：

```text
近 20 日平均成交额至少 3 亿元；
近 5 日均量不超过近 60 日均量的 60%。
```

---

### 4.5 破位过滤参数

| 参数 | 含义 | 建议 |
|---|---|---|
| `--max-20d-drop-pct` | 相对近 20 日最高价的最大允许回撤 | 平衡 20，严格 15 |
| `--min-distance-from-60d-low-pct` | 最新价距离近 60 日低点至少多少 | 平衡 3，严格 5 |
| `--require-not-break-low-volume-low` | 要求最新价不能跌破最近命中地量日低点 | 强烈建议在严格版中使用 |

`--require-not-break-low-volume-low` 很关键：

```text
如果地量日之后继续跌破地量日低点，说明原来的卖盘枯竭信号大概率失效。
```

---

### 4.6 均线确认参数

| 参数 | 含义 | 严格程度 |
|---|---|---|
| `--require-price-above-ma5` | 最新价必须站上 MA5 | 低 |
| `--require-price-above-ma10` | 最新价必须站上 MA10 | 中 |
| `--require-price-above-ma20` | 最新价必须站上 MA20 | 高 |

建议：

```text
观察池：不加均线过滤，避免漏掉早期低吸观察对象。
确认池：加 --require-price-above-ma5。
更保守：加 --require-price-above-ma10 或 MA20。
```

---

### 4.7 确认信号参数

| 参数 | 含义 |
|---|---|
| `--require-confirm-signal` | 只保留出现确认信号的股票 |

确认信号定义：

```text
最近一次命中下跌地量日之后 1-3 个交易日内：
1. 涨跌幅 > 0；
2. 收盘价突破低量日最高价；
3. 成交量大于低量日前后 5 日均量。
```

这个参数会大幅减少结果数量。它筛的是更接近买点的股票，不是早期潜伏观察池。

---

### 4.8 盈亏比与评分参数

| 参数 | 含义 | 建议 |
|---|---|---|
| `--min-reward-risk-ratio` | 最低盈亏比 | 严格用 2 |
| `--min-low-absorb-score` | 最低低吸综合评分 | 观察用 60-70，严格用 70-75 |

默认计算方式：

```text
参考止损价 = 最近命中低量日最低价 * 0.98
参考目标价 = 近 60 日最高价
盈亏比 = (参考目标价 - 最新收盘价) / (最新收盘价 - 参考止损价)
```

---

## 5. 输出字段说明

结果输出到：

```text
output/low_absorb_日期_参数.csv
output/latest_low_absorb.csv
output/latest_low_absorb.md
```

重点字段：

| 字段 | 含义 |
|---|---|
| `低吸综合评分` | 0-100，越高越优先观察 |
| `建议状态` | 程序根据评分和结构给出的状态分类 |
| `命中下跌低量分位(%)` | 最近窗口中命中的下跌低量日，在历史下跌日样本中的分位 |
| `最新成交量(手)` | 最新交易日成交量，A 股通常 1 手 = 100 股 |
| `最新成交量全样本分位(%)` | 最新成交量在历史全部有效交易日中的分位，越低越缩量 |
| `最新下跌量分位(%)` | 如果最新日是下跌日，它在历史下跌日样本中的分位 |
| `最新量/下跌低量阈值` | 小于等于 1 说明最新量也进入下跌低量阈值附近 |
| `近5日/60日均量比` | 判断整体是否缩量 |
| `近20日高点回撤(%)` | 判断短期是否跌太深 |
| `距60日低点(%)` | 判断是否贴近阶段新低 |
| `最近低量日低点` | 最近一次命中下跌地量日的最低价 |
| `是否跌破低量日低点` | 如果为“是”，信号偏失效 |
| `MA5` / `MA10` / `MA20` / `MA60` | 均线位置 |
| `参考止损价` | 默认按最近低量日低点 * 0.98 计算 |
| `参考目标价` | 默认按近 60 日最高价计算 |
| `盈亏比` | 用于判断交易是否值得做 |

---

## 6. 评分规则

低吸综合评分由 6 个部分组成：

| 模块 | 权重 | 说明 |
|---|---:|---|
| 卖盘枯竭评分 | 25% | 命中低量分位、最新量分位越低越好 |
| 整体缩量评分 | 15% | 近 5 日均量 / 近 60 日均量越低越好，但过低也需结合成交额 |
| 位置安全评分 | 20% | 不能跌太深，不能贴近 60 日新低，不能跌破地量低点 |
| 趋势质量评分 | 15% | 是否站上 MA5 / MA10 / MA20 / MA60 |
| 确认信号评分 | 15% | 是否出现放量阳线突破地量日高点 |
| 风险收益评分 | 10% | 盈亏比越高越好 |

评分解释：

```text
80 分以上：优先观察；如果同时有确认信号，接近确认型低吸候选。
70-80 分：观察池核心对象，需要等确认或结合人工复盘。
60-70 分：弱观察，可能只是缩量但买点不充分。
60 分以下：条件不足，不建议优先看。
```

---

## 7. 建议状态解释

| 建议状态 | 含义 |
|---|---|
| `可低吸-确认型` | 评分高、有确认信号、盈亏比较好 |
| `可低吸-轻仓型` | 评分较高、站回短期均线、盈亏比尚可 |
| `观察-等待放量确认` | 有低量信号，但还需要买盘回流确认 |
| `观察-等待站回均线` | 有低量信号，但趋势修复不足 |
| `信号失效-跌破地量低点` | 地量之后继续破位，原信号失效 |
| `弱观察-条件不足` | 条件不够好，只能作为备选 |

---

## 8. 参数如何调节

结果太多时，加严：

```bash
--min-market-cap-yi 1000
--lowest-down-percent 5
--min-hit-days 3
--min-avg-amount-yi 5
--recent-volume-shrink-ratio 0.6
--max-latest-volume-percentile 15
--require-not-break-low-volume-low
--require-price-above-ma5
--min-low-absorb-score 75
```

结果太少时，放宽：

```bash
--min-market-cap-yi 500
--lowest-down-percent 10
--min-hit-days 2
--min-avg-amount-yi 2
--recent-volume-shrink-ratio 0.7
--max-latest-volume-percentile 30
--min-low-absorb-score 60
```

---

## 9. 日常使用流程

建议按这个流程做：

```text
第一步：跑“平衡观察池”
第二步：按低吸综合评分排序
第三步：优先看 70 分以上
第四步：剔除明显利空、行业走弱、基本面恶化的股票
第五步：等待站回 MA5 / 放量阳线 / 不破地量低点
第六步：只做盈亏比合理的票
```

程序适合做：

```text
初筛、复盘、观察池生成、低吸候选排序
```

不适合做：

```text
自动下单、无脑买入、替代基本面和消息面判断
```

---

## 10. 常见问题

### Q1：为什么结果为空？

可能原因：

```text
1. 参数太严格；
2. 当前市场没有符合条件的票；
3. 数据源当天还没有更新；
4. 网络导致日线缓存不完整；
5. 加了 --require-confirm-signal 导致大幅过滤。
```

先尝试：

```bash
--min-low-absorb-score 60
```

或者去掉：

```bash
--require-confirm-signal
```

### Q2：什么时候加 `--require-confirm-signal`？

当你想找更接近买点的股票时加。早期观察池不要加，否则容易漏掉刚开始缩量的股票。

### Q3：为什么要看“最新成交量全样本分位”？

因为只看“最近 10 天曾经命中过地量”不够。你还需要知道：

```text
当前这一天是否仍然处于缩量状态。
```

所以程序同时输出：

```text
命中下跌低量分位
+ 最新成交量全样本分位
+ 最新下跌量分位
```

---

## 11. 数据源说明

候选股列表优先使用 AkShare，日线数据主要使用东方财富接口，并保留部分兜底数据源。网络不稳定时可复用本地缓存。

如果候选表无法刷新，但本地已有：

```text
data/candidate_table.csv
```

程序会尽量复用旧缓存。

---

## 12. 风险提示

本项目只是一个量化辅助筛选脚本。低量不等于必涨，卖盘枯竭也不等于买盘马上回流。任何低吸都必须结合：

```text
大盘环境
行业强弱
个股基本面
消息面变化
关键支撑位
仓位管理
止损纪律
```

不要把筛选结果理解成投资建议。
