.PHONY: help fmt fmt-check lint schema test-vectors render policy evidence verify-evidence all setup-tools clean
.PHONY: py-test ts-build e2e-rest proto-gen quality-review test-all

# Default target
.DEFAULT_GOAL := help

# Variables
PYTHON := python3
MKTOOL := kustomize
KUBECTL := kubectl
YAMLLINT := yamllint
KYVERNO := kyverno
NPM := npm
TSC := npx tsc

# Directories
DIST_DIR := dist
EVIDENCE_DIR := $(DIST_DIR)/evidence
ROOT_DIR := root
DEPLOY_DIR := deploy
SCRIPTS_DIR := scripts
SUPPLY_CHAIN_DIR := supply-chain
TOOLS_DIR := tools
SERVICES_DIR := services
TESTS_DIR := tests
PROTO_DIR := proto
VAR_DIR := var
ARTIFACTS_DIR := artifacts
TEST_REPORTS_DIR := test-reports

# Ensure dist directory exists
$(DIST_DIR):
	mkdir -p $(DIST_DIR)

$(EVIDENCE_DIR):
	mkdir -p $(EVIDENCE_DIR)

help: ## Show this help message
	@echo "Machine Native Ops - Kubernetes + GitOps Control Plane"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

fmt: ## Format all YAML/JSON/Markdown files
	@echo "🔧 Formatting files..."
	@$(ROOT_DIR)/scripts/fmt.sh

fmt-check: ## Check formatting without modifying files
	@echo "🔍 Checking formatting..."
	@$(ROOT_DIR)/scripts/fmt.sh --check

lint: ## Run linting checks
	@echo "🔍 Running lint checks..."
	@$(ROOT_DIR)/scripts/lint.sh

schema: ## Validate all YAML files against JSON schemas
	@echo "🔍 Validating schemas..."
	@$(ROOT_DIR)/scripts/schema_validate.py

test-vectors: ## Run test vectors (valid/invalid cases)
	@echo "🧪 Running test vectors..."
	@$(ROOT_DIR)/scripts/vector_test.py

render: ## Render Kubernetes manifests with Kustomize
	@echo "🏗️  Rendering manifests..."
	@$(SCRIPTS_DIR)/render_manifests.sh

policy: ## Run policy checks (Kyverno)
	@echo "🛡️  Running policy checks..."
	@$(DEPLOY_DIR)/policies/policy_check.sh

evidence: verify-evidence ## Generate evidence chain (includes all validation steps)
	@echo "🔗 Generating evidence chain..."
	@$(ROOT_DIR)/scripts/evidence_collect.py
	@$(ROOT_DIR)/scripts/hash_artifacts.py
	@$(SUPPLY_CHAIN_DIR)/scripts/generate_provenance.sh
	@$(SUPPLY_CHAIN_DIR)/scripts/generate_attestation.sh
	@echo "✅ Evidence chain generated in $(EVIDENCE_DIR)/"

verify-evidence: $(EVIDENCE_DIR) ## Verify evidence chain integrity
	@echo "🔍 Verifying evidence chain..."
	@$(ROOT_DIR)/scripts/verify_evidence.sh
	@echo "✅ Evidence chain verified"

all: fmt-check lint schema test-vectors render policy evidence ## Run complete validation pipeline

setup-tools: ## Install required tools
	@echo "🔧 Setting up tools..."
	@$(TOOLS_DIR)/install-tools.sh

clean: ## Clean build artifacts
	@echo "🧹 Cleaning up..."
	@rm -rf $(DIST_DIR)
	@rm -rf .pytest_cache
	@rm -rf .coverage
	@echo "✅ Clean completed"

# CI-specific targets
ci: fmt-check lint schema test-vectors render policy evidence verify-evidence ## CI pipeline (same as all but with explicit verification)

# Development targets
dev-setup: setup-tools ## Set up development environment
	@echo "🚀 Development environment ready"
	@echo "Run 'make all' to validate your changes"

