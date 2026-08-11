# Security control matrix

Every control in the platform, where it is implemented, and what it defends
against. "Preventive" controls block bad states from being created;
"detective" controls surface them; "corrective" ones bound the damage.

## Infrastructure security

| # | Control | Type | Implementation | Threat mitigated |
|---|---|---|---|---|
| I1 | Terraform format gate | Preventive | `templates/security/terraform-fmt.yml` | Malicious/accidental changes hidden in noisy diffs |
| I2 | Terraform validation | Preventive | `templates/security/terraform-validate.yml` | Invalid configs failing mid-apply, leaving half-built (often insecure) state |
| I3 | TFLint + azurerm ruleset | Preventive | `templates/security/terraform-lint.yml`, `.tflint.hcl` | Deprecated/incorrect provider usage that silently weakens posture |
| I4 | Checkov policy-as-code | Preventive | `templates/security/checkov-scan.yml`, `.checkov.yaml` | Public exposure, missing encryption, weak TLS reaching Azure at all |
| I5 | Azure Policy — deny assignments | Preventive | `terraform/modules/policy` | Privileged pods, untrusted registries — even for changes made outside the pipeline |
| I6 | Azure Policy — compliance gate | Detective | `templates/security/azure-policy-check.yml` | Drift introduced via portal/CLI between runs |
| I7 | Plan-artifact hand-off | Preventive | `infrastructure-pipeline.yml` Apply stage | TOCTOU: applying something other than what was reviewed |
| I8 | Remote state hardening | Preventive | `terraform/backend.tf` | State theft (state contains resource details and can contain secrets) |

## Application security

| # | Control | Type | Implementation | Threat mitigated |
|---|---|---|---|---|
| A1 | Secret scanning, full history | Detective | `templates/security/gitleaks-scan.yml`, `.gitleaks.toml` | Committed credentials (still live even after "removal") |
| A2 | Dependency (SCA) scanning | Preventive | `templates/security/dependency-scan.yml` | Shipping known-vulnerable third-party packages |
| A3 | SAST + quality gate | Preventive | `templates/security/sonarqube-sast.yml`, `sonar-project.properties` | Injection sinks, weak crypto, tainted flows in first-party code |
| A4 | Container image scan (pre-push) | Preventive | `templates/security/trivy-image-scan.yml` | Vulnerable OS/app layers reaching the registry |
| A5 | SBOM generation | Detective | same template (CycloneDX output) | "Are we affected?" taking days during the next Log4Shell |
| A6 | License allowlist | Preventive | `templates/security/license-compliance.yml` | Copyleft obligations entering the product unreviewed |
| A7 | Input validation in the app | Preventive | `app/src/main.py` (pydantic bounds/pattern) | Injection & abuse via API payloads |
| A8 | Base image pinned by digest | Preventive | `app/Dockerfile` | Tag-repoint / registry compromise of the base image |

## Deployment security

| # | Control | Type | Implementation | Threat mitigated |
|---|---|---|---|---|
| D1 | Environment approvals | Preventive | ADO Environments (`docs/pipeline-design.md`) | Unauthorized promotion; separation of duties (requester ≠ approver) |
| D2 | Release gates (branch control, hours, lock) | Preventive | ADO Environments | Deploys from unreviewed branches; concurrent-deploy races |
| D3 | Signature verification at deploy | Preventive | `templates/deploy/deploy-aks.yml` | Tampered or out-of-band images being promoted |
| D4 | Keyless artifact signing | Preventive | `templates/deploy/cosign-sign.yml` | Signing-key theft (no key exists); provenance forgery (Rekor log) |
| D5 | Workload identity federation (pipeline) | Preventive | `terraform/modules/identity`, all `AzureCLI@2` steps | Service-connection secret theft — there is no secret |
| D6 | Workload identity (pods) | Preventive | `kubernetes/serviceaccount.yaml` | Credential exfiltration from the cluster |
| D7 | Key Vault via CSI driver | Preventive | `kubernetes/secretproviderclass.yaml` | Secrets in env vars / etcd / `kubectl describe` |
| D8 | RBAC everywhere | Preventive | KV RBAC-only, AKS Azure RBAC, AcrPull/AcrPush scoping | Lateral movement from any single compromised identity |
| D9 | Pod Security 'restricted' + hardened spec | Preventive | `kubernetes/namespace.yaml`, `deployment.yaml` | Container escape primitives (root, caps, writable rootfs) |
| D10 | Default-deny NetworkPolicy | Preventive/Corrective | `kubernetes/networkpolicy.yaml` | Lateral movement from a compromised pod |
| D11 | Resource limits | Corrective | `kubernetes/deployment.yaml` | DoS blast radius of a runaway/compromised pod |
| D12 | Audit logging (kube-audit, guard, Defender) | Detective | `terraform/modules/aks` | Undetected cluster compromise; forensics gaps |

## RBAC summary

| Identity | Scope | Role | Why this and nothing more |
|---|---|---|---|
| `id-…-deployer` (pipeline) | Platform resource group | Contributor + AcrPush | Deploys the platform; cannot manage RBAC or touch other RGs |
| `id-…-workload` (pods) | Key Vault | Key Vault Secrets User | Reads secrets; cannot write, delete, or see other resources |
| AKS kubelet identity | ACR | AcrPull | Pulls images; cannot push or delete |
| Platform team (humans) | AKS | Azure Kubernetes Service RBAC Admin via Entra group | Group-based, PIM-eligible, auditable; no standing local admin |
| Service owners (humans) | ADO `app-prod` environment | Approver | Human gate on production; not an Azure data-plane role at all |
