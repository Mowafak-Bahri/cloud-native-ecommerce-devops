#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m"

KEEP_STACK=false
REPORT_JSON=""

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Spin up docker-compose stack and run functional API checks.

Options:
  --keep           Keep containers running after tests
  --report PATH    Write JSON report to PATH (default tests/results/<timestamp>.json)
  -h, --help       Show help
USAGE
}

log() { printf "%b\n" "$*"; }
log_info() { log "${GREEN}[INFO]${NC} $*"; }
log_warn() { log "${YELLOW}[WARN]${NC} $*"; }
log_error() { log "${RED}[ERROR]${NC} $*"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
  elif command_exists docker-compose; then
    docker-compose "$@"
  else
    log_error "docker compose or docker-compose not available"
    exit 2
  fi
}

require_tools() {
  local missing=()
  for tool in docker curl jq python3; do
    if ! command_exists "$tool"; then
      missing+=("$tool")
    fi
  done
  if ((${#missing[@]} > 0)); then
    log_error "Missing prerequisites: ${missing[*]}"
    exit 2
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep)
      KEEP_STACK=true
      shift
      ;;
    --report)
      REPORT_JSON="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

require_tools
mkdir -p "${REPO_ROOT}/tests/results"
if [[ -z "$REPORT_JSON" ]]; then
  REPORT_JSON="${REPO_ROOT}/tests/results/test-$(date +%Y%m%d-%H%M%S).json"
fi

RESULT_FILE=$(mktemp)
PASS_COUNT=0
TEST_COUNT=0

cleanup() {
  if $KEEP_STACK; then
    log_info "Leaving containers up (--keep)"
  else
    log_info "Stopping docker-compose stack"
    COMPOSE_PROJECT_NAME=ecommerce-dev compose -f "$COMPOSE_FILE" down -v >/dev/null 2>&1 || true
  fi
  rm -f "$RESULT_FILE"
}

trap cleanup EXIT

measure_request() {
  local method="$1" url="$2" body="${3:-}"
  local tmp
  tmp=$(mktemp)
  local start end code duration
  start=$(date +%s%3N)
  if [[ -n "$body" ]]; then
    code=$(curl -sS -o "$tmp" -w "%{http_code}" -H 'Content-Type: application/json' -X "$method" -d "$body" "$url") || true
  else
    code=$(curl -sS -o "$tmp" -w "%{http_code}" "$url") || true
  fi
  end=$(date +%s%3N)
  duration=$((end - start))
  echo "$code" "$duration" "$tmp"
}

run_test() {
  local name="$1" method="$2" url="$3" body="$4" validator="$5"
  local result code duration tmp
  result=$(measure_request "$method" "$url" "$body")
  code=$(awk '{print $1}' <<<"$result")
  duration=$(awk '{print $2}' <<<"$result")
  tmp=$(awk '{print $3}' <<<"$result")

  TEST_COUNT=$((TEST_COUNT + 1))
  local passed=0
  if eval "$validator"; then
    passed=1
    PASS_COUNT=$((PASS_COUNT + 1))
    printf "%-50s %6s %8sms\n" "$name" "${GREEN}PASS${NC}" "$duration"
  else
    printf "%-50s %6s %8sms\n" "$name" "${RED}FAIL${NC}" "$duration"
  fi

  printf '%s|%s|%s\n' "$name" "$passed" "$duration" >> "$RESULT_FILE"
  rm -f "$tmp"
}

wait_for_postgres() {
  log_info "Waiting for PostgreSQL"
  local attempt=0
  while true; do
    if COMPOSE_PROJECT_NAME=ecommerce-dev compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U postgres >/dev/null 2>&1; then
      break
    fi
    attempt=$((attempt + 1))
    if (( attempt > 30 )); then
      log_error "PostgreSQL did not become ready"
      exit 1
    fi
    sleep 2
  done
}

wait_for_service() {
  local name="$1" url="$2"
  log_info "Waiting for ${name}"
  local attempt=0
  until curl -sf "$url" >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    if (( attempt > 30 )); then
      log_error "${name} did not become healthy"
      exit 1
    fi
    sleep 2
  done
}

start_stack() {
  log_info "Starting docker-compose stack"
  COMPOSE_PROJECT_NAME=ecommerce-dev compose -f "$COMPOSE_FILE" up -d --build
  wait_for_postgres
  wait_for_service "Product service" "http://localhost:8000/health"
  wait_for_service "Order service" "http://localhost:8001/health"
  wait_for_service "Frontend" "http://localhost:3000/health"
}

start_stack

printf "%-50s %6s %8s\n" "Test" "Status" "Time"
printf "%-50s %6s %8s\n" "--------------------------------------------------" "------" "--------"

PRODUCT_URL="http://localhost:8000"
ORDER_URL="http://localhost:8001"

run_test "GET /products returns seeds" "GET" "${PRODUCT_URL}/products" "" '[[ "$code" -eq 200 ]] && jq -e "length >= 3" "$tmp" >/dev/null'
run_test "GET /products/1 returns product" "GET" "${PRODUCT_URL}/products/1" "" '[[ "$code" -eq 200 ]] && [[ $(jq -r ".id" "$tmp") -eq 1 ]]'
run_test "POST /products creates product" "POST" "${PRODUCT_URL}/products" '{"name":"Test Product","description":"local test","price":55.5,"stock":10}' '[[ "$code" -eq 201 ]] && jq -e "has(\"id\")" "$tmp" >/dev/null'
run_test "POST /products negative price" "POST" "${PRODUCT_URL}/products" '{"name":"Bad","description":"bad","price":-1,"stock":1}' '[[ "$code" -eq 422 ]]'
run_test "POST /orders valid" "POST" "${ORDER_URL}/orders" '{"product_id":1,"quantity":1}' '[[ "$code" -eq 201 ]] && jq -e "has(\"total_price\")" "$tmp" >/dev/null'
run_test "GET /orders lists" "GET" "${ORDER_URL}/orders" "" '[[ "$code" -eq 200 ]] && jq -e "type==\"array\"" "$tmp" >/dev/null'
run_test "POST /orders quantity > stock" "POST" "${ORDER_URL}/orders" '{"product_id":1,"quantity":999999}' '[[ "$code" -eq 400 ]]'
run_test "POST /orders invalid product" "POST" "${ORDER_URL}/orders" '{"product_id":999999,"quantity":1}' '[[ "$code" -eq 404 ]]'

PERCENT=$(python3 - <<PY
passed=$PASS_COUNT
total=$TEST_COUNT
print(0 if total==0 else round((passed/total)*100, 2))
PY
)
printf "\nSummary: %d/%d tests passed (%.2f%%)\n" "$PASS_COUNT" "$TEST_COUNT" "$PERCENT"

python3 - "$RESULT_FILE" "$REPORT_JSON" <<'PY'
import json, sys
src, dest = sys.argv[1], sys.argv[2]
results = []
with open(src, 'r', encoding='utf-8') as fh:
    for line in fh:
        name, passed, duration = line.strip().split('|')
        results.append({
            "name": name,
            "passed": bool(int(passed)),
            "duration_ms": int(duration)
        })
summary = {
    "total": len(results),
    "passed": sum(1 for r in results if r["passed"])
}
report = {"summary": summary, "tests": results}
with open(dest, 'w', encoding='utf-8') as fh:
    json.dump(report, fh, indent=2)
print(f"Report written to {dest}")
PY
