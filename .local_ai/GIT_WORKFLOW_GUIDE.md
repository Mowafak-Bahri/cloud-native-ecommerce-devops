# 🔄 Professional Git Workflow Guide

**Making Your Development History Look Natural and Professional**

This guide demonstrates industry-standard Git practices for incremental development, professional commit messages, and collaborative workflows.

---

## 🎯 Philosophy: Small, Focused, Incremental Commits

### Why Small Commits Matter

**In professional software engineering:**
- ✅ Each commit represents a single logical change
- ✅ Makes code review easier and faster
- ✅ Simplifies debugging (git bisect)
- ✅ Enables easy rollbacks
- ✅ Creates clear project history
- ✅ Demonstrates professional development discipline

**Anti-patterns (what NOT to do):**
- ❌ `git commit -m "fixed stuff"`
- ❌ One massive commit with 50 files
- ❌ Vague commit messages
- ❌ Mixing unrelated changes
- ❌ Committing broken code

---

## 📝 Commit Message Convention

We follow the **Conventional Commits** specification used by companies like Google, Angular, and many open-source projects.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

| Type | Description | Example |
|------|-------------|---------|
| `feat` | New feature | `feat(product-service): add product search endpoint` |
| `fix` | Bug fix | `fix(order-service): correct inventory calculation` |
| `docs` | Documentation only | `docs(readme): add architecture diagram` |
| `style` | Code style (formatting, no logic change) | `style(frontend): apply prettier formatting` |
| `refactor` | Code change that neither fixes bug nor adds feature | `refactor(db): extract connection pool to module` |
| `perf` | Performance improvement | `perf(product-service): add database index on product_id` |
| `test` | Adding or updating tests | `test(order-service): add unit tests for order creation` |
| `build` | Build system or dependencies | `build(docker): update node base image to 18-alpine` |
| `ci` | CI/CD changes | `ci(github-actions): add terraform validation step` |
| `chore` | Maintenance tasks | `chore(deps): update terraform to 1.6.0` |
| `revert` | Revert a previous commit | `revert: feat(auth): add JWT authentication` |

### Scope (Optional but Recommended)

The scope should be the part of the codebase affected:
- `product-service`
- `order-service`
- `frontend`
- `terraform`
- `docker`
- `ci`
- `monitoring`
- `security`

### Subject Line Rules

1. **Limit to 50 characters** (if possible, 72 max)
2. **Use imperative mood** ("add" not "added" or "adds")
3. **Don't capitalize first letter** (lowercase after type)
4. **No period at the end**
5. **Be specific and descriptive**

**Good examples:**
```
feat(product-service): add pagination to products endpoint
fix(terraform): correct security group ingress rules
docs(architecture): document ECS task scaling strategy
```

**Bad examples:**
```
Fixed bug
Updated files
WIP
asdf
```

### Body (Optional for Complex Changes)

- Explain **what** and **why**, not **how**
- Wrap at 72 characters
- Separate from subject with a blank line

**Example:**
```
feat(product-service): add Redis caching for product catalog

Implements Redis caching layer to reduce database load during
high-traffic periods. Cache invalidation occurs on product updates.

Benchmarks show 80% reduction in database queries and 60% improvement
in API response time for product listing endpoints.
```

### Footer (For Breaking Changes or Issue References)

```
BREAKING CHANGE: remove support for legacy authentication
Closes #123
Refs #456
```

---

## 🌲 Branch Strategy

### Branch Naming Convention

```
<type>/<short-description>

Examples:
feature/add-product-search
fix/inventory-calculation-bug
docs/add-runbook
refactor/database-connection-pool
chore/update-dependencies
```

### Main Branches

| Branch | Purpose | Protection |
|--------|---------|------------|
| `main` | Production-ready code | Protected, requires PR |
| `develop` | Integration branch | Protected, requires PR |
| `staging` | Pre-production testing | May be protected |

### Feature Branch Workflow

