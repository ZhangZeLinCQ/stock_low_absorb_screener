# Low Absorb Screener 4.0：胜率优化版

本版基于原 `low_absorb_screener.py` 继续增强，核心思路不是“找更多股票”，而是减少低吸误判：

1. 继续保留原有低量下跌、涨跌停排除、整体缩量、破位过滤、均线确认、确认信号、盈亏比、综合评分。
2. 新增“主题景气度”评分，把研究报告里更容易有资金反复的方向纳入排序：AI算力、存储芯片、人形机器人、工业母机、商业航天、国产替代。
3. 新增“大盘环境过滤”，弱市中低吸胜率通常下降，可要求指数站上 MA20 / MA60 后再输出候选。
4. 新增“最终评分”，公式默认：`最终评分 = 低吸综合评分 * 90% + 主题评分 * 10%`。

> 注意：本项目只是观察池/复盘辅助工具，不构成投资建议，也不能保证胜率。

---

## 新增文件

- `low_absorb_screener.py`：已修改后的主程序。
- `config/hot_theme_codes.csv`：根据当前研究主线预置的热点主题股票池，可自行增删。
- `requirements.txt`：运行依赖。
- `README_4_0_胜率优化版.md`：本说明文件。

---

## 快速安装

```bash
cd low_absorb_screener4_0
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
python3 -m py_compile low_absorb_screener.py
python3 low_absorb_screener.py --help
```

Windows PowerShell：

```powershell
cd low_absorb_screener4_0
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m py_compile low_absorb_screener.py
python low_absorb_screener.py --help
```

---

## 推荐命令 1：日常平衡观察池

适合先筛出一批候选，再人工看板块和K线。

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
  --theme-score-weight 10 \
  --min-final-score 65 \
  --workers 3
```

---

## 推荐命令 2：提高胜率的严格观察池

更适合你当前想要的“少一点，但质量高一点”。

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
  --theme-score-weight 15 \
  --min-final-score 72 \
  --workers 3
```

---

## 推荐命令 3：只做研究报告主线

只保留 AI算力、存储芯片、人形机器人、工业母机、商业航天、国产替代等主题相关候选。

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
  --require-theme \
  --min-theme-score 80 \
  --theme-score-weight 20 \
  --min-final-score 75 \
  --workers 3
```

---

## 推荐命令 4：大盘环境确认版

弱市里减少左侧接飞刀。要求上证指数站上 MA20 后才输出结果。

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
  --min-reward-risk-ratio 1.5 \
  --theme-score-weight 15 \
  --market-filter ma20 \
  --market-index-code 000001 \
  --min-final-score 75 \
  --workers 3
```

如果这条筛不出结果，可以先去掉 `--require-price-above-ma5`，或者把 `--market-filter ma20` 改回 `--market-filter off`。

---

## 新增参数说明

| 参数 | 含义 |
|---|---|
| `--theme-csv` | 主题股票池 CSV，默认 `config/hot_theme_codes.csv` |
| `--theme-score-weight` | 主题评分进入最终排序的权重，默认 10，最高允许 50 |
| `--min-theme-score` | 最低主题评分，0 表示不启用 |
| `--require-theme` | 只保留命中主题池/主题关键词的股票 |
| `--min-final-score` | 最低最终评分，0 表示不启用 |
| `--market-filter` | 大盘过滤：`off` / `ma20` / `ma60` / `ma20-and-ma60` / `ma20-or-ma60` |
| `--market-index-code` | 大盘过滤指数，默认 `000001`；可用 `399001`、`000300` |

---

## 如何维护主题股票池

编辑：

```bash
config/hot_theme_codes.csv
```

格式：

```csv
股票代码,股票名称,主题标签,主题评分,备注
601138,工业富联,AI算力/服务器/液冷/机器人,96,AI服务器与算力产业链核心主板标的
```

建议：

- 强主线核心票给 90-100。
- 正相关但弹性/纯度一般给 80-89。
- 边缘概念或仅题材沾边给 70-79。
- 不确定的不要加入，避免主题评分污染排序。

---

## 输出字段变化

新增：

- `所属行业`
- `相关概念`
- `主题标签`
- `主题评分`
- `最终评分`

排序逻辑变为：

1. 最终评分高优先；
2. 低吸综合评分高优先；
3. 命中低量天数多优先；
4. 命中分位更低优先；
5. 盈亏比更高优先；
6. 市值更大优先。

---

## 实盘使用纪律

筛选结果只做观察池。真正买入前至少再看：

1. 是否处在研究报告主线或近期市场强势方向；
2. 是否跌破最近地量日低点；
3. 是否站回 MA5 / MA10；
4. 是否出现放量阳线确认；
5. 盈亏比是否至少 1.5；
6. 个股是否有利空、解禁、业绩雷、减持。

