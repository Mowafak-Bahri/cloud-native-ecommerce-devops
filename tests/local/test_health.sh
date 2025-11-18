#!/usr/bin/env bash

###############################################################################
# Health Check Tests
# Tests all service health endpoints to ensure services are running properly
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m"

# Test configuration
PRODUCT_URL="${PRODUCT_SERVICE_URL:-http://localhost:8000}"
ORDER_URL="${ORDER_SERVICE_URL:-http://localhost:8001}"
FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"

PASSED=0
FAILED=0
TOTAL=0

# Logging functions
log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[PASS]${NC} %s\n" "$*"; }
log_error() { printf "${RED}[FAIL]${NC} %s\n" "$*"; }
log_warn() { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }

# Test runner function
run_test() {
    local test_name="$1"
    local test_command="$2"

    TOTAL=$((TOTAL + 1))
    printf "%-60s " "$test_name..."

    if eval "$test_command" >/dev/null 2>&1; then
        printf "${GREEN}PASS${NC}\n"
        PASSED=$((PASSED + 1))
        return 0
    else
        printf "${RED}FAIL${NC}\n"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Health check tests
test_product_service_health() {
    local response
    response=$(curl -sf "${PRODUCT_URL}/health" 2>&1)
    echo "$response" | grep -q '"status":"healthy"'
}

test_order_service_health() {
    local response
    response=$(curl -sf "${ORDER_URL}/health" 2>&1)
    echo "$response" | grep -q '"status":"healthy"'
}

test_frontend_health() {
    local response
    response=$(curl -sf "${FRONTEND_URL}/health" 2>&1)
    echo "$response" | grep -q '"status":"healthy"'
}

test_product_service_accessible() {
    curl -sf "${PRODUCT_URL}/health" -o /dev/null
}

test_order_service_accessible() {
    curl -sf "${ORDER_URL}/health" -o /dev/null
}

test_frontend_accessible() {
    curl -sf "${FRONTEND_URL}/health" -o /dev/null
}

# Main test execution
main() {
    echo "========================================"
    echo "  Health Check Tests"
    echo "========================================"
    echo ""

    log_info "Testing service endpoints:"
    log_info "  Product Service: ${PRODUCT_URL}"
    log_info "  Order Service: ${ORDER_URL}"
    log_info "  Frontend: ${FRONTEND_URL}"
    echo ""

    # Run tests
    run_test "Product service is accessible" "test_product_service_accessible"
    run_test "Product service health check returns healthy" "test_product_service_health"

    run_test "Order service is accessible" "test_order_service_accessible"
    run_test "Order service health check returns healthy" "test_order_service_health"

    run_test "Frontend is accessible" "test_frontend_accessible"
    run_test "Frontend health check returns healthy" "test_frontend_health"

    # Summary
    echo ""
    echo "========================================"
    echo "  Test Summary"
    echo "========================================"
    printf "Total tests: %d\n" "$TOTAL"
    printf "${GREEN}Passed: %d${NC}\n" "$PASSED"
    printf "${RED}Failed: %d${NC}\n" "$FAILED"

    if [ "$FAILED" -eq 0 ]; then
        echo ""
        log_success "All health checks passed!"
        return 0
    else
        echo ""
        log_error "Some health checks failed!"
        return 1
    fi
}

main "$@"
