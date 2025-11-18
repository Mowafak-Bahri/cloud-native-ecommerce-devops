#!/usr/bin/env bash

###############################################################################
# Local Test Suite Runner
# Runs all local tests sequentially and provides comprehensive summary
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
KEEP_CONTAINERS=false

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

Run all local test suites for the e-commerce application.

Options:
    --verbose           Show detailed test output
    --keep-containers   Keep Docker containers running after tests
    -h, --help          Show this help message

Examples:
    # Run all tests
    ./test_all.sh

    # Run with verbose output
    ./test_all.sh --verbose

    # Keep containers running for debugging
    ./test_all.sh --keep-containers
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --keep-containers)
            KEEP_CONTAINERS=true
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

    local missing=()
    for cmd in docker curl jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        log_info "Please install missing tools and try again"
        exit 1
    fi

    # Check docker compose
    if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
        log_error "docker-compose or 'docker compose' command not found"
        exit 1
    fi

    log_success "All prerequisites satisfied"
}

# Start Docker Compose stack
start_services() {
    log_header "Starting Docker Compose Stack"

    cd "$REPO_ROOT"

    log_info "Building and starting services..."
    if $VERBOSE; then
        docker compose up -d --build
    else
        docker compose up -d --build >/dev/null 2>&1
    fi

    log_info "Waiting for services to be healthy..."

    # Wait for PostgreSQL
    local attempt=0
    while ! docker compose exec -T postgres pg_isready -U postgres >/dev/null 2>&1; do
        sleep 2
        attempt=$((attempt + 1))
        if [ $attempt -gt 30 ]; then
            log_error "PostgreSQL failed to start"
            exit 1
        fi
    done
    log_success "PostgreSQL is ready"

    # Wait for services
    for service in "Product:8000" "Order:8001" "Frontend:3000"; do
        IFS=: read -r name port <<< "$service"
        attempt=0
        while ! curl -sf "http://localhost:${port}/health" >/dev/null 2>&1; do
            sleep 2
            attempt=$((attempt + 1))
            if [ $attempt -gt 30 ]; then
                log_error "${name} service failed to start"
                exit 1
            fi
        done
        log_success "${name} service is ready"
    done

    echo ""
}

# Stop Docker Compose stack
stop_services() {
    if $KEEP_CONTAINERS; then
        log_info "Keeping containers running (--keep-containers flag)"
    else
        log_info "Stopping Docker Compose stack..."
        cd "$REPO_ROOT"
        if $VERBOSE; then
            docker compose down -v
        else
            docker compose down -v >/dev/null 2>&1
        fi
        log_success "Containers stopped"
    fi
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
        log_success "All test suites passed! 🎉"
        return 0
    else
        echo ""
        log_error "Some test suites failed!"
        return 1
    fi
}

# Cleanup handler
cleanup() {
    local exit_code=$?
    echo ""
    stop_services
    exit $exit_code
}

trap cleanup EXIT INT TERM

# Main execution
main() {
    echo "========================================"
    echo "  E-Commerce Local Test Suite"
    echo "========================================"
    echo ""

    check_prerequisites
    start_services

    # Run all test suites - continue even if one fails
    run_test_suite "Health Checks" "${SCRIPT_DIR}/test_health.sh" || true
    run_test_suite "Product Service" "${SCRIPT_DIR}/test_products.sh" || true
    run_test_suite "Order Service" "${SCRIPT_DIR}/test_orders.sh" || true
    run_test_suite "Frontend" "${SCRIPT_DIR}/test_frontend.sh" || true
    run_test_suite "Database" "${SCRIPT_DIR}/test_database.sh" || true

    # Print summary
    print_summary
}

main "$@"
