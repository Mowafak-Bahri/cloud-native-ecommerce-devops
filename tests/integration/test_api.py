import os
import uuid

import pytest
import requests

BASE_URL = os.getenv("API_BASE_URL", "http://localhost:3000")
PRODUCT_URL = os.getenv("PRODUCT_SERVICE_URL", "http://localhost:8000")
ORDER_URL = os.getenv("ORDER_SERVICE_URL", "http://localhost:8001")


def _post_json(url: str, payload: dict) -> requests.Response:
  return requests.post(url, json=payload, timeout=10)


class TestProductService:
  def test_health_check(self):
    """Verify product service health endpoint"""
    response = requests.get(f"{PRODUCT_URL}/../health", timeout=5)
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

  def test_list_products(self):
    """Verify products endpoint returns initial seed data"""
    response = requests.get(f"{PRODUCT_URL}/products", timeout=5)
    assert response.status_code == 200
    products = response.json()
    assert len(products) >= 3
    assert all("id" in p and "name" in p for p in products)

  def test_get_product_by_id(self):
    """Verify individual product retrieval"""
    response = requests.get(f"{PRODUCT_URL}/products/1", timeout=5)
    assert response.status_code == 200
    product = response.json()
    assert product["id"] == 1
    assert "name" in product
    assert "price" in product

  def test_create_product(self):
    """Verify product creation"""
    new_product = {
      "name": f"Integration {uuid.uuid4().hex[:6]}",
      "description": "Created by integration test",
      "price": 99.99,
      "stock": 100,
    }
    response = _post_json(f"{PRODUCT_URL}/products", new_product)
    assert response.status_code == 201
    created = response.json()
    assert created["name"] == new_product["name"]
    assert "id" in created


class TestOrderService:
  def test_list_orders(self):
    """Verify orders endpoint"""
    response = requests.get(f"{ORDER_URL}/orders", timeout=5)
    assert response.status_code == 200
    assert isinstance(response.json(), list)

  def test_create_order(self):
    """Verify order creation"""
    order = {"product_id": 1, "quantity": 2}
    response = _post_json(f"{ORDER_URL}/orders", order)
    assert response.status_code == 201
    created = response.json()
    assert created["product_id"] == 1
    assert created["quantity"] == 2
    assert "total_price" in created

  def test_order_validation(self):
    """Verify order validation"""
    order = {"product_id": 1, "quantity": 999999}
    response = _post_json(f"{ORDER_URL}/orders", order)
    assert response.status_code == 400

    order = {"product_id": 99999, "quantity": 1}
    response = _post_json(f"{ORDER_URL}/orders", order)
    assert response.status_code == 404


if __name__ == "__main__":
  raise SystemExit(pytest.main([__file__, "-v"]))
