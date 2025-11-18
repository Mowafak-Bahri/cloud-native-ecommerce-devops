#!/usr/bin/env bash

###############################################################################
# Frontend Service Tests
# Tests frontend API gateway and proxy functionality
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
FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"

PASSED=0
FAILED=0
TOTAL=0

# Logging functions
log_info() { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[PASS]${NC} %s\n" "$*"; }
log_error() { printf "${RED}[FAIL]${NC} %s\n" "$*"; }

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

# Frontend tests
test_root_endpoint() {
    local response
    response=$(curl -sf "${FRONTEND_URL}/")
    # Should return welcome message
    [ -n "$response" ]
}

test_products_proxy() {
    local response
    response=$(curl -sf "${FRONTEND_URL}/products")
    # Should proxy to product service and return array
    echo "$response" | jq -e 'type == "array"' >/dev/null
}

test_orders_proxy() {
    local response
    response=$(curl -sf "${FRONTEND_URL}/orders")
    # Should proxy to order service and return array
    echo "$response" | jq -e 'type == "array"' >/dev/null
}

test_health_endpoint() {
    local response
    response=$(curl -sf "${FRONTEND_URL}/health")
    # Should return healthy status
    echo "$response" | jq -e '.status == "healthy"' >/dev/null
}

test_health_checks_backend_services() {
    local response
    response=$(curl -sf "${FRONTEND_URL}/health")
    # Should include backend service status
    echo "$response" | jq -e 'has("product_service") and has("order_service")' >/dev/null
}

test_cors_headers_present() {
    local headers
    headers=$(curl -sI "${FRONTEND_URL}/" | tr -d '\r')
    # Should have CORS headers
    echo "$headers" | grep -qi "access-control-allow-origin"
}

test_content_type_json() {
    local headers
    headers=$(curl -sI "${FRONTEND_URL}/products" | tr -d '\r')
    # Should return JSON content type
    echo "$headers" | grep -qi "content-type.*application/json"
}

test_404_for_unknown_path() {
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" "${FRONTEND_URL}/unknown-path-12345")
    # Should return 404
    [ "$status" = "404" ]
}

# Main test execution
main() {
    echo "========================================"
    echo "  Frontend Service Tests"
    echo "========================================"
    echo ""

    log_info "Testing endpoint: ${FRONTEND_URL}"
    echo ""

    # Run tests
    run_test "Root endpoint responds" "test_root_endpoint"
    run_test "Health endpoint returns healthy" "test_health_endpoint"
    run_test "Health checks backend services" "test_health_checks_backend_services"

    run_test "Proxy /products to product service" "test_products_proxy"
    run_test "Proxy /orders to order service" "test_orders_proxy"

    run_test "CORS headers present" "test_cors_headers_present"
    run_test "Content-Type is JSON" "test_content_type_json"
    run_test "Unknown path returns 404" "test_404_for_unknown_path"

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
        log_success "All frontend tests passed!"
        return 0
    else
        echo ""
        log_error "Some frontend tests failed!"
        return 1
    fi
}

main "$@"
