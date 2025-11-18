# 🧪 Complete Testing Guide for E-Commerce DevOps Platform

Welcome! This guide will help you test the e-commerce platform **even if you know nothing about cloud infrastructure**. Everything is automated and easy to use.

## 📋 Table of Contents

1. [Quick Start](#-quick-start)
2. [What You'll Need](#-what-youll-need)
3. [Testing Your Local Setup](#-testing-your-local-setup)
4. [Testing AWS Deployment](#-testing-aws-deployment)
5. [Understanding Test Results](#-understanding-test-results)
6. [Troubleshooting](#-troubleshooting)
7. [Advanced Usage](#-advanced-usage)

---

## 🚀 Quick Start

**Want to test everything right now? Just run this:**

```bash
./run_all_tests.sh --local-only
```

That's it! The script will:
- ✅ Start all services automatically
- ✅ Run all tests
- ✅ Show you clear results
- ✅ Clean up everything when done

---

## 🛠 What You'll Need

### For Local Testing (Recommended for Beginners)

You only need these tools installed on your computer:

1. **Docker Desktop** - [Download here](https://www.docker.com/products/docker-desktop)
   - Click the link, download, install, and open it
   - Make sure it shows "Docker is running"

2. **Terminal/Command Line**
   - Mac: Use "Terminal" app (already installed)
   - Windows: Use "PowerShell" or "Command Prompt"
   - Linux: Use your favorite terminal

3. **curl** and **jq** (Usually pre-installed)
   - Mac: Already installed
   - Linux: Run `sudo apt-get install curl jq`
   - Windows: Included in Git Bash

### For AWS Testing (Optional - Advanced)

Only needed if you want to test your AWS deployment:

1. **AWS Account** - You need access to AWS
2. **AWS CLI** - [Installation guide](https://aws.amazon.com/cli/)
3. **AWS Credentials** - Run `aws configure` to set up

---

## 🏠 Testing Your Local Setup

### The Easiest Way - Test Everything

Just run this command from the project root:

```bash
./run_all_tests.sh --local-only
```

### What Happens?

1. **Docker containers start** - The script automatically starts:
   - PostgreSQL database
   - Product service
   - Order service
   - Frontend service

2. **Tests run** - The script tests:
   - ✅ All services are healthy
   - ✅ You can create products
   - ✅ You can create orders
   - ✅ Database is working
   - ✅ Services talk to each other

3. **Results shown** - You see:
   - Green ✓ for passing tests
   - Red ✗ for failing tests
   - Summary at the end

4. **Cleanup** - Everything stops and cleans up

### Quick Health Check

Just want to verify everything is running?

```bash
./run_all_tests.sh --quick
```

This runs only health checks (super fast!).

### Keep Services Running

Want to keep services running to manually test?

```bash
./run_all_tests.sh --local-only --keep-containers
```

Now you can:
- Visit http://localhost:3000 in your browser
- Test the API manually
- Investigate any issues

When done, stop services:
```bash
docker compose down
```

---

## 🔍 Testing Individual Features

Want to test just one thing? Use these commands:

### Test Health Checks Only
```bash
./tests/local/test_health.sh
```
**What it does:** Checks if all services are responding

### Test Product Service
```bash
./tests/local/test_products.sh
```
**What it does:** Tests creating, listing, and validating products

### Test Order Service
```bash
./tests/local/test_orders.sh
```
**What it does:** Tests creating orders, stock validation, price calculation

### Test Frontend
```bash
./tests/local/test_frontend.sh
```
**What it does:** Tests API gateway and request proxying

### Test Database
```bash
./tests/local/test_database.sh
```
**What it does:** Tests database connectivity and data persistence

---

## ☁️ Testing AWS Deployment

**Note:** This requires AWS credentials and a deployed infrastructure.

### Test Everything on AWS

```bash
./run_all_tests.sh --aws-only
```

### Test ECS Services

```bash
./tests/aws/test_ecs.sh
```
**What it does:** Checks your ECS cluster, services, and tasks

### Test Load Balancer

```bash
./tests/aws/test_alb.sh
```
**What it does:** Checks ALB routing and target health

---

## 📊 Understanding Test Results

### Reading the Output

```
Health Checks                                               ✓ PASS
Product Service                                             ✓ PASS
Order Service                                               ✓ PASS
Frontend                                                    ✓ PASS
Database                                                    ✓ PASS

═══════════════════════════════════════════════════════════
Total: 5 | Passed: 5 | Failed: 0 | Skipped: 0
═══════════════════════════════════════════════════════════

[SUCCESS] All tests passed! 🎉
```

### What Each Status Means

- **✓ PASS** (Green) - Everything works! 🎉
- **✗ FAIL** (Red) - Something is broken 😞
- **⊘ SKIP** (Yellow) - Test was skipped (e.g., AWS test but no credentials)

### Test Reports

After running tests, check the `tests/results/` folder:

```
tests/results/
  ├── test-report-20250117-143022.json    # Machine-readable results
  └── test-report-20250117-143022.html    # Pretty web report
```

Open the `.html` file in your browser for a nice visual report!

---

## 🔧 Troubleshooting

### Problem: "Docker not found"

**Solution:**
1. Install Docker Desktop from https://www.docker.com/products/docker-desktop
2. Make sure Docker is running (look for the Docker icon in your system tray)
3. Run `docker --version` to verify

### Problem: "Port already in use"

**Solution:**
```bash
# Stop all containers
docker compose down

# If that doesn't work, stop all Docker containers
docker stop $(docker ps -aq)

# Try again
./run_all_tests.sh --local-only
```

### Problem: "Service failed to start"

**Solution:**
```bash
# Check service logs
docker compose logs product-service
docker compose logs order-service
docker compose logs frontend

# Rebuild containers
docker compose down -v
docker compose build --no-cache
./run_all_tests.sh --local-only
```

### Problem: "Tests fail but I don't know why"

**Solution:**
```bash
# Run with verbose output
./run_all_tests.sh --local-only --verbose

# This shows detailed error messages
```

### Problem: "Database connection failed"

**Solution:**
```bash
# Wait a bit longer for PostgreSQL to start
docker compose down
docker compose up -d
sleep 30  # Wait 30 seconds
./tests/local/test_health.sh
```

### Problem: "AWS tests fail with credentials error"

**Solution:**
```bash
# Configure AWS credentials
aws configure

# Enter your:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Default output format (json)

# Try again
./run_all_tests.sh --aws-only
```

---

## 🎓 Advanced Usage

### Run with Verbose Output

See exactly what's happening:
```bash
./run_all_tests.sh --verbose
```

### Test Both Local and AWS

```bash
./run_all_tests.sh
```

### Custom Test Combinations

```bash
# Quick local check
./run_all_tests.sh --local-only --quick

# Verbose AWS tests
./run_all_tests.sh --aws-only --verbose

# Keep containers for debugging
./run_all_tests.sh --local-only --keep-containers --verbose
```

### Add Your Own Tests

Want to add a new test? It's easy!

1. Create a new test file in `tests/local/`:
   ```bash
   cp tests/local/test_health.sh tests/local/test_myfeature.sh
   ```

2. Edit the file and add your test logic

3. Make it executable:
   ```bash
   chmod +x tests/local/test_myfeature.sh
   ```

4. Add it to `tests/local/test_all.sh`:
   ```bash
   run_test_suite "My Feature" "${SCRIPT_DIR}/test_myfeature.sh"
   ```

That's it! Your test will run with all the others.

---

## 📚 Test Categories Explained

### 1. Health Checks
**What:** Verifies all services respond to /health endpoints
**Why:** Ensures basic service availability
**When to run:** Always run this first

### 2. Product Service Tests
**What:** Tests product CRUD operations
**Why:** Ensures product catalog works
**Tests:**
- List all products
- Get single product
- Create new product
- Validate input (negative prices, missing fields)
- Check seed data

### 3. Order Service Tests
**What:** Tests order creation and validation
**Why:** Ensures order processing works
**Tests:**
- List all orders
- Create new order
- Validate stock availability
- Validate product existence
- Calculate total price
- Check order status

### 4. Frontend Tests
**What:** Tests API gateway functionality
**Why:** Ensures frontend proxies requests correctly
**Tests:**
- Root endpoint responds
- Health check works
- Proxy to product service
- Proxy to order service
- CORS headers present

### 5. Database Tests
**What:** Tests database connectivity and persistence
**Why:** Ensures data is stored correctly
**Tests:**
- Database is accessible
- Services connect to database
- Data persists after creation
- Table constraints enforced

### 6. AWS ECS Tests (Advanced)
**What:** Tests ECS deployment
**Why:** Ensures cloud deployment is healthy
**Tests:**
- Cluster exists and is active
- Services are running
- Tasks are healthy
- Desired count matches running count

### 7. AWS ALB Tests (Advanced)
**What:** Tests load balancer
**Why:** Ensures routing works correctly
**Tests:**
- ALB is accessible
- Routes work (/products, /orders)
- Target groups are healthy
- Health checks pass

---

## 🎯 Best Practices

### For Developers

1. **Always test locally first**
   ```bash
   ./run_all_tests.sh --local-only
   ```

2. **Run quick checks frequently**
   ```bash
   ./run_all_tests.sh --quick
   ```

3. **Use verbose mode when debugging**
   ```bash
   ./run_all_tests.sh --verbose
   ```

4. **Keep containers running to investigate failures**
   ```bash
   ./run_all_tests.sh --keep-containers
   ```

### For CI/CD Pipelines

1. **Always generate reports**
   ```bash
   ./run_all_tests.sh --local-only
   # Reports in tests/results/
   ```

2. **Check exit codes**
   ```bash
   if ./run_all_tests.sh --local-only; then
       echo "Tests passed!"
   else
       echo "Tests failed!"
       exit 1
   fi
   ```

### For Production Deployments

1. **Test AWS deployment after Terraform apply**
   ```bash
   ./run_all_tests.sh --aws-only
   ```

2. **Verify all components**
   ```bash
   ./tests/aws/test_ecs.sh
   ./tests/aws/test_alb.sh
   ```

---

## 📝 Summary

### For Complete Beginners

1. Install Docker Desktop
2. Open terminal
3. Navigate to project folder
4. Run: `./run_all_tests.sh --local-only`
5. Look for green ✓ symbols
6. Done! 🎉

### For Developers

- Use `--quick` for fast checks
- Use `--verbose` for debugging
- Use `--keep-containers` to investigate
- Add custom tests as needed
- Check `tests/results/` for reports

### For DevOps Engineers

- Test locally before deploying
- Use `--aws-only` for deployment verification
- Integrate with CI/CD pipelines
- Monitor test reports
- Add infrastructure tests as needed

---

## 🆘 Getting Help

### Still Stuck?

1. **Check logs:**
   ```bash
   docker compose logs
   ```

2. **Run with verbose output:**
   ```bash
   ./run_all_tests.sh --verbose
   ```

3. **Check individual service:**
   ```bash
   curl http://localhost:8000/health
   curl http://localhost:8001/health
   curl http://localhost:3000/health
   ```

4. **Restart everything:**
   ```bash
   docker compose down -v
   docker compose up -d --build
   ```

### Need More Help?

- Check the main README.md
- Review the architecture docs in `docs/`
- Look at existing tests for examples
- Check troubleshooting guide in `docs/runbooks/troubleshooting.md`

---

## 🎊 You're Ready!

You now know how to:
- ✅ Run all tests with one command
- ✅ Test individual features
- ✅ Read and understand test results
- ✅ Troubleshoot common issues
- ✅ Add your own tests
- ✅ Test AWS deployments

**Remember:** Testing is easy! Just run:
```bash
./run_all_tests.sh --local-only
```

Happy testing! 🚀
