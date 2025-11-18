#!/usr/bin/env bash

###############################################################################
# Master Test Runner
# Runs all tests (local and/or AWS) with comprehensive reporting
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
BOLD="\033[1m"
NC="\033[0m"

# Configuration
LOCAL_ONLY=false
AWS_ONLY=false
QUICK_MODE=false
VERBOSE=false
KEEP_CONTAINERS=false
GENERATE_REPORT=true
REPORT_DIR="${SCRIPT_DIR}/tests/results"

# Logging functions
log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$*"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
log_header() { printf "\n${BOLD}${BLUE}═══════════════════════════════════════════${NC}\n${BOLD}${BLUE}  %s${NC}\n${BOLD}${BLUE}═══════════════════════════════════════════${NC}\n" "$*"; }

usage() {
    cat <<EOF
${BOLD}E-Commerce DevOps Test Runner${NC}

${BOLD}USAGE:${NC}
    $(basename "$0") [OPTIONS]

${BOLD}DESCRIPTION:${NC}
    Master test runner for the cloud-native e-commerce platform.
    Run all tests with a single command!

${BOLD}OPTIONS:${NC}
    --local-only        Run only local tests (Docker Compose)
    --aws-only          Run only AWS deployment tests
    --quick             Quick mode - health checks only
    --verbose           Show detailed test output
    --keep-containers   Keep Docker containers running after tests
    --no-report         Don't generate test reports
    -h, --help          Show this help message

${BOLD}EXAMPLES:${NC}
    # Test everything locally (recommended for developers)
    ${GREEN}./run_all_tests.sh --local-only${NC}

    # Quick health check
    ${GREEN}./run_all_tests.sh --quick${NC}

    # Test with verbose output and keep containers for debugging
    ${GREEN}./run_all_tests.sh --verbose --keep-containers${NC}

    # Test AWS deployment
    ${GREEN}./run_all_tests.sh --aws-only${NC}

    # Test everything (local + AWS)
    ${GREEN}./run_all_tests.sh${NC}

${BOLD}PREREQUISITES:${NC}
    Local Tests:
        ✓ Docker & Docker Compose
        ✓ curl, jq

    AWS Tests:
        ✓ AWS CLI configured
        ✓ Valid AWS credentials
        ✓ Terraform infrastructure deployed

${BOLD}OUTPUT:${NC}
    - Console output with color-coded results
    - JSON report: ${REPORT_DIR}/test-report-<timestamp>.json
    - HTML report: ${REPORT_DIR}/test-report-<timestamp>.html

${BOLD}MORE HELP:${NC}
    For detailed testing documentation, see:
        tests/TESTING.md

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --local-only)
            LOCAL_ONLY=true
            shift
            ;;
        --aws-only)
            AWS_ONLY=true
            shift
            ;;
        --quick)
            QUICK_MODE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --keep-containers)
            KEEP_CONTAINERS=true
            shift
            ;;
        --no-report)
            GENERATE_REPORT=false
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo ""
            usage
            exit 1
            ;;
    esac
done

# Check if both --local-only and --aws-only are specified
if $LOCAL_ONLY && $AWS_ONLY; then
    log_error "Cannot specify both --local-only and --aws-only"
    exit 1
fi

