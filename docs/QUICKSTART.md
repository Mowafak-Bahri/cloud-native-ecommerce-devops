# Quick Start

## 1. Prerequisites
- Docker Desktop installed and running
- Git installed
- At least 5GB free disk space

## 2. Get Started (3 commands)
```bash
git clone https://github.com/Mowafak-Bahri/cloud-native-ecommerce-devops.git
cd cloud-native-ecommerce-devops
docker-compose up -d
```

## 3. Verify (1 command)
```bash
curl http://localhost:3000/products
```

## 4. Test It
- Create an order: `curl -X POST http://localhost:3000/orders -H 'Content-Type: application/json' -d '{"product_id":1,"quantity":1}'`
- View orders: `curl http://localhost:3000/orders`

## 5. Stop
```bash
docker-compose down
```

## 6. Next Steps
- Deploy to AWS: see `docs/runbooks/deployment.md`
- Learn more: read `README.md`
