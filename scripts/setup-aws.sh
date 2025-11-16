#!/usr/bin/env bash

set -euo pipefail

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m"

log() { printf "%b\n" "$*"; }
log_info() { log "${GREEN}[INFO]${NC} $*"; }
log_warn() { log "${YELLOW}[WARN]${NC} $*"; }
log_error() { log "${RED}[ERROR]${NC} $*"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

require_aws() {
  if ! command_exists aws; then
    log_error "AWS CLI is required"
    exit 2
  fi
}

prompt_bucket_name() {
  local user
  user=$(whoami)
  local default="${user}-terraform-state-$(date +%Y%m%d%H%M%S)"
  read -rp "Enter S3 bucket name [${default}]: " bucket
  bucket=${bucket:-$default}
  if [[ ! $bucket =~ ^[a-z0-9.-]{3,63}$ ]]; then
    log_error "Bucket name must be 3-63 lowercase characters, numbers, dots, or hyphens"
    exit 2
  fi
  echo "$bucket"
}

confirm() {
  read -rp "Proceed with creation? (y/N): " answer
  [[ "${answer,,}" == "y" ]] || [[ "${answer,,}" == "yes" ]]
}

ensure_region() {
  local region="${AWS_REGION:-$(aws configure get region 2>/dev/null || true)}"
  if [[ -z "$region" ]]; then
    read -rp "Enter AWS region (e.g., us-east-1): " region
  fi
  if [[ -z "$region" ]]; then
    log_error "AWS region is required"
    exit 2
  fi
  echo "$region"
}

bucket_exists() {
  aws s3api head-bucket --bucket "$1" >/dev/null 2>&1
}

create_bucket() {
  local bucket="$1" region="$2"
  if bucket_exists "$bucket"; then
    log_warn "Bucket ${bucket} already exists"
  else
    log_info "Creating S3 bucket ${bucket} in ${region}"
    if [[ "$region" == "us-east-1" ]]; then
      aws s3api create-bucket --bucket "$bucket" >/dev/null
    else
      aws s3api create-bucket --bucket "$bucket" --create-bucket-configuration LocationConstraint="$region" >/dev/null
    fi
  fi

  log_info "Enabling default encryption"
  aws s3api put-bucket-encryption --bucket "$bucket" --server-side-encryption-configuration 'Rules=[{ApplyServerSideEncryptionByDefault={SSEAlgorithm=AES256}}]' >/dev/null

  log_info "Enabling versioning"
  aws s3api put-bucket-versioning --bucket "$bucket" --versioning-configuration Status=Enabled >/dev/null

  log_info "Blocking public access"
  aws s3api put-public-access-block --bucket "$bucket" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null
}

create_lock_table() {
  local table="terraform-locks"
  if aws dynamodb describe-table --table-name "$table" >/dev/null 2>&1; then
    log_warn "DynamoDB table ${table} already exists"
  else
    log_info "Creating DynamoDB table ${table}"
    aws dynamodb create-table \
      --table-name "$table" \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST >/dev/null
    aws dynamodb wait table-exists --table-name "$table"
  fi
}

update_backend_block() {
  local bucket="$1" region="$2"
  local tf_file="terraform/main.tf"
  if [[ ! -f "$tf_file" ]]; then
    log_error "${tf_file} not found"
    exit 1
  fi

  python3 - "$tf_file" <<PY
import pathlib, re, sys
bucket = "$bucket"
region = "$region"
path = pathlib.Path(sys.argv[1])
text = path.read_text()

backend_block = f'''backend "s3" {{
    bucket         = "{bucket}"
    key            = "cloud-native-ecommerce/terraform.tfstate"
    region         = "{region}"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }}'''

if 'backend "s3"' in text and '# backend "s3"' not in text:
    print("Backend already configured")
else:
    pattern = re.compile(r'# backend "s3" \{[^\}]+\}', re.MULTILINE)
    new_text, count = pattern.subn(backend_block, text, count=1)
    if count == 0:
        print("Unable to find commented backend block; please update terraform/main.tf manually")
    else:
        path.write_text(new_text)
        print("Updated terraform backend block")
PY
}

require_aws
BUCKET=$(prompt_bucket_name)
REGION=$(ensure_region)

log_info "Bucket: ${BUCKET}"
log_info "Region: ${REGION}"

if ! confirm; then
  log_warn "Aborted by user"
  exit 0
fi

aws sts get-caller-identity >/dev/null

create_bucket "$BUCKET" "$REGION"
create_lock_table
update_backend_block "$BUCKET" "$REGION"

log_info "S3 bucket ARN: arn:aws:s3:::${BUCKET}"
log_info "DynamoDB table: terraform-locks"
log_info "Next steps: run 'cd terraform && terraform init'"