```bash
# 1. Create feature branch from main
git checkout main
git pull origin main
git checkout -b feature/add-monitoring-dashboard

# 2. Make small, incremental commits (see below)
git add <files>
git commit -m "feat(monitoring): add CloudWatch dashboard module"

# 3. Push regularly
git push -u origin feature/add-monitoring-dashboard

# 4. Create pull request when ready
# 5. After review and approval, merge to main
# 6. Delete feature branch after merge
```

---

## 🔨 Incremental Development Pattern

### Example: Building the Product Service

**Instead of this (bad):**
```bash
# One massive commit
git add .
git commit -m "Added product service"
```

**Do this (professional):**

#### **Commit 1: Project Structure**
```bash
mkdir -p services/product-service/app
touch services/product-service/app/__init__.py
touch services/product-service/app/main.py
touch services/product-service/requirements.txt

git add services/product-service/
git commit -m "feat(product-service): initialize project structure

Create basic directory structure for product service with
FastAPI application skeleton."
```

#### **Commit 2: Dependencies**
```bash
# Edit requirements.txt
git add services/product-service/requirements.txt
git commit -m "build(product-service): add Python dependencies

Add FastAPI, uvicorn, psycopg2, and pydantic for API development
and database connectivity."
```

#### **Commit 3: Database Configuration**
```bash
# Add database connection code to main.py
git add services/product-service/app/main.py
git commit -m "feat(product-service): add database connection module

Implement PostgreSQL connection with environment variable
configuration and connection pooling."
```

#### **Commit 4: Data Model**
```bash
# Add Pydantic models
git add services/product-service/app/main.py
git commit -m "feat(product-service): add Product data model

Define Pydantic model for product validation with fields:
id, name, description, price, stock."
```

#### **Commit 5: Health Check Endpoint**
```bash
# Add /health endpoint
git add services/product-service/app/main.py
git commit -m "feat(product-service): add health check endpoint

Implement /health endpoint for ALB target health monitoring.
Returns service status and database connectivity check."
```

#### **Commit 6: Database Schema**
```bash
# Add table creation code
git add services/product-service/app/main.py
git commit -m "feat(product-service): add database schema initialization

Create products table with auto-incrementing ID, name, description,
price (DECIMAL), and stock (INTEGER) fields."
```

#### **Commit 7: GET Endpoint**
```bash
# Add GET /products endpoint
git add services/product-service/app/main.py
git commit -m "feat(product-service): add GET /products endpoint

Implement endpoint to retrieve all products from database with
proper error handling and JSON response formatting."
```

#### **Commit 8: POST Endpoint**
```bash
# Add POST /products endpoint
git add services/product-service/app/main.py
git commit -m "feat(product-service): add POST /products endpoint

Implement endpoint to create new products with input validation,
database insertion, and return created product with assigned ID."
```

#### **Commit 9: Dockerfile**
```bash
# Create Dockerfile
git add services/product-service/Dockerfile
git commit -m "build(product-service): add production Dockerfile

Multi-stage Docker build with Python 3.11-slim base image,
health check configuration, and non-root user for security."
```

#### **Commit 10: Documentation**
```bash
# Add README
git add services/product-service/README.md
git commit -m "docs(product-service): add service documentation

Document API endpoints, environment variables, local development
setup, and deployment instructions."
```

**Result:** 10 focused commits instead of 1 blob. Clear development progression.

---

## 📋 Commit Patterns for Different Tasks

### Infrastructure (Terraform)

```bash
# Commit 1: VPC module
git add terraform/modules/networking/
git commit -m "feat(terraform): add VPC networking module

Create VPC with public/private subnets across 3 AZs, internet
gateway, and route tables following AWS best practices."

# Commit 2: Security groups
git add terraform/modules/networking/security_groups.tf
git commit -m "feat(terraform): add security group definitions

Define security groups for ALB, ECS tasks, and RDS with
least-privilege ingress/egress rules."

# Commit 3: Outputs
git add terraform/modules/networking/outputs.tf
git commit -m "feat(terraform): add networking module outputs

Export VPC ID, subnet IDs, and security group IDs for use
in dependent modules."
```

