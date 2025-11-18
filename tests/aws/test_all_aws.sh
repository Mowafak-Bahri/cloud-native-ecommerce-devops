#!/usr/bin/env bash

###############################################################################
# AWS Test Suite Runner
# Runs all AWS deployment tests
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
BOLD="\033[1m"
NC="\033[0m"

# Configuration
VERBOSE=false

# Test results
declare -A TEST_RESULTS
TEST_SUITES=()

# Logging functions
log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"; }
log_error() { printf "${RED}[ERROR]${NC} %s\n" "$*"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
log_header() { printf "\n${BOLD}${BLUE}%s${NC}\n" "$*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Run all AWS deployment test suites for the e-commerce application.

Options:
    --verbose           Show detailed test output
    -h, --help          Show this help message

Examples:
    # Run all AWS tests
    ./test_all_aws.sh

    # Run with verbose output
    ./test_all_aws.sh --verbose

Prerequisites:
    - AWS CLI installed and configured
    - Valid AWS credentials
    - Terraform infrastructure deployed
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v aws >/dev/null 2>&1; then
        log_error "AWS CLI not found. Please install it first."
        exit 1
    fi

    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        log_error "jq not found. Please install it first."
        exit 1
    fi

    log_success "All prerequisites satisfied"
}

# Run a test suite
run_test_suite() {
    local test_name="$1"
    local test_script="$2"

    log_header "Running: ${test_name}"

    TEST_SUITES+=("$test_name")

    if [ ! -f "$test_script" ]; then
        log_error "Test script not found: $test_script"
        TEST_RESULTS["$test_name"]="SKIP"
        return 1
    fi

    local output
    if $VERBOSE; then
        if bash "$test_script"; then
            TEST_RESULTS["$test_name"]="PASS"
            return 0
        else
            TEST_RESULTS["$test_name"]="FAIL"
            return 1
        fi
    else
        output=$(bash "$test_script" 2>&1)
        if [ $? -eq 0 ]; then
            echo "$output" | tail -n 5
            TEST_RESULTS["$test_name"]="PASS"
            return 0
        else
            echo "$output"
            TEST_RESULTS["$test_name"]="FAIL"
            return 1
        fi
    fi
}

# Print summary
print_summary() {
    log_header "Test Summary"

    local total=${#TEST_SUITES[@]}
    local passed=0
    local failed=0
    local skipped=0

    printf "\n%-40s %10s\n" "Test Suite" "Result"
    printf "%s\n" "$(printf '=%.0s' {1..52})"

    for suite in "${TEST_SUITES[@]}"; do
        local result="${TEST_RESULTS[$suite]}"
        case "$result" in
            PASS)
                printf "%-40s ${GREEN}%10s${NC}\n" "$suite" "✓ PASS"
                passed=$((passed + 1))
                ;;
            FAIL)
                printf "%-40s ${RED}%10s${NC}\n" "$suite" "✗ FAIL"
                failed=$((failed + 1))
                ;;
            SKIP)
                printf "%-40s ${YELLOW}%10s${NC}\n" "$suite" "⊘ SKIP"
                skipped=$((skipped + 1))
                ;;
        esac
    done

    printf "%s\n" "$(printf '=%.0s' {1..52})"
    printf "\nTotal: %d | ${GREEN}Passed: %d${NC} | ${RED}Failed: %d${NC} | ${YELLOW}Skipped: %d${NC}\n" \
        "$total" "$passed" "$failed" "$skipped"

    if [ $failed -eq 0 ]; then
        echo ""
        log_success "All AWS test suites passed! 🎉"
        return 0
    else
        echo ""
        log_error "Some AWS test suites failed!"
        return 1
    fi
}

# Main execution
main() {
    echo "========================================"
    echo "  E-Commerce AWS Test Suite"
    echo "========================================"
    echo ""

    check_prerequisites

    # Run all test suites - continue even if one fails
    run_test_suite "ECS Deployment" "${SCRIPT_DIR}/test_ecs.sh" || true
    run_test_suite "Application Load Balancer" "${SCRIPT_DIR}/test_alb.sh" || true

    # Print summary
    print_summary
}

main "$@"
