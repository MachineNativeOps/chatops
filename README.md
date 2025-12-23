# Machine Native Ops - Kubernetes + GitOps 控制面工程骨架

## 專案概述

這是一個完整的 Kubernetes + GitOps 控制面工程骨架，提供：

- **聲明式治理**：`root/` 目錄包含 9 份 `.root.*.yaml` 治理宣告
- **GitOps 部署**：ArgoCD + Kustomize 自動化部署
- **Policy Gates**：Kyverno 政策驗證
- **Evidence Chain**：完整的供應鏈安全證據鏈
- **多平台 CI/CD**：GitHub Actions + GitLab CI + Cloudflare 支援

## 快速開始

### 本地開發

```bash
# 克隆倉庫
git clone https://github.com/MachineNativeOps/machine-native-ops.git
cd machine-native-ops

# 安裝依賴工具（參考 tools/tool-versions.txt）
make setup-tools

# 執行完整驗證流程
make all

# 個別驗證步驟
make fmt          # 格式化檢查
make lint         # 代碼檢查
make schema       # Schema 驗證
make test-vectors # 測試向量
make render       # 產生 K8s manifests
make policy       # 政策檢查
make evidence     # 產生證據鏈
make verify-evidence # 驗證證據鏈
```

### 部署到 Kubernetes

```bash
# 產生 manifests
make render

# 部署到 dev 環境
kubectl apply -k deploy/kustomize/overlays/dev

# 或使用 ArgoCD
kubectl apply -f deploy/argocd/
```

## 專案結構

```
.
├── root/                    # 治理層宣告
│   ├── .root.*.yaml        # 9 份治理宣告檔案
│   ├── schemas/            # JSON Schema
│   ├── scripts/            # 驗證腳本
│   └── tests/              # 測試向量
├── deploy/                 # 部署層
│   ├── kustomize/          # Kustomize 配置
│   ├── argocd/             # ArgoCD 配置
│   └── policies/           # 政策配置
├── supply-chain/           # 供應鏈安全
├── scripts/                # 通用腳本
├── .github/workflows/      # GitHub Actions
├── .gitlab-ci.yml          # GitLab CI
└── dist/                   # 輸出目錄
```

## 治理模型

### Root Config (.root.config.yaml)
定義系統基本配置：系統 ID、時區、部署模式、預設命名空間。

### Root Governance (.root.governance.yaml)
定義治理模型：角色（admin/operator/viewer）、政策、審計規則。

### Root Module Registry (.root.modules.yaml)
定義模組註冊表：模組列表、依賴關係、入口點。

### Root Super Execution (.root.super-execution.yaml)
定義執行流程：bootstrap → validate → deploy，包含觸發器和回退機制。

### Root Trust (.root.trust.yaml)
定義信任模型：信任根、金鑰輪替、驗證政策。

### Root Provenance (.root.provenance.yaml)
定義來源追蹤：來源、元資料、審計軌跡。

### Root Integrity (.root.integrity.yaml)
定義完整性保護：雜湊鎖定、漂移檢測、凍結政策。

### Root Bootstrap (.root.bootstrap.yaml)
定義初始化序列：初始化步驟、預載模組、健康檢查。

### Root Gates Map (.root.gates.map.yaml)
定義驗證閘門：輸入、工具、通過條件、失敗處理。

## Evidence Chain

每次執行 `make all` 都會產生完整的證據鏈：

```
dist/evidence/
├── gate-report.json          # 閘門執行報告
├── digests.json              # 檔案雜湊清單
├── repo-fingerprint.json     # 倉庫指紋
├── toolchain.json            # 工具鏈版本
├── provenance.intoto.json    # 來源證明
├── attestation.intoto.json   # 證明聲明
└── merkle-root.json          # Merkle 根雜湊
```

## CI/CD 支援

### GitHub Actions
- **CI**：完整驗證流程，上傳 evidence artifacts
- **Gate Lock & Attest**：手動觸發的供應鏈驗證

### GitLab CI
- 相同的驗證流程，支援 GitLab Runner

### Cloudflare
- 預留部署掛點，支援 Pages/Workers 部署

## 安全要求

- ✅ 不提交任何真實密鑰或 Token
- ✅ 所有 YAML 必須通過 Schema 驗證
- ✅ 政策閘門阻止不安全配置
- ✅ 完整的供應鏈證據鏈
- ✅ 支援簽章驗證（可 stub）

## 文件大小治理

- 建議上限：64 KB / 檔
- 硬性上限：256 KB / 檔
- 超過必須按語意責任邊界拆分
- 所有拆分必須在 README 建立索引

## 貢獻指南

請參考 [CONTRIBUTING.md](CONTRIBUTING.md) 了解分支策略、提交規範、CI 要求。

## 安全政策

請參考 [SECURITY.md](SECURITY.md) 了解安全提交規範、漏洞回報流程。

## 授權

本專案採用 Apache-2.0 授權，詳見 [LICENSE](LICENSE) 檔案。

## 版本

當前版本：`0.1.0`