### CI/CD Workflows

```bash
# Commit 1: Workflow skeleton
git add .github/workflows/deploy.yml
git commit -m "ci: add deployment workflow skeleton

Create GitHub Actions workflow structure with job definitions
for build, test, and deploy stages."

# Commit 2: Build job
git add .github/workflows/deploy.yml
git commit -m "ci: implement Docker build job

Add Docker build step with image tagging using git SHA
and push to Amazon ECR."

# Commit 3: Security scanning
git add .github/workflows/deploy.yml
git commit -m "ci: add container security scanning

Integrate Trivy for vulnerability scanning of Docker images
with fail-on-critical severity configuration."
```

### Documentation

```bash
# Commit 1: Architecture diagram
git add docs/architecture.png
git commit -m "docs: add system architecture diagram

Visual representation of AWS infrastructure showing VPC,
ECS services, ALB, RDS, and monitoring components."

# Commit 2: Runbook
git add docs/runbook.md
git commit -m "docs: add operational runbook

Document common troubleshooting procedures for ECS task
failures, database connectivity issues, and deployment rollbacks."

# Commit 3: Cost analysis
git add docs/cost-analysis.md
git commit -m "docs: add cost optimization analysis

Document cost breakdown by service, optimization strategies
implemented, and projected scaling costs."
```

---

## 🔍 Code Review Process

### Before Creating Pull Request

```bash
# 1. Ensure you're up to date with main
git checkout main
git pull origin main
git checkout feature/your-branch
git rebase main

# 2. Review your commits
git log --oneline main..HEAD

# 3. Clean up commit history if needed (interactive rebase)
git rebase -i main

# 4. Ensure tests pass
npm test  # or appropriate test command

# 5. Push to remote
git push origin feature/your-branch --force-with-lease
```

### Pull Request Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Documentation update
- [ ] Refactoring
- [ ] Performance improvement

## Changes Made
- Added X functionality
- Modified Y component
- Fixed Z issue

## Testing
- [ ] Local testing completed
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manually tested in dev environment

## Screenshots (if applicable)
[Add screenshots of UI changes or monitoring dashboards]

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
- [ ] Terraform plan reviewed (if infrastructure change)

## Related Issues
Closes #123
```

---

## 🚀 Daily Workflow Example

### Morning Workflow

```bash
# 1. Pull latest changes
git checkout main
git pull origin main

# 2. Check what you were working on
git log --oneline -5
git status

# 3. Create or continue feature branch
git checkout -b feature/add-x-ray-tracing
# or
git checkout feature/add-x-ray-tracing
git rebase main
```

### During Development

```bash
# Make small change (one logical unit)
# Edit file...

# Stage specific files (not git add .)
git add services/product-service/app/main.py

# Review what you're committing
git diff --staged

# Commit with descriptive message
git commit -m "feat(product-service): add X-Ray tracing middleware

Instrument FastAPI application with AWS X-Ray SDK to enable
distributed tracing across microservices."

# Push frequently
git push origin feature/add-x-ray-tracing
```

### End of Day

```bash
# Commit any work in progress (if needed)
git add .
git commit -m "wip: X-Ray integration (incomplete)

Partial implementation of tracing. Need to:
- Complete subsegment instrumentation
- Add environment variable configuration
- Test trace propagation"

git push origin feature/add-x-ray-tracing
```

### Next Day

```bash
# Continue from where you left off
git checkout feature/add-x-ray-tracing
git log -1  # Review yesterday's work

# If you committed WIP, you can amend or continue
git add .
git commit --amend -m "feat(product-service): add X-Ray tracing middleware

Complete implementation with subsegment instrumentation,
environment variable configuration, and trace propagation."

