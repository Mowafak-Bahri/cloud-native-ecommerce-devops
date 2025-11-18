#!/usr/bin/env bash
set -euo pipefail

FRONTEND_URL="${FRONTEND_URL:-http://localhost:3000}"
ORDER_URL="${ORDER_URL:-http://localhost:8001}"
PRODUCT_URL="${PRODUCT_URL:-http://localhost:8000}"

print_step() { echo -e "\n===== $1 ====="; }

# Task 1.2 – Verify helmet headers on frontend service
print_step "Task 1.2: Checking security headers on frontend"
curl -s -D - "$FRONTEND_URL/health" -o /dev/null \
  | grep -Ei 'x-content-type-options|x-frame-options|x-xss-protection|referrer-policy'

# Task 1.3 – Order-service error handler (intentional DB failure simulation)
print_step "Task 1.3: Triggering error to check centralized handling (order-service)"
curl -s -X POST "$ORDER_URL/orders" \
  -H "Content-Type: application/json" \
  -d '{"product_id":999999,"quantity":1}' | jq

# Task 1.4 – Frontend error handler via product request
print_step "Task 1.4: Triggering error to check centralized handling (frontend)"
curl -s "$FRONTEND_URL/products/999999" | jq

# Task 1.5 – Order-service CORS & validation
print_step "Task 1.5: Verifying order-service CORS + validation"
curl -s -I -H "Origin: http://localhost:3000" "$ORDER_URL/health" | grep -Fi 'access-control-allow-origin'
curl -s -X POST "$ORDER_URL/orders" \
  -H "Content-Type: application/json" \
  -d '{"product_id":"abc","quantity":-1}' | jq

# Task 1.6 – Frontend CORS + timeout
print_step "Task 1.6: Verifying frontend CORS headers"
curl -s -I -H "Origin: http://localhost:3000" "$FRONTEND_URL/health" | grep -Fi 'access-control-allow-origin'

# Task 1.7 – Order-service rate limiting
print_step "Task 1.7: Hitting order-service repeatedly to confirm rate limiting"
for i in {1..110}; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "$ORDER_URL/health")
  if [[ "$status" == "429" ]]; then
    echo "Rate limit triggered at request $i"
    break
  fi
done

# Task 1.8 – Product-service structured logging (manual check after hitting endpoint)
print_step "Task 1.8: Hit product-service to generate logs (inspect container logs)"
curl -s "$PRODUCT_URL/products" >/dev/null
echo "Now run: docker logs <product-service-container> | head"

# Task 1.9 – Product-service rate limiting
print_step "Task 1.9: Flood product-service to confirm limiter"
for i in {1..70}; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "$PRODUCT_URL/products")
  if [[ "$status" == "429" ]]; then
    echo "Product-service rate limit triggered at request $i"
    break
  fi
done

echo -e "\nAll Phase 1 security tests executed."
