SHELL := /usr/bin/env bash
.ONESHELL:
.SHELLFLAGS := -euo pipefail -c

PY ?= python3
NODE ?= node
PIP ?= pip
PNPM ?= pnpm

ARTIFACTS_DIR ?= artifacts
AUDIT_DIR ?= var/audit

.PHONY: help
help:
	@printf "%s\n" \
	"Targets:" \
	"  bootstrap          Install local tooling (python deps) and init dirs" \
	"  lint               Run lint/format checks (python + ts if present)" \
	"  policy             Run conftest policy checks" \
	"  scan               Run baseline security scans (local mode)" \
	"  quality-gates      Compute quality score + gate verdict (local)" \
	"  naming-discovery   Run naming discovery (K8s manifests + repo files)" \
	"  naming-plan        Generate naming migration plan template" \
	"  naming-dryrun      Dry-run rename plan (simulated)" \
	"  audit              Append a local audit event" \
	"  artifact-build      Convert docs (md/pdf/docx) to structured artifacts" \
	"  py-test            Run python tests (engine) if present" \
	"  ts-build           Build typescript (gateway) if present" \
	"  e2e-rest           Run E2E smoke (rest->grpc) if present"

.PHONY: bootstrap
bootstrap:
	mkdir -p "$(ARTIFACTS_DIR)"/{reports,evidence,modules,audit,tmp} "$(AUDIT_DIR)"
	$(PY) -m pip install --upgrade pip >/dev/null
	$(PIP) install -r scripts/requirements.txt

.PHONY: lint
lint:
	$(PY) scripts/ci/lint_python.py
	$(PY) scripts/ci/lint_repo_structure.py

.PHONY: policy
policy:
	$(PY) scripts/policy/run_conftest.py --policy-dir policies/opa --target-dir deployments

.PHONY: scan
scan:
	$(PY) scripts/security/scan_iac_checkov.py --root deployments --out "$(ARTIFACTS_DIR)/reports/checkov.json"
	$(PY) scripts/security/scan_kubeaudit.py --root deployments --out "$(ARTIFACTS_DIR)/reports/kubeaudit.json"
	$(PY) scripts/security/scan_kubebench_stub.py --out "$(ARTIFACTS_DIR)/reports/kube-bench.json"

.PHONY: quality-gates
quality-gates:
	$(PY) scripts/quality/quality_gates.py --out "$(ARTIFACTS_DIR)/reports/quality-gates.json"

.PHONY: naming-discovery
naming-discovery:
	$(PY) scripts/naming/discovery.py --root deployments --out "$(ARTIFACTS_DIR)/reports/naming-discovery.json"

.PHONY: naming-plan
naming-plan:
	$(PY) scripts/naming/plan.py --discovery "$(ARTIFACTS_DIR)/reports/naming-discovery.json" --out "$(ARTIFACTS_DIR)/reports/naming-plan.csv"

.PHONY: naming-dryrun
naming-dryrun:
	$(PY) scripts/naming/dryrun.py --plan "$(ARTIFACTS_DIR)/reports/naming-plan.csv" --out "$(ARTIFACTS_DIR)/reports/naming-dryrun.json"

.PHONY: audit
audit:
	$(PY) scripts/audit/append_audit.py --event "$(EVENT)" --actor "$(ACTOR)" --why "$(WHY)" --how "$(HOW)" --trace-id "$(TRACE_ID)" --out "$(AUDIT_DIR)/audit.jsonl"

.PHONY: artifact-build
artifact-build:
	$(PY) scripts/artifacts/build_modules.py --in artifacts/sources --out artifacts/modules --reports artifacts/reports

.PHONY: py-test
py-test:
	if [ -d services/engine-python ]; then \
		$(PY) -m pytest -q services/engine-python/tests; \
	else \
		echo "skip: services/engine-python not found"; \
	fi

.PHONY: ts-build
ts-build:
	if [ -d services/gateway-ts ]; then \
		cd services/gateway-ts && (command -v pnpm >/dev/null 2>&1 && pnpm -v >/dev/null 2>&1 || npm i -g pnpm) && pnpm i && pnpm build; \
	else \
		echo "skip: services/gateway-ts not found"; \
	fi

.PHONY: e2e-rest
e2e-rest:
	if [ -f tests/e2e/rest_to_grpc.sh ]; then \
		bash tests/e2e/rest_to_grpc.sh; \
	else \
		echo "skip: tests/e2e/rest_to_grpc.sh not found"; \
	fi