# Force push (only on feature branches, never on main!)
git push origin feature/add-x-ray-tracing --force-with-lease
```

---

## 📊 Example Development Timeline with Commits

### Week 1: Local Development (15-20 commits)

**Day 1-2: Service scaffolding**
```
feat(product-service): initialize project structure
build(product-service): add Python dependencies
feat(product-service): add database connection module
feat(order-service): initialize project structure
build(order-service): add Node.js dependencies
feat(order-service): add database connection module
```

**Day 3-4: Core functionality**
```
feat(product-service): add Product data model
feat(product-service): add health check endpoint
feat(product-service): add GET /products endpoint
feat(product-service): add POST /products endpoint
feat(order-service): add Order data model
feat(order-service): add health check endpoint
feat(order-service): add GET /orders endpoint
feat(order-service): add POST /orders endpoint
```

**Day 5-7: Containerization**
```
build(product-service): add production Dockerfile
build(order-service): add production Dockerfile
build(frontend): add production Dockerfile
build: add docker-compose for local development
docs: add local development setup guide
```

### Week 2: AWS Infrastructure (20-30 commits)

**Day 8-9: Networking**
```
feat(terraform): add VPC networking module
feat(terraform): add security group definitions
feat(terraform): add networking module outputs
test(terraform): validate networking module
docs(terraform): document networking architecture
```

**Day 10-11: Database & Container Registry**
```
feat(terraform): add RDS PostgreSQL module
feat(terraform): add ECR repositories
feat(terraform): configure RDS security and backups
fix(terraform): correct RDS subnet group configuration
docs(terraform): document database architecture
```

**Day 12-14: ECS & Load Balancer**
```
feat(terraform): add ECS cluster module
feat(terraform): add ALB configuration
feat(terraform): add product-service task definition
feat(terraform): add order-service task definition
feat(terraform): add frontend task definition
feat(terraform): add ECS service definitions
feat(terraform): configure ALB target groups
feat(terraform): add health check configuration
fix(terraform): adjust health check thresholds
docs(terraform): add deployment architecture diagram
```

### Week 3: CI/CD & Monitoring (15-25 commits)

**Day 15-16: GitHub Actions**
```
ci: add deployment workflow skeleton
ci: implement Docker build job
ci: add container security scanning
ci: add ECR push step
ci: add ECS deployment step
ci: add rollback on failure
test(ci): validate workflow with test deployment
docs(ci): document deployment process
```

**Day 17-18: Monitoring**
```
feat(terraform): add CloudWatch log groups
feat(terraform): add CloudWatch dashboard
feat(terraform): add CloudWatch alarms
feat(monitoring): add X-Ray tracing configuration
feat(product-service): add X-Ray instrumentation
feat(order-service): add X-Ray instrumentation
docs(monitoring): add observability runbook
```

**Day 19-21: Security**
```
feat(terraform): add Secrets Manager configuration
feat(terraform): add IAM roles with least privilege
refactor(services): use Secrets Manager for DB credentials
feat(terraform): add VPC Flow Logs
security(docker): update base images to latest patches
security(terraform): enable encryption at rest for RDS
docs(security): document security architecture
```

### Week 4: Optimization & Documentation (10-15 commits)

**Day 22-23: Cost Optimization**
```
feat(terraform): add Fargate Spot configuration
feat(terraform): add auto-scaling policies
feat(lambda): add automated tear-down function
perf(product-service): add database connection pooling
perf(product-service): add index on product_id column
docs(finops): add cost optimization playbook
```

**Day 24-28: Documentation & Polish**
```
docs: add comprehensive README
docs: add architecture decision records
docs: add API documentation
docs: add troubleshooting guide
refactor: apply consistent code formatting
test: add integration test suite
docs: add contribution guidelines
docs: add changelog
```

**Total: 60-90 commits over 4 weeks** (natural, incremental development)

---

## 🎯 Git Commands Reference

### Essential Daily Commands

```bash
# Status and changes
git status                          # Check current state
git diff                            # See unstaged changes
git diff --staged                   # See staged changes
git log --oneline -10               # Recent commits

# Staging
git add <file>                      # Stage specific file
git add <directory>                 # Stage directory
git add -p                          # Interactive staging (review each change)

