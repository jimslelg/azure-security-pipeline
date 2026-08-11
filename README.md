# azure-security-pipeline

A security-first CI/CD pipeline showcasing DevSecOps automation with
Infrastructure as Code validation, secret detection, vulnerability scanning,
container security, policy enforcement, and automated deployment approvals.
Built to demonstrate secure software delivery in Azure environments.

> 🚧 Built incrementally — see [docs/ROADMAP.md](docs/ROADMAP.md) for the
> phase-by-phase delivery plan and what has landed so far.

## What this project demonstrates

| Layer | Controls |
|---|---|
| **Infrastructure security** | `terraform fmt` / `validate`, TFLint, Checkov policy-as-code, Azure Policy compliance validation |
| **Application security** | GitLeaks secret scanning, dependency (SCA) scanning, SonarQube SAST, Trivy container scanning, license compliance |
| **Deployment security** | Environment approvals, release gates, RBAC, workload identity (no stored credentials), Key Vault integration, Cosign-signed artifacts |

## Tech stack

Azure DevOps · Terraform · Checkov · TFLint · Trivy · SonarQube · GitLeaks ·
Azure Key Vault · Azure Policy · Docker · AKS · Cosign

## Repository layout

```
azure-security-pipeline/
├── azure-pipelines.yml     # Pipeline entry point (orchestrates all stages)
├── pipelines/              # Stage/step templates, incl. reusable security templates
├── terraform/              # IaC: AKS, ACR, Key Vault, network, policy, identity
├── app/                    # Sample containerized workload under test
├── kubernetes/             # Hardened AKS manifests
└── docs/                   # Architecture, security controls, threat model, roadmap
```

## License

MIT — see [LICENSE](LICENSE).