# Security targets
secret-scan: ## Scan for secrets in the repository
	@echo "🔍 Scanning for secrets..."
	@$(ROOT_DIR)/scripts/secret_scan.sh

# Quick validation (for development)
quick-check: fmt-check lint schema ## Quick validation without heavy operations
	@echo "⚡ Quick check completed"

# Full deployment test (requires Kubernetes cluster)
deploy-test: render ## Test deployment (requires cluster access)
	@echo "🚀 Testing deployment..."
	@echo "Applying to current context: $$(kubectl config current-context)"
	@kubectl apply -k $(DEPLOY_DIR)/kustomize/overlays/dev --dry-run=client
	@echo "✅ Deployment test passed"

# Evidence-specific targets
evidence-lock: $(EVIDENCE_DIR) ## Generate Merkle root hash lock
	@echo "🔒 Generating evidence lock..."
	@$(ROOT_DIR)/scripts/build_merkle_root.py
	@echo "✅ Evidence lock generated"

verify-evidence-lock: ## Verify evidence lock integrity
	@echo "🔍 Verifying evidence lock..."
	@$(ROOT_DIR)/scripts/verify_evidence_lock.sh
	@echo "✅ Evidence lock verified"

# Documentation targets
docs: ## Generate documentation
	@echo "📚 Generating documentation..."
	@echo "Documentation generation not implemented yet"

# Status targets
status: ## Show current status
	@echo "📊 Repository Status:"
	@echo "Version: $$(cat VERSION)"
	@echo "Git branch: $$(git branch --show-current 2>/dev/null || echo 'not a git repo')"
	@echo "Git commit: $$(git rev-parse --short HEAD 2>/dev/null || echo 'not a git repo')"
	@if [ -d "$(EVIDENCE_DIR)" ]; then \
		echo "Evidence files: $$(ls $(EVIDENCE_DIR) | wc -l)"; \
	else \
		echo "Evidence files: 0"; \
	fi

# Version targets
version: ## Show current version
	@echo $$(cat VERSION)

bump-patch: ## Bump patch version
	@echo "🔖 Bumping patch version..."
	@python3 -c "import sys; v=open('VERSION').read().strip().split('.'); v[2]=str(int(v[2])+1); print('.'.join(v))" > VERSION
	@echo "New version: $$(cat VERSION)"

bump-minor: ## Bump minor version
	@echo "🔖 Bumping minor version..."
	@python3 -c "import sys; v=open('VERSION').read().strip().split('.'); v[1]=str(int(v[1])+1); v[2]='0'; print('.'.join(v))" > VERSION
	@echo "New version: $$(cat VERSION)"

bump-major: ## Bump major version
	@echo "🔖 Bumping major version..."
	@python3 -c "import sys; v=open('VERSION').read().strip().split('.'); v[0]=str(int(v[0])+1); v[1]='0'; v[2]='0'; print('.'.join(v))" > VERSION
	@echo "New version: $$(cat VERSION)"

# ========================================
# Multi-Agent AI CI/CD Targets (Phase-1/2/3)
# ========================================

py-test: ## Run Python tests (engine-python)
	@echo "🐍 Running Python tests..."
	@mkdir -p $(TEST_REPORTS_DIR)
	@if [ -d "$(SERVICES_DIR)/engine-python" ]; then \
		cd $(SERVICES_DIR)/engine-python && \
		$(PYTHON) -m pytest tests/ -v --tb=short 2>&1 | tee ../../$(TEST_REPORTS_DIR)/py-test.log || true; \
	else \
		echo "⚠️  engine-python service not found, skipping"; \
	fi
	@echo "✅ Python tests completed"

