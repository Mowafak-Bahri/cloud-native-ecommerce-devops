# Contributing to Cloud-Native E-Commerce Platform

## Introduction
Thank you for contributing to the Cloud-Native E-Commerce Platform reference implementation. This document explains how to propose changes, follow engineering standards, and collaborate with the maintainers. Participation requires adherence to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Development Setup
**Prerequisites**
- AWS CLI v2+
- Terraform v1.5+
- Docker Engine v20+
- Git v2.30+
- Node.js 18+ and Python 3.11+ for service-specific development

**Local Environment**
1. Fork and clone the repository:
   ```bash
   git clone https://github.com/<your-gh-handle>/cloud-native-ecommerce-devops.git
   cd cloud-native-ecommerce-devops
   git remote add upstream https://github.com/original/cloud-native-ecommerce-devops.git
   ```
2. Copy `.env.example` files within each service and populate local secrets (never commit actual secrets).
3. Start dependencies with docker-compose for local testing:
   ```bash
   docker-compose up --build
   ```
4. Verify health endpoints:
   ```bash
   curl http://localhost:3000/health
   curl http://localhost:8001/health
   curl http://localhost:8002/health
   ```

## Contribution Workflow
1. **Fork** the repository and keep your fork synced with upstream.
2. **Create a feature branch** from `main` using `type/short-description` naming (e.g., `feat/cart-discounts`).
3. **Implement changes** following the code standards below.
4. **Run tests locally**, including unit, integration, and linting commands relevant to the services touched.
5. **Commit** with Conventional Commit messages.
6. **Push** the branch to your fork and open a Pull Request against `main`.
7. **Engage in review**, address feedback, and ensure CI checks are green.

## Commit Message Convention
We follow [Conventional Commits](https://www.conventionalcommits.org/).

**Format**
```
type(scope): subject

body (optional)

BREAKING CHANGE: details (if applicable)
```

**Allowed Types**
`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`

**Examples**
```
feat(product-service): add pagination to catalog endpoint
fix(terraform): correct alb security group ingress rules
docs(readme): update architecture diagram
```

See `docs/git-workflow.md` for branching, rebasing, and release procedures.

## Code Standards
- **Python (FastAPI)**: PEP 8, Black formatter (`black .`), isort, pytest for tests.
- **Node.js/TypeScript**: ESLint with project rules, Prettier formatting, Jest tests.
- **Terraform**: `terraform fmt`, `terraform validate`, maintain module READMEs and examples.
- **Docker**: Minimal base images, multi-stage builds, non-root users, pinned versions, and healthchecks.
- **General**: Add comments only when the intent is non-obvious, keep functions small, document public interfaces.

## Testing Requirements
- Add or update tests with every code change.
- Run service-specific unit tests and integration tests (see `package.json` and `pyproject.toml` scripts).
- Execute `docker-compose -f docker-compose.test.yml up --build --exit-code-from tests` for cross-service validation.
- Pull requests must pass all GitHub Actions checks before review.

## Pull Request Process
- Ensure your PR description references related issues, testing evidence, and rollout considerations.
- Complete the PR checklist in `.github/pull_request_template.md`.
- Request review from at least one maintainer; two approvals are recommended for risky changes.
- Address review comments with follow-up commits or amend before merge.
- CI must be green. Rebase onto `main` if necessary.
- Maintainers use **Squash and Merge** to keep history linear.

## Documentation
- Update README sections, service-specific docs, and runbooks when functionality changes.
- Document significant architectural decisions via ADRs in `docs/adr/`.
- Keep API contracts in `docs/api/` synchronized with code and tests.

## Security
- Never store or commit plaintext credentials, keys, or tokens.
- Use AWS Secrets Manager locally when possible; otherwise, use `.env.local` excluded from git.
- Report vulnerabilities as described in [SECURITY.md](SECURITY.md); do not open public issues.
- CI/CD runs Trivy, tfsec, and CodeQL. Fix reported issues before requesting review.

## Questions and Help
- Use GitHub Discussions for architectural questions and community support.
- Open GitHub Issues for bugs; include reproduction steps, logs, and expected behavior.
- Submit feature requests via GitHub Issues labeled `enhancement`; attach ADR drafts when proposing large changes.
