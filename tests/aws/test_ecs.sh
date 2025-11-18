#!/usr/bin/env bash

###############################################################################
# AWS ECS Tests
# Tests ECS cluster, services, and tasks
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
CLUSTER_NAME="${CLUSTER_NAME:-ecommerce-dev-cluster}"
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

# Check prerequisites
check_aws_cli() {
    command -v aws >/dev/null 2>&1
}

check_aws_credentials() {
    aws sts get-caller-identity >/dev/null 2>&1
}

# ECS tests
test_cluster_exists() {
    aws ecs describe-clusters \
        --clusters "$CLUSTER_NAME" \
        --region "$AWS_REGION" \
        --query 'clusters[0].status' \
        --output text | grep -q "ACTIVE"
}

test_product_service_running() {
    local service_name="${PROJECT_NAME}-${ENVIRONMENT}-product"
    local running_count
    running_count=$(aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$service_name" \
        --region "$AWS_REGION" \
        --query 'services[0].runningCount' \
        --output text)

    [ "$running_count" -gt 0 ]
}

test_order_service_running() {
    local service_name="${PROJECT_NAME}-${ENVIRONMENT}-order"
    local running_count
    running_count=$(aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$service_name" \
        --region "$AWS_REGION" \
        --query 'services[0].runningCount' \
        --output text)

    [ "$running_count" -gt 0 ]
}

test_frontend_service_running() {
    local service_name="${PROJECT_NAME}-${ENVIRONMENT}-frontend"
    local running_count
    running_count=$(aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$service_name" \
        --region "$AWS_REGION" \
        --query 'services[0].runningCount' \
        --output text)

    [ "$running_count" -gt 0 ]
}

test_services_healthy() {
    local services=(
        "${PROJECT_NAME}-${ENVIRONMENT}-product"
        "${PROJECT_NAME}-${ENVIRONMENT}-order"
        "${PROJECT_NAME}-${ENVIRONMENT}-frontend"
    )

    for service in "${services[@]}"; do
        local desired running
        desired=$(aws ecs describe-services \
            --cluster "$CLUSTER_NAME" \
            --services "$service" \
            --region "$AWS_REGION" \
            --query 'services[0].desiredCount' \
            --output text)

        running=$(aws ecs describe-services \
            --cluster "$CLUSTER_NAME" \
            --services "$service" \
            --region "$AWS_REGION" \
            --query 'services[0].runningCount' \
            --output text)

        [ "$running" -eq "$desired" ] || return 1
    done

    return 0
}

test_tasks_running() {
    local task_count
    task_count=$(aws ecs list-tasks \
        --cluster "$CLUSTER_NAME" \
        --region "$AWS_REGION" \
        --desired-status RUNNING \
        --query 'length(taskArns)' \
        --output text)

    [ "$task_count" -gt 0 ]
}

# Main test execution
main() {
    echo "========================================"
    echo "  AWS ECS Tests"
    echo "========================================"
    echo ""

    log_info "Configuration:"
    log_info "  Region: ${AWS_REGION}"
    log_info "  Cluster: ${CLUSTER_NAME}"
    log_info "  Environment: ${ENVIRONMENT}"
    echo ""

    # Prerequisites
    if ! check_aws_cli; then
        log_error "AWS CLI not found. Please install it first."
        exit 1
    fi

    if ! check_aws_credentials; then
        log_error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    fi

    # Run tests
    run_test "ECS cluster exists and is active" "test_cluster_exists"
    run_test "Product service has running tasks" "test_product_service_running"
    run_test "Order service has running tasks" "test_order_service_running"
    run_test "Frontend service has running tasks" "test_frontend_service_running"
    run_test "All services healthy (running == desired)" "test_services_healthy"
    run_test "Cluster has running tasks" "test_tasks_running"

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
        log_success "All ECS tests passed!"
        return 0
    else
        echo ""
        log_error "Some ECS tests failed!"
        return 1
    fi
}

main "$@"
