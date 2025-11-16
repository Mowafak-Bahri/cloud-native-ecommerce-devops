#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m"

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Options:
  --days N        Number of days to analyze (default 7)
  --month YYYY-MM Specific month to analyze
  --today         Only today's costs
  --json          Output JSON summary instead of table
  --budget USD    Budget threshold (default 50)
  -h, --help      Show this help message
USAGE
}

log_error() { printf "%b\n" "${RED}[ERROR]${NC} $*" >&2; }

require_aws() {
  if ! command -v aws >/dev/null 2>&1; then
    log_error "AWS CLI required"
    exit 2
  fi
}

MODE="days"
DAYS=7
MONTH=""
OUTPUT_JSON=false
BUDGET=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --days)
      MODE="days"
      DAYS="$2"
      shift 2
      ;;
    --month)
      MODE="month"
      MONTH="$2"
      shift 2
      ;;
    --today)
      MODE="today"
      shift
      ;;
    --json)
      OUTPUT_JSON=true
      shift
      ;;
    --budget)
      BUDGET="$2"
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

require_aws

read START_DATE END_DATE < <(python3 - "$MODE" "$DAYS" "$MONTH" <<'PY'
import sys, datetime
mode, days, month = sys.argv[1], int(sys.argv[2]), sys.argv[3]
today = datetime.date.today()
if mode == 'today':
    start = today
    end = today + datetime.timedelta(days=1)
elif mode == 'month':
    if not month:
        raise SystemExit('Month format YYYY-MM required for --month')
    year, mon = map(int, month.split('-'))
    start = datetime.date(year, mon, 1)
    if mon == 12:
        end = datetime.date(year + 1, 1, 1)
    else:
        end = datetime.date(year, mon + 1, 1)
else:
    n = max(1, days)
    start = today - datetime.timedelta(days=n-1)
    end = today + datetime.timedelta(days=1)
print(start.isoformat(), end.isoformat())
PY
)

DATA=$(aws ce get-cost-and-usage \
  --time-period Start=$START_DATE,End=$END_DATE \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE)

python3 - "$DATA" "$OUTPUT_JSON" "$BUDGET" <<'PY'
import json, sys
from decimal import Decimal
from collections import defaultdict

data = json.loads(sys.argv[1])
want_json = sys.argv[2].lower() == 'true'
budget = Decimal(sys.argv[3])

CATEGORY_MAP = {
    'ECS': ['Elastic Container Service', 'ECS', 'Fargate'],
    'RDS': ['Relational Database Service', 'RDS'],
    'ALB': ['Application Load Balancer', 'Elastic Load Balancing'],
    'NAT': ['NAT Gateway'],
    'DataTransfer': ['Data Transfer', 'CloudFront Out'],
}

def map_category(service_name: str) -> str:
    for category, keywords in CATEGORY_MAP.items():
        if any(keyword in service_name for keyword in keywords):
            return category
    return 'Other'

rows = []
total = Decimal('0')

for item in data['ResultsByTime']:
    date = item['TimePeriod']['Start']
    buckets = defaultdict(Decimal)
    day_total = Decimal('0')
    for group in item.get('Groups', []):
        amount = Decimal(group['Metrics']['BlendedCost']['Amount'])
        service_name = group['Keys'][0] or 'Other'
        cat = map_category(service_name)
        buckets[cat] += amount
        day_total += amount
    total += day_total
    rows.append({'date': date, 'buckets': buckets, 'total': day_total})

num_days = len(rows)
average = (total / num_days) if num_days else Decimal('0')
projected = average * Decimal('30')

summary = {
    'total': float(total),
    'average_daily': float(average),
    'projected_monthly': float(projected),
    'budget': float(budget)
}

services_total = defaultdict(Decimal)
for item in data['ResultsByTime']:
    for group in item.get('Groups', []):
        svc = group['Keys'][0] or 'Other'
        services_total[svc] += Decimal(group['Metrics']['BlendedCost']['Amount'])

suggestions = []
if projected > budget:
    suggestions.append('Projected spend exceeds budget. Consider scaling down idle services or enabling auto scaling policies.')
    suggestions.append('Review RDS instance size and enable stop/start schedule for dev environments.')

if want_json:
    output = {
        'summary': summary,
        'daily': [
            {
                'date': row['date'],
                'ecs': float(row['buckets'].get('ECS', Decimal('0'))),
                'rds': float(row['buckets'].get('RDS', Decimal('0'))),
                'alb': float(row['buckets'].get('ALB', Decimal('0'))),
                'nat': float(row['buckets'].get('NAT', Decimal('0'))),
                'data_transfer': float(row['buckets'].get('DataTransfer', Decimal('0'))),
                'other': float(row['buckets'].get('Other', Decimal('0'))),
                'total': float(row['total'])
            }
            for row in rows
        ],
        'top_services': [
            {'service': svc, 'amount': float(amount)}
            for svc, amount in sorted(services_total.items(), key=lambda x: x[1], reverse=True)[:5]
        ],
        'alerts': suggestions,
    }
    print(json.dumps(output, indent=2))
else:
    headers = ['Date', 'ECS', 'RDS', 'ALB', 'NAT', 'Transfer', 'Other', 'Total']
    widths = [12, 10, 10, 10, 10, 11, 10, 10]
    def fmt_row(values):
        return "┌" + "┬".join("─" * w for w in widths) + "┐" if values is None else None
    top_border = "┌" + "┬".join("─" * w for w in widths) + "┐"
    mid_border = "├" + "┼".join("─" * w for w in widths) + "┤"
    bottom_border = "└" + "┴".join("─" * w for w in widths) + "┘"
    print(top_border)
    print("│" + "│".join(f"{h:^{w}}" for h, w in zip(headers, widths)) + "│")
    print(mid_border)
    for row in rows:
        vals = [
            row['date'],
            f"${row['buckets'].get('ECS', Decimal('0')):.2f}",
            f"${row['buckets'].get('RDS', Decimal('0')):.2f}",
            f"${row['buckets'].get('ALB', Decimal('0')):.2f}",
            f"${row['buckets'].get('NAT', Decimal('0')):.2f}",
            f"${row['buckets'].get('DataTransfer', Decimal('0')):.2f}",
            f"${row['buckets'].get('Other', Decimal('0')):.2f}",
            f"${row['total']:.2f}"
        ]
        print("│" + "│".join(f"{value:^{width}}" for value, width in zip(vals, widths)) + "│")
    print(bottom_border)
    print(f"Total cost: ${total:.2f}")
    print(f"Average daily: ${average:.2f}")
    if projected > budget:
        print(f"Projected monthly: ${projected:.2f} (budget ${budget:.2f}) ⚠️ exceeds budget")
    else:
        print(f"Projected monthly: ${projected:.2f} (budget ${budget:.2f}) ✅ within budget")
    if suggestions:
        print("\nSuggestions:")
        for tip in suggestions:
            print(f"- {tip}")
    top_items = sorted(services_total.items(), key=lambda x: x[1], reverse=True)[:5]
    print("\nTop services:")
    for name, amount in top_items:
        print(f"- {name}: ${amount:.2f}")
PY
