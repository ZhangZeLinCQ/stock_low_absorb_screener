#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${PROJECT_DIR}/logs"
mkdir -p "${LOG_DIR}"

cd "${PROJECT_DIR}"

if [[ -d "${PROJECT_DIR}/../.venv" ]]; then
  # 兼容 GPgetter 仓库根目录下的统一虚拟环境
  # shellcheck disable=SC1091
  source "${PROJECT_DIR}/../.venv/bin/activate"
elif [[ -d "${PROJECT_DIR}/.venv" ]]; then
  # 兼容低吸子项目自己的虚拟环境
  # shellcheck disable=SC1091
  source "${PROJECT_DIR}/.venv/bin/activate"
else
  python3 -m venv "${PROJECT_DIR}/.venv"
  # shellcheck disable=SC1091
  source "${PROJECT_DIR}/.venv/bin/activate"
fi

python3 -m pip install -U pip >/dev/null
python3 -m pip install -r requirements.txt

LOG_FILE="${LOG_DIR}/low_absorb_$(date +%Y%m%d).log"
python3 low_absorb_screener.py "$@" 2>&1 | tee -a "${LOG_FILE}"
