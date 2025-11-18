#!/usr/bin/env bash

###############################################################################
# Product Service Tests
# Tests all product service endpoints and functionality
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

# Product service tests
test_list_products() {
    local response
    response=$(curl -sf "${PRODUCT_URL}/products")
    # Should return an array with at least 3 seed products
    echo "$response" | jq -e 'length >= 3' >/dev/null
}

test_get_product_by_id() {
    local response
    response=$(curl -sf "${PRODUCT_URL}/products/1")
    # Should return product with id=1
    echo "$response" | jq -e '.id == 1' >/dev/null
}

test_product_has_required_fields() {
    local response
    response=$(curl -sf "${PRODUCT_URL}/products/1")
    # Check for required fields
    echo "$response" | jq -e 'has("id") and has("name") and has("price") and has("stock")' >/dev/null
}

test_create_product() {
    local response status
    local timestamp=$(date +%s)
    local payload='{"name":"Test Product '"${timestamp}"'","description":"Integration test product","price":99.99,"stock":50,"category":"Test"}'

    response=$(curl -sf -X POST "${PRODUCT_URL}/products" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should return 201 and include id
    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${PRODUCT_URL}/products" \
        -H "Content-Type: application/json" \
        -d "$payload")

    [ "$status" = "201" ]
}

test_create_product_returns_id() {
    local response
    local timestamp=$(date +%s)
    local payload='{"name":"Test Product ID '"${timestamp}"'","description":"Test","price":49.99,"stock":10,"category":"Test"}'

    response=$(curl -sf -X POST "${PRODUCT_URL}/products" \
        -H "Content-Type: application/json" \
        -d "$payload")

    echo "$response" | jq -e 'has("id")' >/dev/null
}

test_invalid_negative_price() {
    local status
    local payload='{"name":"Invalid Product","description":"Negative price","price":-10,"stock":5,"category":"Test"}'

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${PRODUCT_URL}/products" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should return 422 (validation error)
    [ "$status" = "422" ]
}

test_invalid_negative_stock() {
    local status
    local payload='{"name":"Invalid Product","description":"Negative stock","price":10,"stock":-5,"category":"Test"}'

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${PRODUCT_URL}/products" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should return 422 (validation error)
    [ "$status" = "422" ]
}

test_invalid_missing_name() {
    local status
    local payload='{"description":"No name","price":10,"stock":5}'

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${PRODUCT_URL}/products" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should return 422 (validation error)
    [ "$status" = "422" ]
}

test_get_nonexistent_product() {
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" "${PRODUCT_URL}/products/999999")

    # Should return 404
    [ "$status" = "404" ]
}

test_seed_data_contains_laptop() {
    local response
    response=$(curl -sf "${PRODUCT_URL}/products")
    # Check if seed data contains "Laptop Pro"
    echo "$response" | jq -e '.[] | select(.name == "Laptop Pro")' >/dev/null
}

# Main test execution
main() {
    echo "========================================"
    echo "  Product Service Tests"
    echo "========================================"
    echo ""

    log_info "Testing endpoint: ${PRODUCT_URL}"
    echo ""

    # Run tests
    run_test "List all products" "test_list_products"
    run_test "Get product by ID" "test_get_product_by_id"
    run_test "Product has required fields" "test_product_has_required_fields"
    run_test "Seed data contains Laptop Pro" "test_seed_data_contains_laptop"

    run_test "Create new product" "test_create_product"
    run_test "Created product returns ID" "test_create_product_returns_id"

    run_test "Reject negative price" "test_invalid_negative_price"
    run_test "Reject negative stock" "test_invalid_negative_stock"
    run_test "Reject missing name" "test_invalid_missing_name"

    run_test "Get non-existent product returns 404" "test_get_nonexistent_product"

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
        log_success "All product service tests passed!"
        return 0
    else
        echo ""
        log_error "Some product service tests failed!"
        return 1
    fi
}

main "$@"
