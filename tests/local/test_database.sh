#!/usr/bin/env bash

###############################################################################
# Database Tests
# Tests database connectivity and data persistence
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
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-ecommerce}"
DB_USER="${DB_USER:-postgres}"
DB_PASSWORD="${DB_PASSWORD:-password}"

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

# Database tests
test_database_accessible() {
    if command -v nc >/dev/null 2>&1; then
        nc -z "$DB_HOST" "$DB_PORT"
    else
        # Fallback to curl if nc not available
        timeout 5 bash -c "cat < /dev/null > /dev/tcp/${DB_HOST}/${DB_PORT}"
    fi
}

test_product_service_db_connection() {
    local response
    response=$(curl -sf "${PRODUCT_URL}/health")
    # Health check should verify DB connection
    echo "$response" | jq -e '.database == "connected"' >/dev/null
}

test_order_service_db_connection() {
    local response
    response=$(curl -sf "${ORDER_URL}/health")
    # Health check should verify DB connection
    [ "$(echo "$response" | jq -r '.status')" = "healthy" ]
}

test_products_table_has_data() {
    local response
    response=$(curl -sf "${PRODUCT_URL}/products")
    # Should have seed data (at least 3 products)
    local count=$(echo "$response" | jq 'length')
    [ "$count" -ge 3 ]
}

test_data_persistence() {
    local timestamp=$(date +%s)
    local product_name="Persistence Test ${timestamp}"
    local payload="{\"name\":\"${product_name}\",\"description\":\"Test persistence\",\"price\":123.45,\"stock\":99,\"category\":\"Test\"}"

    # Create a product
    local create_response
    create_response=$(curl -sf -X POST "${PRODUCT_URL}/products" \
        -H "Content-Type: application/json" \
        -d "$payload")

    local product_id=$(echo "$create_response" | jq -r '.id')

    # Retrieve the product
    local get_response
    get_response=$(curl -sf "${PRODUCT_URL}/products/${product_id}")

    # Verify it's the same product
    local retrieved_name=$(echo "$get_response" | jq -r '.name')
    [ "$retrieved_name" = "$product_name" ]
}

test_order_data_persistence() {
    local payload='{"product_id":1,"quantity":3}'

    # Create an order
    local create_response
    create_response=$(curl -sf -X POST "${ORDER_URL}/orders" \
        -H "Content-Type: application/json" \
        -d "$payload")

    local order_id=$(echo "$create_response" | jq -r '.id')

    # List orders and verify our order exists
    local list_response
    list_response=$(curl -sf "${ORDER_URL}/orders")

    # Check if order exists in list
    echo "$list_response" | jq -e ".[] | select(.id == ${order_id})" >/dev/null
}

test_product_table_constraints() {
    # Try to create product with invalid data
    local status
    local payload='{"name":"","description":"Empty name","price":10,"stock":5,"category":"Test"}'

    status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${PRODUCT_URL}/products" \
        -H "Content-Type: application/json" \
        -d "$payload")

    # Should fail validation (422)
    [ "$status" = "422" ]
}

# Main test execution
main() {
    echo "========================================"
    echo "  Database Tests"
    echo "========================================"
    echo ""

    log_info "Database configuration:"
    log_info "  Host: ${DB_HOST}"
    log_info "  Port: ${DB_PORT}"
    log_info "  Database: ${DB_NAME}"
    echo ""

    # Run tests
    run_test "Database is accessible" "test_database_accessible"
    run_test "Product service connects to database" "test_product_service_db_connection"
    run_test "Order service connects to database" "test_order_service_db_connection"

    run_test "Products table has seed data" "test_products_table_has_data"
    run_test "Product data persists after creation" "test_data_persistence"
    run_test "Order data persists after creation" "test_order_data_persistence"

    run_test "Product table enforces constraints" "test_product_table_constraints"

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
        log_success "All database tests passed!"
        return 0
    else
        echo ""
        log_error "Some database tests failed!"
        return 1
    fi
}

main "$@"
