#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m"

SERVICES=("product-service" "order-service" "frontend")

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options] <service|all>

Deploy one or more services to AWS ECR/ECS.

Options:
  --dry-run         Show actions without executing them
  -h, --help        Show this help message

Environment variables:
  AWS_REGION        AWS region (falls back to configured default)
  PROJECT_NAME      Project prefix (default: ecommerce)
  ENVIRONMENT       Environment suffix (default: dev)
  ECS_CLUSTER       Override ECS cluster name

Examples:
  $(basename "$0") product-service
  $(basename "$0") --dry-run all
USAGE
}

log() { printf "%b\n" "$*"; }
log_info() { log "${GREEN}[INFO]${NC} $*"; }
log_warn() { log "${YELLOW}[WARN]${NC} $*"; }
log_error() { log "${RED}[ERROR]${NC} $*"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

ensure_prereqs() {
  local missing=()
  for cmd in aws docker git; do
    if ! command_exists "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if ((${#missing[@]} > 0)); then
    log_error "Missing prerequisites: ${missing[*]}"
    exit 2
  fi
}

DRY_RUN=false
SERVICE_ARG=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      log_error "Unknown option: $1"
      usage
      exit 2
      ;;
    *)
      SERVICE_ARG="$1"
      shift
      ;;
  esac
done

if [[ -z "$SERVICE_ARG" ]]; then
  log_error "Service name is required"
  usage
  exit 2
fi

ensure_prereqs

PROJECT_NAME="${PROJECT_NAME:-ecommerce}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
AWS_REGION="${AWS_REGION:-$(aws configure get region 2>/dev/null || true)}"

if [[ -z "${AWS_REGION}" ]]; then
  log_error "AWS region not set. Set AWS_REGION env var or configure AWS CLI."
  exit 2
fi

AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)"
if [[ -z "$AWS_ACCOUNT_ID" ]]; then
  log_error "Unable to determine AWS account ID. Check AWS credentials."
  exit 1
fi

ECS_CLUSTER="${ECS_CLUSTER:-${PROJECT_NAME}-${ENVIRONMENT}-cluster}"
GIT_SHA="$(git rev-parse --short=7 HEAD)"

login_ecr() {
  log_info "Logging into ECR (${AWS_REGION})"
  if $DRY_RUN; then
    log_warn "[dry-run] Skipping docker login"
    return
  fi
  aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
}

validate_service() {
  local svc="$1"
  if [[ ! " ${SERVICES[*]} " =~ " ${svc} " ]]; then
    log_error "Invalid service '${svc}'. Supported: ${SERVICES[*]} or 'all'"
    exit 2
  fi

  local dir="${REPO_ROOT}/services/${svc}"
  if [[ ! -d "$dir" ]]; then
    log_error "Service directory ${dir} not found"
    exit 1
  fi
}

get_services_to_deploy() {
  if [[ "$SERVICE_ARG" == "all" ]]; then
    printf "%s\n" "${SERVICES[@]}"
  else
    validate_service "$SERVICE_ARG"
    printf "%s\n" "$SERVICE_ARG"
  fi
}

build_and_push() {
  local svc="$1"
  local repo="${PROJECT_NAME}-${ENVIRONMENT}-${svc}"
  local image_base="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${repo}"
  local dir="${REPO_ROOT}/services/${svc}"

  log_info "Ensuring ECR repository ${repo} exists"
  if ! aws ecr describe-repositories --repository-names "$repo" --region "$AWS_REGION" >/dev/null 2>&1; then
    log_error "ECR repository ${repo} not found"
    exit 1
  fi

  log_info "Building Docker image for ${svc}"
  if $DRY_RUN; then
    log_warn "[dry-run] docker build ${dir}"
  else
    docker build -t "${image_base}:latest" -t "${image_base}:${GIT_SHA}" "$dir"
  fi

  log_info "Pushing Docker image for ${svc}"
  if $DRY_RUN; then
    log_warn "[dry-run] docker push ${image_base}"
  else
    docker push "${image_base}:latest"
    docker push "${image_base}:${GIT_SHA}"
  fi
}

wait_for_ecs() {
  local svc_name="$1"
  local start_ts
  start_ts=$(date +%s)
  local timeout=$((10 * 60))

  while true; do
    local status
    status="$(aws ecs describe-services --cluster "$ECS_CLUSTER" --services "$svc_name" \
      --query 'services[0].deployments[?status==`PRIMARY` && rolloutState==`COMPLETED`]' --output text 2>/dev/null || true)"

    if [[ -n "$status" ]]; then
      log_info "Service ${svc_name} is stable"
      break
    fi

    if (( $(date +%s) - start_ts > timeout )); then
      log_error "Timeout waiting for ECS service ${svc_name}"
      exit 1
    fi

    sleep 15
  done
}

deploy_ecs() {
  local svc="$1"
  local ecs_service="${PROJECT_NAME}-${ENVIRONMENT}-${svc}"

  log_info "Updating ECS service ${ecs_service}"
  if $DRY_RUN; then
    log_warn "[dry-run] aws ecs update-service --cluster ${ECS_CLUSTER} --service ${ecs_service}"
    return
  fi

  aws ecs update-service \
    --cluster "$ECS_CLUSTER" \
    --service "$ecs_service" \
    --force-new-deployment \
    >/dev/null

  wait_for_ecs "$ecs_service"
}

main() {
  login_ecr

  mapfile -t targets < <(get_services_to_deploy)

  for svc in "${targets[@]}"; do
    build_and_push "$svc"
    deploy_ecs "$svc"
  done

  log_info "Deployment complete"
}

main "$@"