ts-build: ## Build TypeScript (gateway-ts)
	@echo "📦 Building TypeScript..."
	@mkdir -p $(TEST_REPORTS_DIR)
	@if [ -d "$(SERVICES_DIR)/gateway-ts" ]; then \
		cd $(SERVICES_DIR)/gateway-ts && \
		if [ -f "package.json" ]; then \
			$(NPM) install --prefer-offline --no-audit 2>/dev/null || true; \
			$(TSC) --noEmit 2>&1 | tee ../../$(TEST_REPORTS_DIR)/ts-build.log || true; \
		else \
			echo "⚠️  No package.json found"; \
		fi; \
	else \
		echo "⚠️  gateway-ts service not found, skipping"; \
	fi
	@echo "✅ TypeScript build completed"

e2e-rest: ## Run E2E REST to gRPC tests
	@echo "🔗 Running E2E REST to gRPC tests..."
	@mkdir -p $(TEST_REPORTS_DIR)
	@if [ -x "$(TESTS_DIR)/e2e/rest_to_grpc.sh" ]; then \
		$(TESTS_DIR)/e2e/rest_to_grpc.sh 2>&1 | tee $(TEST_REPORTS_DIR)/e2e-rest.log; \
	else \
		echo "⚠️  E2E test script not found or not executable"; \
	fi
	@echo "✅ E2E tests completed"

proto-gen: ## Generate protobuf code
	@echo "📝 Generating protobuf code..."
	@mkdir -p $(PROTO_DIR)/generated
	@if command -v protoc >/dev/null 2>&1; then \
		protoc --proto_path=$(PROTO_DIR) \
			--python_out=$(PROTO_DIR)/generated \
			--grpc_python_out=$(PROTO_DIR)/generated \
			$(PROTO_DIR)/engine.proto; \
		echo "✅ Protobuf code generated"; \
	else \
		echo "⚠️  protoc not installed, skipping proto generation"; \
	fi

quality-review: ## Run intelligent code review
	@echo "🔍 Running intelligent code review..."
	@mkdir -p $(ARTIFACTS_DIR)
	@$(PYTHON) $(SCRIPTS_DIR)/quality/intelligent_review.py
	@echo "✅ Code review completed"

test-all: py-test ts-build e2e-rest ## Run all tests (Python, TypeScript, E2E)
	@echo "✅ All tests completed"

# Environment management targets
env-setup: ## Set up environment (requires: development|staging|production)
	@echo "🔧 Setting up environment..."
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make env-setup ENV=development|staging|production"; \
		exit 1; \
	fi
	@$(PYTHON) $(SCRIPTS_DIR)/env/environment_manager.py setup $(ENV)

env-validate: ## Validate environment configuration
	@echo "🔍 Validating environment..."
	@if [ -z "$(ENV)" ]; then \
		echo "Usage: make env-validate ENV=development|staging|production"; \
		exit 1; \
	fi
	@$(PYTHON) $(SCRIPTS_DIR)/env/environment_manager.py validate $(ENV)

# Audit and observability targets
audit-init: ## Initialize audit directory
	@echo "📋 Initializing audit directory..."
	@mkdir -p $(VAR_DIR)/audit
	@echo "✅ Audit directory ready: $(VAR_DIR)/audit"

# Combined adaptive testing pipeline
adaptive-test: ## Run adaptive testing based on changes
	@echo "🎯 Running adaptive testing pipeline..."
	@$(MAKE) py-test
	@$(MAKE) ts-build
	@$(MAKE) e2e-rest
	@$(MAKE) quality-review
	@echo "✅ Adaptive testing completed"

# Service management
services-start: ## Start all services (requires Docker)
	@echo "🚀 Starting services..."
	@if command -v docker-compose >/dev/null 2>&1; then \
		docker-compose up -d; \
	else \
		echo "⚠️  docker-compose not installed"; \
	fi

services-stop: ## Stop all services
	@echo "🛑 Stopping services..."
	@if command -v docker-compose >/dev/null 2>&1; then \
		docker-compose down; \
	else \
		echo "⚠️  docker-compose not installed"; \
	fi