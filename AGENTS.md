# Repository Guidelines

## Project Structure & Module Organization
This repository is a script-first Python project.

- `low_absorb_screener.py`: primary CLI screener (data fetch, cache update, scoring, output).
- `zhihu_quant_screener.py`: secondary screener variant with its own CLI workflow.
- `data/`: working data (`candidate_table.csv`, `kline/`, `run_state.json`).
- `output/`: generated reports such as `latest_low_absorb.csv` and Markdown summaries.
- `logs/`: daily execution logs (used by automation scripts).
- `scripts/`: automation helpers (`run_low_absorb_daily.sh`, `install_wsl_daily_task.ps1`).

## Build, Test, and Development Commands
- `python -m venv .venv` then `.\.venv\Scripts\Activate.ps1` (Windows) or `source .venv/bin/activate` (Linux/macOS): create and activate virtualenv.
- `python -m pip install -r requirements.txt`: install runtime dependencies.
- `python -m py_compile low_absorb_screener.py zhihu_quant_screener.py`: syntax sanity check.
- `python low_absorb_screener.py --help`: verify CLI options and defaults.
- `bash scripts/run_low_absorb_daily.sh --workers 3`: run with logging and auto-venv handling.

## Coding Style & Naming Conventions
- Use Python with 4-space indentation and UTF-8 encoding.
- Follow existing naming: `snake_case` for functions/variables/files, `PascalCase` for dataclasses.
- Keep CLI arguments explicit and long-form (for example `--min-market-cap-yi`).
- Prefer `pathlib.Path`, type hints, and small pure helper functions for calculations.
- Match current style in existing files; no formatter/linter config is currently committed.

## Testing Guidelines
There is no dedicated automated test suite in this repository yet.

- Minimum validation for changes: run `py_compile` and `--help` checks above.
- For behavior changes, run one real screener command and verify outputs in `output/` and logs in `logs/`.
- If introducing non-trivial logic, add focused tests under a new `tests/` folder (recommended `pytest` style: `test_*.py`).

## Commit & Pull Request Guidelines
- Current history shows concise subject lines with prefixes (for example `docs: ...`).
- Prefer format: `<type>: <short summary>` where `type` is `feat`, `fix`, `docs`, `refactor`, or `chore`.
- PRs should include: purpose, key parameter/logic changes, sample output impact, and any data/backfill implications.
- Link related issues/tasks when available, and include screenshots/tables only when output formatting changes.
