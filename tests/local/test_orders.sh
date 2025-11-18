#!/usr/bin/env bash

###############################################################################
# Order Service Tests
# Tests all order service endpoints and functionality
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
ORDER_URL="${ORDER_SERVICE_URL:-http://localhost:8001}"
PRODUCT_URL="${PRODUCT_SERVICE_URL:-http://localhost:8000}"

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

# Order service tests
test_list_orders() {
    local response
    response=$(curl -sf "${ORDER_URL}/orders")
    # Should return an array
    echo "$response" | jq -e 'type == "array"' >/dev/null
}

test_create_order() {
    local response status
    local payload='{"product_id":1,"quantity":1}'

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${ORDER_URL}/orders" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should return 201
    [ "$status" = "201" ]
}

test_create_order_returns_fields() {
    local response
    local payload='{"product_id":1,"quantity":2}'

    response=$(curl -sf -X POST "${ORDER_URL}/orders" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should have required fields
    echo "$response" | jq -e 'has("id") and has("product_id") and has("quantity") and has("total_price") and has("status")' >/dev/null
}

test_create_order_calculates_total() {
    local response
    local payload='{"product_id":1,"quantity":2}'

    response=$(curl -sf -X POST "${ORDER_URL}/orders" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should have total_price > 0
    local total_price=$(echo "$response" | jq -r '.total_price')
    [ "$total_price" != "null" ] && [ "$total_price" != "0" ]
}

test_order_validates_stock() {
    local status
    local payload='{"product_id":1,"quantity":999999}'

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${ORDER_URL}/orders" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should return 400 (insufficient stock)
    [ "$status" = "400" ]
}

test_order_validates_product_exists() {
    local status
    local payload='{"product_id":999999,"quantity":1}'

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${ORDER_URL}/orders" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should return 404 (product not found)
    [ "$status" = "404" ]
}

test_order_validates_positive_quantity() {
    local status
    local payload='{"product_id":1,"quantity":0}'

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${ORDER_URL}/orders" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should return 400 (invalid quantity)
    [ "$status" = "400" ]
}

test_order_validates_negative_quantity() {
    local status
    local payload='{"product_id":1,"quantity":-5}'

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${ORDER_URL}/orders" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should return 400 (invalid quantity)
    [ "$status" = "400" ]
}

test_order_validates_missing_product_id() {
    local status
    local payload='{"quantity":1}'

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${ORDER_URL}/orders" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should return 400 (missing product_id)
    [ "$status" = "400" ]
}

test_order_status_is_pending() {
    local response
    local payload='{"product_id":1,"quantity":1}'

    response=$(curl -sf -X POST "${ORDER_URL}/orders" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Status should be PENDING
    echo "$response" | jq -e '.status == "PENDING"' >/dev/null
}

# Main test execution
main() {
    echo "========================================"
    echo "  Order Service Tests"
    echo "========================================"
    echo ""

    log_info "Testing endpoint: ${ORDER_URL}"
    echo ""

    # Run tests
    run_test "List all orders" "test_list_orders"

    run_test "Create new order" "test_create_order"
    run_test "Created order has required fields" "test_create_order_returns_fields"
    run_test "Order calculates total price" "test_create_order_calculates_total"
    run_test "Order status is PENDING" "test_order_status_is_pending"

    run_test "Validate insufficient stock" "test_order_validates_stock"
    run_test "Validate product exists" "test_order_validates_product_exists"
    run_test "Validate positive quantity" "test_order_validates_positive_quantity"
    run_test "Validate non-negative quantity" "test_order_validates_negative_quantity"
    run_test "Validate missing product_id" "test_order_validates_missing_product_id"

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
        log_success "All order service tests passed!"
        return 0
    else
        echo ""
        log_error "Some order service tests failed!"
        return 1
    fi
}

main "$@"
