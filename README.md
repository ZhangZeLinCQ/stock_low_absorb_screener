# Low Absorb Screener 3.0：卖盘枯竭低吸筛选器

用于筛选 **A 股沪深主板 10cm、非 ST、大市值股票** 的低吸观察池脚本。

核心目标：从大市值股票中筛出满足以下条件的标的：

- 下跌日成交量处于历史低位
- 当前成交量也偏低
- 没有明显破位
- 位置相对安全
- 初步有买盘修复迹象
- 盈亏比相对合理

> **重要说明**：程序只能帮助提高筛选质量，不能保证低吸正确。输出结果应作为观察池或复盘清单，不应作为自动下单依据。

---

## 目录

- [1. 本版新增内容](#1-本版新增内容)
- [2. 安装](#2-安装)
- [3. 推荐运行命令](#3-推荐运行命令)
- [4. 全部参数说明](#4-全部参数说明)
- [5. 输出字段说明](#5-输出字段说明)
- [6. 评分规则](#6-评分规则)
- [7. 建议状态解释](#7-建议状态解释)
- [8. 参数调节指南](#8-参数调节指南)
- [9. 日常使用流程](#9-日常使用流程)
- [10. 常见问题](#10-常见问题)
- [11. 数据源说明](#11-数据源说明)
- [12. 风险提示](#12-风险提示)

---

## 1. 本版新增内容

相对 2.x 版本，3.0 新增：

1. **低吸综合评分**：0-100 分，综合卖盘枯竭、整体缩量、位置安全、趋势质量、确认信号、盈亏比六个维度。
2. **建议状态**：自动分类为"可低吸-确认型""可低吸-轻仓型""观察-等待放量确认""观察-等待站回均线""信号失效-跌破地量低点""弱观察-条件不足"。
3. **地量低点保护**：`--require-not-break-low-volume-low`，要求最新收盘价不能跌破最近命中低量日的最低价。
4. **均线确认过滤**：`--require-price-above-ma5` / `--require-price-above-ma10` / `--require-price-above-ma20`。
5. **风险收益比过滤**：`--min-reward-risk-ratio`，默认以最近低量日低点下方作为止损，以近 60 日高点作为目标价。
6. **当前成交量分位**：`--max-latest-volume-percentile`，最新成交量在历史全样本中的分位百分比。
7. **下跌日口径可选**：`--down-day-mode`，支持涨跌幅<0（pct）或收盘价<开盘价（green）。
8. **成交量单位归一化**：自动检测并修复不同数据源（股 vs 手）的成交量单位不一致问题。
9. **多数据源容灾**：候选表依次尝试 AkShare、腾讯行情、东方财富；日线依次尝试东方财富、新浪、AkShare。

---

## 2. 安装

进入项目目录：

```bash
cd low_absorb_screener3_0
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

如果这套筛不到股票，先去掉 `--require-confirm-signal`，再把 `--min-low-absorb-score 75` 调成 70。

---

## 4. 全部参数说明

### 4.1 股票池参数

| 参数 | 类型 | 默认值 | 含义 |
|---|---|---|---|
| `--min-market-cap-yi` | float | 500.0 | 最低总市值，单位亿元 |
| `--refresh-candidates` | flag | 否 | 强制刷新候选股票池缓存 |
| `--candidate-output` | path | data/candidate_table.csv | 候选表保存路径 |
| `--data-dir` | path | data/ | 数据保存目录 |

程序默认只保留：沪深主板 10cm（600/601/603/605/000/001/002/003 开头）、非 ST / 非 *ST、总市值大于阈值。

---

### 4.2 地量识别参数

| 参数 | 类型 | 默认值 | 含义 |
|---|---|---|---|
| `--lookback-days` | int | 240 | 历史统计周期（交易日），必须 >= 30 |
| `--recent-days` | int | 10 | 最近观察窗口（交易日） |
| `--min-hit-days` | int | 3 | 最近窗口内至少命中几天 |
| `--lowest-down-percent` | float | 10.0 | 下跌日成交量进入历史最低百分之几 |
| `--down-day-mode` | str | pct | 下跌日定义：pct=涨跌幅<0，green=收盘价<开盘价 |

示例：

```bash
--lookback-days 240 --recent-days 10 --min-hit-days 3 --lowest-down-percent 5
```

含义：过去 240 个交易日内，把所有下跌日成交量从低到高排序；最近 10 个交易日内，至少 3 个下跌日的成交量进入历史最低 5%。

---

### 4.3 当前成交量分位参数

| 参数 | 类型 | 默认值 | 含义 |
|---|---|---|---|
| `--max-latest-volume-percentile` | float | 0（不启用） | 最新成交量必须处于历史全样本最低多少百分比以内 |

示例：`--max-latest-volume-percentile 20` 表示最新成交量必须处于过去 lookback-days 有效样本的最低 20% 以内。

---

### 4.4 流动性与整体缩量参数

| 参数 | 类型 | 默认值 | 含义 |
|---|---|---|---|
| `--min-avg-amount-yi` | float | 0（不启用） | 近 20 日平均成交额下限，单位亿元 |
| `--recent-volume-shrink-ratio` | float | 0（不启用） | 近 5 日均量 / 近 60 日均量上限 |

示例：`--min-avg-amount-yi 3 --recent-volume-shrink-ratio 0.6` 表示近 20 日平均成交额至少 3 亿元，且近 5 日均量不超过近 60 日均量的 60%。

---

### 4.5 破位过滤参数

| 参数 | 类型 | 默认值 | 含义 |
|---|---|---|---|
| `--max-20d-drop-pct` | float | 0（不启用） | 相对近 20 日最高价的最大允许回撤百分比 |
| `--min-distance-from-60d-low-pct` | float | 0（不启用） | 最新价距离近 60 日低点至少多少百分比 |
| `--require-not-break-low-volume-low` | flag | 否 | 要求最新价不能跌破最近命中地量日低点 |

`--require-not-break-low-volume-low` 很关键：如果地量日之后继续跌破地量日低点，说明原来的卖盘枯竭信号大概率失效。

---

### 4.6 均线确认参数

| 参数 | 类型 | 默认值 | 含义 |
|---|---|---|---|
| `--require-price-above-ma5` | flag | 否 | 最新价必须站上 MA5 |
| `--require-price-above-ma10` | flag | 否 | 最新价必须站上 MA10 |
| `--require-price-above-ma20` | flag | 否 | 最新价必须站上 MA20 |

建议：观察池不加均线过滤；确认池加 `--require-price-above-ma5`；更保守加 MA10 或 MA20。

---

### 4.7 确认信号参数

| 参数 | 类型 | 默认值 | 含义 |
|---|---|---|---|
| `--require-confirm-signal` | flag | 否 | 只保留出现确认信号的股票 |

确认信号定义：最近一次命中下跌地量日之后 1-3 个交易日内，涨跌幅 > 0，收盘价突破低量日最高价，成交量大于低量日前后 5 日均量。

这个参数会大幅减少结果数量，适合找更接近买点的股票。

---

### 4.8 盈亏比与评分参数

| 参数 | 类型 | 默认值 | 含义 |
|---|---|---|---|
| `--min-reward-risk-ratio` | float | 0（不启用） | 最低盈亏比 |
| `--min-low-absorb-score` | float | 0（不启用） | 最低低吸综合评分（0-100） |

默认计算方式：参考止损价 = 最近命中低量日最低价 × 0.98，参考目标价 = 近 60 日最高价，盈亏比 = (目标价 - 最新收盘价) / (最新收盘价 - 止损价)。

---

### 4.9 涨跌停处理参数

| 参数 | 类型 | 默认值 | 含义 |
|---|---|---|---|
| `--limit-pct-threshold` | float | 9.8 | 识别涨停/跌停的涨跌幅阈值（%） |
| `--keep-limit-days` | flag | 否 | 保留涨跌停日（默认排除） |

默认会从历史排序样本和最近命中样本中排除涨跌停日，避免因涨跌停导致的成交量失真。

---

### 4.10 日期控制参数

| 参数 | 类型 | 默认值 | 含义 |
|---|---|---|---|
| `--end-date` | str | 自动 | 统计截止日期 YYYYMMDD |
| `--include-today` | flag | 否 | 强制包含今日数据 |
| `--exclude-today` | flag | 否 | 强制不包含今日数据 |
| `--history-days` | int | 730 | 本地保存的历史自然日跨度 |

默认逻辑：下午 4 点后运行自动包含今日，之前则使用上一交易日。

---

### 4.11 并发与缓存参数

| 参数 | 类型 | 默认值 | 含义 |
|---|---|---|---|
| `--workers` | int | 6 | 日线数据获取的并发线程数 |
| `--compute-workers` | int | 1 | 筛选计算的并发线程数 |
| `--skip-kline-update` | flag | 否 | 只使用本地已有 K 线，不联网更新 |
| `--force-kline-update` | flag | 否 | 忽略本地缓存，重新拉取候选股最近两年日线 |
| `--force-renormalize` | flag | 否 | 对已有 K 线缓存强制重新做成交量单位归一化 |

---

### 4.12 输出参数

| 参数 | 类型 | 默认值 | 含义 |
|---|---|---|---|
| `--output` | path | 自动 | 结果 CSV 路径，默认 `output/low_absorb_日期_参数.csv` |

结果会同时输出到：
- `output/low_absorb_日期_参数.csv`（带参数标记的历史结果）
- `output/latest_low_absorb.csv`（最新结果副本）
- `output/latest_low_absorb.md`（Markdown 格式，方便查看）

---

## 5. 输出字段说明

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
| `是否跌破低量日低点` | 如果为"是"，信号偏失效 |
| `MA5` / `MA10` / `MA20` / `MA60` | 均线位置 |
| `参考止损价` | 默认按最近低量日低点 × 0.98 计算 |
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

- **80 分以上**：优先观察；如果同时有确认信号，接近确认型低吸候选。
- **70-80 分**：观察池核心对象，需要等确认或结合人工复盘。
- **60-70 分**：弱观察，可能只是缩量但买点不充分。
- **60 分以下**：条件不足，不建议优先看。

---

## 7. 建议状态解释

| 建议状态 | 含义 |
|---|---|
| `可低吸-确认型` | 评分 >= 80、有确认信号、盈亏比 >= 2 |
| `可低吸-轻仓型` | 评分 >= 75、站回 MA5 和 MA10、盈亏比 >= 1.5 |
| `观察-等待放量确认` | 评分 >= 70、站回 MA5，但还需买盘回流确认 |
| `观察-等待站回均线` | 评分 >= 60，趋势修复不足 |
| `信号失效-跌破地量低点` | 地量之后继续破位，原信号失效 |
| `弱观察-条件不足` | 评分 < 60，条件不够好 |

---

## 8. 参数调节指南

### 结果太多时，加严：

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

### 结果太少时，放宽：

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

1. 跑"平衡观察池"或"严格观察池"
2. 按低吸综合评分排序
3. 优先看 70 分以上
4. 剔除明显利空、行业走弱、基本面恶化的股票
5. 等待站回 MA5 / 放量阳线 / 不破地量低点
6. 只做盈亏比合理的票

程序适合做：初筛、复盘、观察池生成、低吸候选排序。

不适合做：自动下单、无脑买入、替代基本面和消息面判断。

---

## 10. 常见问题

### Q1：为什么结果为空？

可能原因：
1. 参数太严格
2. 当前市场没有符合条件的票
3. 数据源当天还没有更新
4. 网络导致日线缓存不完整
5. 加了 `--require-confirm-signal` 导致大幅过滤

先尝试 `--min-low-absorb-score 60` 或去掉 `--require-confirm-signal`。

### Q2：什么时候加 `--require-confirm-signal`？

当你想找更接近买点的股票时加。早期观察池不要加，否则容易漏掉刚开始缩量的股票。

### Q3：为什么要看"最新成交量全样本分位"？

因为只看"最近 10 天曾经命中过地量"不够，你还需要知道当前这一天是否仍然处于缩量状态。所以程序同时输出命中下跌低量分位、最新成交量全样本分位、最新下跌量分位三个指标。

### Q4：`--down-day-mode` 应该用 pct 还是 green？

默认 `pct`（涨跌幅<0）更适合卖盘枯竭筛选，因为有些 K 线虽然收盘价高于开盘价（红 K），但实际上是在下跌（相比昨日收盘）。`green` 模式更严格，只看收盘价<开盘价的 K 线。

### Q5：成交量单位归一化是什么？

不同数据源可能用不同单位报告成交量（股 vs 手，1 手 = 100 股）。程序会自动检测并统一，确保成交量排序准确。如需手动修复，可加 `--force-renormalize`。

---

## 11. 数据源说明

- **候选股列表**：优先使用 AkShare，失败后依次尝试腾讯行情、东方财富。
- **日线数据**：主要使用东方财富接口，失败后依次尝试新浪、AkShare。
- **本地缓存**：候选表缓存 20 小时，日线增量更新。

如果候选表无法刷新但本地已有 `data/candidate_table.csv`，程序会自动复用旧缓存。

---

## 12. 风险提示

本项目只是一个量化辅助筛选脚本。低量不等于必涨，卖盘枯竭也不等于买盘马上回流。任何低吸都必须结合：大盘环境、行业强弱、个股基本面、消息面变化、关键支撑位、仓位管理、止损纪律。

不要把筛选结果理解成投资建议。

---

## 4.0 胜率优化补充

本压缩包中的主程序已升级为 4.0 版，新增：

- `--theme-csv` / `--require-theme` / `--min-theme-score`：按研究报告主线筛选或加权排序。
- `--theme-score-weight`：把主题景气度纳入最终评分。
- `--min-final-score`：按最终评分过滤。
- `--market-filter` / `--market-index-code`：按上证指数、深成指、沪深300等指数的 MA20/MA60 状态控制是否输出结果。

详细使用方法见：`README_4_0_胜率优化版.md`。
