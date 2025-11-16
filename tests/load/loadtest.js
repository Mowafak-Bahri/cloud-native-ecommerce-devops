import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const BASE_URL = __ENV.API_BASE_URL || 'http://localhost:3000';
const errorRate = new Rate('errors');

export const options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '1m', target: 10 },
    { duration: '30s', target: 50 },
    { duration: '2m', target: 50 },
    { duration: '30s', target: 100 },
    { duration: '1m', target: 100 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    errors: ['rate<0.05'],
  },
};

export default function () {
  const productsRes = http.get(`${BASE_URL}/products`);
  check(productsRes, {
    'products status 200': (r) => r.status === 200,
    'products has data': (r) => JSON.parse(r.body).length > 0,
  }) || errorRate.add(1);

  sleep(1);

  const productRes = http.get(`${BASE_URL}/products/1`);
  check(productRes, {
    'product status 200': (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(1);

  if (Math.random() < 0.1) {
    const payload = JSON.stringify({
      product_id: 1,
      quantity: Math.floor(Math.random() * 3) + 1,
    });

    const params = { headers: { 'Content-Type': 'application/json' } };
    const orderRes = http.post(`${BASE_URL}/orders`, payload, params);
    check(orderRes, {
      'order created': (r) => r.status === 201,
    }) || errorRate.add(1);
  }

  sleep(2);
}

// Run with: k6 run tests/load/loadtest.js
