#!/usr/bin/env bash

###############################################################################
# AWS ALB Tests
# Tests Application Load Balancer and routing
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

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAME="${PROJECT_NAME:-ecommerce}"

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

# Get ALB DNS name from Terraform outputs
get_alb_dns() {
    cd "$REPO_ROOT/terraform"
    terraform output -raw alb_dns_name 2>/dev/null || echo ""
}

# ALB tests
test_alb_accessible() {
    local alb_dns="$1"
    curl -sf "http://${alb_dns}/" -o /dev/null
}

test_products_route() {
    local alb_dns="$1"
    local response
    response=$(curl -sf "http://${alb_dns}/products")
    echo "$response" | jq -e 'type == "array"' >/dev/null
}

test_orders_route() {
    local alb_dns="$1"
    local response
    response=$(curl -sf "http://${alb_dns}/orders")
    echo "$response" | jq -e 'type == "array"' >/dev/null
}

test_health_endpoints() {
    local alb_dns="$1"
    curl -sf "http://${alb_dns}/health" | jq -e '.status == "healthy"' >/dev/null
}

test_target_groups_healthy() {
    local tg_name="${PROJECT_NAME}-${ENVIRONMENT}-product-tg"

    # Get target group ARN
    local tg_arn
    tg_arn=$(aws elbv2 describe-target-groups \
        --region "$AWS_REGION" \
        --names "$tg_name" \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text 2>/dev/null)

    if [ -z "$tg_arn" ] || [ "$tg_arn" = "None" ]; then
        return 1
    fi

    # Check target health
    local healthy_count
    healthy_count=$(aws elbv2 describe-target-health \
        --region "$AWS_REGION" \
        --target-group-arn "$tg_arn" \
        --query 'length(TargetHealthDescriptions[?TargetHealth.State==`healthy`])' \
        --output text)

    [ "$healthy_count" -gt 0 ]
}

# Main test execution
main() {
    echo "========================================"
    echo "  AWS ALB Tests"
    echo "========================================"
    echo ""

    log_info "Configuration:"
    log_info "  Region: ${AWS_REGION}"
    log_info "  Environment: ${ENVIRONMENT}"
    echo ""

    # Check AWS CLI
    if ! command -v aws >/dev/null 2>&1; then
        log_error "AWS CLI not found. Please install it first."
        exit 1
    fi

    # Check credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        log_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi

    # Get ALB DNS
    log_info "Retrieving ALB DNS name from Terraform..."
    ALB_DNS=$(get_alb_dns)

    if [ -z "$ALB_DNS" ]; then
        log_error "Could not retrieve ALB DNS name from Terraform outputs"
        log_info "Make sure Terraform has been applied and outputs are available"
        exit 1
    fi

    log_info "ALB DNS: ${ALB_DNS}"
    echo ""

    # Run tests
    run_test "ALB is accessible" "test_alb_accessible '$ALB_DNS'"
    run_test "Health endpoint responds" "test_health_endpoints '$ALB_DNS'"
    run_test "/products route works" "test_products_route '$ALB_DNS'"
    run_test "/orders route works" "test_orders_route '$ALB_DNS'"
    run_test "Target groups have healthy targets" "test_target_groups_healthy"

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
        log_success "All ALB tests passed!"
        log_info "Application is accessible at: http://${ALB_DNS}"
        return 0
    else
        echo ""
        log_error "Some ALB tests failed!"
        return 1
    fi
}

main "$@"