# Committing
git commit -m "message"             # Commit with message
git commit --amend                  # Modify last commit
git commit --amend --no-edit        # Amend without changing message

# Branching
git branch                          # List local branches
git branch -a                       # List all branches (including remote)
git checkout -b <branch>            # Create and switch to new branch
git checkout <branch>               # Switch to existing branch
git branch -d <branch>              # Delete merged branch
git branch -D <branch>              # Force delete branch

# Synchronization
git fetch origin                    # Fetch remote changes
git pull origin main                # Pull and merge from main
git push origin <branch>            # Push branch to remote
git push --force-with-lease         # Safe force push (only on feature branches)

# History and inspection
git log --graph --oneline           # Visual commit history
git log --author="Name"             # Commits by author
git log --since="2 weeks ago"       # Recent commits
git show <commit>                   # Show commit details
git blame <file>                    # See who changed each line

# Undoing changes
git restore <file>                  # Discard unstaged changes
git restore --staged <file>         # Unstage file
git reset HEAD~1                    # Undo last commit (keep changes)
git reset --hard HEAD~1             # Undo last commit (discard changes)
git revert <commit>                 # Create new commit that undoes a commit

# Cleaning
git clean -n                        # Preview untracked files to delete
git clean -fd                       # Delete untracked files and directories
```

### Advanced Workflow Commands

```bash
# Interactive rebase (clean up commits before PR)
git rebase -i main
# Then squash, reword, or reorder commits

# Cherry-pick specific commit
git cherry-pick <commit-hash>

# Stash work in progress
git stash                           # Save and clear working directory
git stash list                      # List stashed changes
git stash pop                       # Apply and remove most recent stash
git stash apply                     # Apply stash without removing

# Compare branches
git diff main..feature-branch
git log main..feature-branch

# Find commits that introduced a bug
git bisect start
git bisect bad                      # Current commit is bad
git bisect good <commit>            # Known good commit
# Git will binary search, mark each commit as good/bad
git bisect reset                    # Exit bisect mode
```

---

## ✅ Commit Quality Checklist

Before each commit, verify:

- [ ] **Single responsibility:** Does this commit do one thing?
- [ ] **Descriptive message:** Would someone understand this without reading code?
- [ ] **Conventional format:** Does it follow `type(scope): subject` format?
- [ ] **Code works:** Does the code compile/run after this commit?
- [ ] **Tests pass:** Do all tests still pass?
- [ ] **No secrets:** No API keys, passwords, or credentials?
- [ ] **No generated files:** No build artifacts, node_modules, etc.?
- [ ] **Staged correctly:** Only files related to this change?

---

## 🎓 Professional Development Habits

### Daily Habits
1. **Morning:** Pull latest changes, review yesterday's commits
2. **During work:** Commit every logical change (not every line)
3. **Before break:** Push current work to backup
4. **End of day:** Ensure all commits are pushed, write next-day plan

### Weekly Habits
1. Review commit history for the week
2. Ensure branch is up to date with main
3. Clean up merged branches
4. Update documentation based on changes

### Red Flags (Things That Make You Look Unprofessional)
- ❌ Commits like "asdf", "WIP", "fix", "update"
- ❌ One massive commit with 50 files
- ❌ Committing and reverting multiple times
- ❌ Leaving merge conflict markers in code
- ❌ Committing commented-out code
- ❌ Inconsistent or no commit messages
- ❌ Committing secrets or credentials

---

## 🚀 Summary: Make Your Git History Tell a Story

**Good Git history shows:**
- Logical progression from idea to implementation
- Clear thinking and planning
- Professional development discipline
- Easy code review and debugging
- Respect for team collaboration

**Your commit history is your professional signature.**

Every commit is a snapshot of your decision-making, planning, and execution. Make it count.

---

**Next:** Start implementing with small commits. Your first commit should be:

```bash
git commit -m "docs: add project README with architecture overview"
```

Then build incrementally from there. 🎯