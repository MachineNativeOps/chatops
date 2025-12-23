# Kubernetes + GitOps 控制面工程骨架建立任務

## Milestone A：治理層（root）落地
- [x] 克隆空的 Git 倉庫
- [x] 建立基本根目錄檔案（README.md, LICENSE, .gitignore, VERSION, SECURITY.md）
- [ ] 建立 CONTRIBUTING.md
- [ ] 建立 Makefile
- [ ] 建立 root/ 目錄結構
- [ ] 建立 root/README.md
- [ ] 建立 9 份 .root.*.yaml 檔案
- [ ] 建立 root/jobs/ 目錄與檔案
- [ ] 建立 root/init/steps/ 腳本
- [ ] 建立 9 份 JSON Schema 檔案
- [ ] 建立 root/scripts/ 驗證腳本
- [ ] 建立 root/tests/vectors/ 測試向量
- [ ] 測試 make schema 和 make test-vectors

## Milestone B：部署層（Kustomize + ArgoCD）落地
- [ ] 建立 deploy/ 目錄結構
- [ ] 建立 deploy/kustomize/base/ 資源
- [ ] 建立 deploy/kustomize/overlays/dev|prod
- [ ] 建立 deploy/argocd/ 配置
- [ ] 建立 deploy/policies/kyverno/ 政策
- [ ] 建立 scripts/render_manifests.sh
- [ ] 測試 make render

## Milestone C：Policy Gates（Kyverno）落地
- [ ] 建立 policy/policy_check.sh
- [ ] 測試 make policy

## Milestone D：Evidence Chain（核心）
- [ ] 建立 supply-chain/ 目錄與腳本
- [ ] 建立證據鏈生成腳本
- [ ] 建立證據驗證腳本
- [ ] 測試 make evidence 和 make verify-evidence

## Milestone E：CI/CD Wrapper
- [ ] 建立 .github/workflows/ci.yaml
- [ ] 建立 .github/workflows/gate-lock-attest.yaml
- [ ] 建立 .gitlab-ci.yml 模板
- [ ] 建立 deploy/cloudflare/README.md 掛點
- [ ] 測試 GitHub Actions

## Milestone F：工具與依賴
- [ ] 建立 tools/ 目錄與依賴檔案
- [ ] 建立 dist/ 輸出目錄

## 最終驗證
- [ ] 執行 make all 完整驗證
- [ ] 檢查檔案大小規範
- [ ] 提交所有變更到倉庫