# Print banner
print_banner() {
    echo ""
    echo "${BOLD}${BLUE}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║     🚀 Cloud-Native E-Commerce DevOps Test Suite 🚀     ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo "${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing=()

    # Check common tools
    for cmd in curl jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    # Check Docker if running local tests
    if ! $AWS_ONLY; then
        if ! command -v docker >/dev/null 2>&1; then
            missing+=("docker")
        fi
        if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
            missing+=("docker-compose")
        fi
    fi

    # Check AWS CLI if running AWS tests
    if ! $LOCAL_ONLY; then
        if ! command -v aws >/dev/null 2>&1; then
            log_warn "AWS CLI not found - skipping AWS tests"
            LOCAL_ONLY=true
        fi
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        echo ""
        log_info "Please install missing tools and try again"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Run local tests
run_local_tests() {
    log_header "LOCAL TESTS"

    if $QUICK_MODE; then
        log_info "Running quick health checks only..."
        local opts=""
        $VERBOSE && opts="$opts --verbose"
        $KEEP_CONTAINERS && opts="$opts --keep-containers"

        # Just run health checks
        if bash "${SCRIPT_DIR}/tests/local/test_health.sh" $opts; then
            return 0
        else
            return 1
        fi
    else
        log_info "Running full local test suite..."
        local opts=""
        $VERBOSE && opts="$opts --verbose"
        $KEEP_CONTAINERS && opts="$opts --keep-containers"

        if bash "${SCRIPT_DIR}/tests/local/test_all.sh" $opts; then
            return 0
        else
            return 1
        fi
    fi
}

# Run AWS tests
run_aws_tests() {
    log_header "AWS TESTS"

    log_info "Running AWS deployment tests..."

    # Check AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log_error "AWS credentials not configured"
        log_info "Run 'aws configure' to set up credentials"
        return 1
    fi

    local opts=""
    $VERBOSE && opts="$opts --verbose"

    if bash "${SCRIPT_DIR}/tests/aws/test_all_aws.sh" $opts; then
        return 0
    else
        return 1
    fi
}

# Generate HTML report
generate_html_report() {
    local json_report="$1"
    local html_report="${json_report%.json}.html"

    cat > "$html_report" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>E-Commerce Test Report</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        .header h1 { margin: 0; }
        .header p { margin: 10px 0 0 0; opacity: 0.9; }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .summary-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .summary-card h3 { margin: 0 0 10px 0; color: #666; font-size: 14px; }
        .summary-card .value { font-size: 32px; font-weight: bold; }
        .summary-card.total .value { color: #667eea; }
        .summary-card.passed .value { color: #48bb78; }
        .summary-card.failed .value { color: #f56565; }
        .summary-card.skipped .value { color: #ed8936; }
        .tests-table {
            background: white;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }
        th {
            background: #f7fafc;
            font-weight: 600;
            color: #4a5568;
        }
        .badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }
        .badge.pass { background: #c6f6d5; color: #22543d; }
        .badge.fail { background: #fed7d7; color: #742a2a; }
        .badge.skip { background: #feebc8; color: #7c2d12; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 E-Commerce Test Report</h1>
        <p id="timestamp"></p>
    </div>

    <div class="summary">
        <div class="summary-card total">
            <h3>Total Tests</h3>
            <div class="value" id="total">0</div>
        </div>
        <div class="summary-card passed">
            <h3>Passed</h3>
            <div class="value" id="passed">0</div>
        </div>
        <div class="summary-card failed">
            <h3>Failed</h3>
            <div class="value" id="failed">0</div>
        </div>
        <div class="summary-card skipped">
            <h3>Skipped</h3>
            <div class="value" id="skipped">0</div>
        </div>
    </div>

    <div class="tests-table">
        <table>
            <thead>
                <tr>
                    <th>Test Suite</th>
                    <th>Status</th>
                    <th>Details</th>
                </tr>
            </thead>
            <tbody id="results">
            </tbody>
        </table>
    </div>

    <script>
        // This will be populated by the test runner
        const reportData = ___REPORT_DATA___;

        document.getElementById('timestamp').textContent = new Date(reportData.timestamp).toLocaleString();
        document.getElementById('total').textContent = reportData.summary.total;
        document.getElementById('passed').textContent = reportData.summary.passed;
        document.getElementById('failed').textContent = reportData.summary.failed;
        document.getElementById('skipped').textContent = reportData.summary.skipped;

        const tbody = document.getElementById('results');
        reportData.tests.forEach(test => {
            const tr = document.createElement('tr');
            const badgeClass = test.status.toLowerCase();
            tr.innerHTML = `
                <td>${test.name}</td>
                <td><span class="badge ${badgeClass}">${test.status}</span></td>
                <td>${test.details || '-'}</td>
            `;
            tbody.appendChild(tr);
        });
    </script>
</body>
</html>
EOF

    # Read JSON and inject into HTML
    if [ -f "$json_report" ]; then
        local json_data=$(cat "$json_report")
        sed -i "s|___REPORT_DATA___|${json_data}|g" "$html_report"
        log_success "HTML report: ${html_report}"
    fi
}

# Generate reports
generate_reports() {
    if ! $GENERATE_REPORT; then
        return 0
    fi

    log_header "GENERATING REPORTS"

    mkdir -p "$REPORT_DIR"

    local timestamp=$(date +%Y%m%d-%H%M%S)
    local json_report="${REPORT_DIR}/test-report-${timestamp}.json"

    # Create JSON report
    cat > "$json_report" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "summary": {
    "total": ${TOTAL_TESTS:-0},
    "passed": ${PASSED_TESTS:-0},
    "failed": ${FAILED_TESTS:-0},
    "skipped": ${SKIPPED_TESTS:-0}
  },
  "tests": [
    ${TEST_RESULTS:-}
  ],
  "environment": {
    "local_only": $LOCAL_ONLY,
    "aws_only": $AWS_ONLY,
    "quick_mode": $QUICK_MODE
  }
}
EOF

    log_success "JSON report: ${json_report}"

    # Generate HTML report
    generate_html_report "$json_report"
}

# Main execution
main() {
    print_banner

    check_prerequisites

    local local_result=0
    local aws_result=0

    # Run local tests
    if ! $AWS_ONLY; then
        run_local_tests || local_result=$?
    fi

    # Run AWS tests
    if ! $LOCAL_ONLY && ! $QUICK_MODE; then
        run_aws_tests || aws_result=$?
    fi

    # Overall result
    log_header "FINAL SUMMARY"

    if [ $local_result -eq 0 ] && [ $aws_result -eq 0 ]; then
        log_success "All tests passed! 🎉"
        echo ""
        log_info "Your application is working correctly!"
        return 0
    else
        if [ $local_result -ne 0 ]; then
            log_error "Local tests failed"
        fi
        if [ $aws_result -ne 0 ]; then
            log_error "AWS tests failed"
        fi
        echo ""
        log_info "Check the output above for details"
        return 1
    fi
}

main "$@"
