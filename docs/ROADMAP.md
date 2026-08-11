# Roadmap

Delivery plan for `azure-security-pipeline`. Each phase lands on its own
`feature/<phase>` branch and is fast-forward merged into `main`, so `main`
always reflects the latest completed phase.

## Phase 1 — Foundation ✅

- Repository scaffold, license, ignore rules
- Roadmap and documentation skeleton

## Phase 2 — Infrastructure as Code (Terraform)

- Remote state backend (Azure Storage + state locking)
- Modules: network, AKS, ACR, Key Vault, managed identity, Azure Policy
- Environment separation via `environments/*.tfvars` (dev / prod)
- Secure-by-default settings: private endpoints, RBAC-only Key Vault,
  Microsoft Entra–integrated AKS, no local auth on ACR

## Phase 3 — Infrastructure Security Pipeline

- `terraform fmt` / `terraform validate` gates
- TFLint with azurerm ruleset
- Checkov policy-as-code scan (fails the build on HIGH/CRITICAL)
- Azure Policy compliance validation against the target subscription
- Reusable Azure DevOps step templates for every control

## Phase 4 — Application Security Pipeline

- Sample containerized workload (FastAPI) with tests
- GitLeaks secret scanning (full history)
- Dependency / SCA scanning (Trivy)
- SAST via SonarQube with quality gate enforcement
- Container image scanning (Trivy) with severity thresholds
- OSS license compliance gate

## Phase 5 — Deployment Security

- Azure DevOps Environments with manual approvals and branch control checks
- Release gates (scan results must be clean before promotion)
- Workload identity federation — zero stored cloud credentials
- Key Vault integration via Secrets Store CSI driver
- Container image signing with Cosign (keyless) and admission verification
- Kubernetes hardening: non-root, read-only rootfs, NetworkPolicy, resource limits

## Phase 6 — Documentation & Diagrams

- Architecture and pipeline diagrams (Mermaid)
- Security control matrix mapped to the pipeline stages
- Threat model (STRIDE) for the delivery platform
- DevSecOps best-practices guide
- Final README

## Future ideas (post-v1)

- DAST stage (OWASP ZAP baseline scan against a review environment)
- SBOM generation (Syft) and attestation storage
- Defender for Cloud / Defender for DevOps integration
- Policy-as-code for Kubernetes (Gatekeeper/OPA constraint templates)
- Chaos/drift detection scheduled runs (`terraform plan -detailed-exitcode`)
