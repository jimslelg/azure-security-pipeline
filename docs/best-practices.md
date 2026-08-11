# DevSecOps best practices

The principles this repository implements, distilled. Each one links to
where it is demonstrated in code.

## 1. Shift left, but keep a right-side backstop

Scanning code is cheaper than scanning production — Checkov, GitLeaks,
TFLint, and SAST all run before anything is created. But preventive scans
only see what flows through the pipeline, so Azure Policy enforces the same
invariants at the platform (deny privileged pods, deny untrusted registries)
and a post-deploy compliance gate detects drift.
*See:* `.checkov.yaml`, `terraform/modules/policy`, `templates/security/azure-policy-check.yml`.

## 2. Eliminate credentials instead of protecting them

The strongest secret management is having no secret. Every hop —
pipeline→Azure, pods→Key Vault, kubelet→ACR, humans→AKS — uses federated
short-lived tokens. Cosign signs keylessly. Nothing exists to rotate, leak,
or find in a dump.
*See:* `terraform/modules/identity`, `kubernetes/serviceaccount.yaml`, `templates/deploy/cosign-sign.yml`.

## 3. Untrusted code gets zero privileges

PR validation stages hold no service connection. A malicious PR can fail its
own build; it cannot probe or mutate Azure. Publishing (push/sign/deploy) is
hard-gated on the protected `main` branch.
*See:* `infrastructure-pipeline.yml` (Validate), `application-pipeline.yml` (stage conditions).

## 4. What was reviewed is what runs

Two instances of the same idea: Terraform applies the exact reviewed plan
artifact (never re-plans at apply time), and deploys verify the cosign
signature on the exact image digest that was scanned and signed. Mutable
references (tags, re-plans) are where supply-chain attacks live.
*See:* `infrastructure-pipeline.yml` (Apply), `templates/deploy/deploy-aks.yml`.

## 5. Human gates must be outside the code they gate

Approvals, branch controls, and locks are configured on Azure DevOps
Environment resources — a PR cannot delete the approval that would have
blocked it. Separation of duties: the requester cannot approve their own
production deploy.
*See:* `docs/pipeline-design.md` § "Where the human controls live".

## 6. Fail the build honestly, silence findings loudly

Gates are deny-by-default. Every suppression — Checkov skips, GitLeaks
allowlist entries, Trivy `--ignore-unfixed` — lives in a reviewed file with a
written justification, never in an ad-hoc CLI flag. An exception is a
decision, and decisions leave audit trails.
*See:* `.checkov.yaml`, `.gitleaks.toml`.

## 7. Pin everything

Terraform providers (`~>` + committed lock file), scanner versions in every
template, base images by digest, image tags = commit SHA. Unpinned
dependencies make builds unreproducible and create silent upgrade attack
surface.
*See:* `terraform/.terraform.lock.hcl`, `app/Dockerfile`, any template's `*Version` parameter.

## 8. Defense in depth on the workload

The same invariant enforced at four layers: the Dockerfile creates a
non-root user; the pod spec pins `runAsUser` and drops capabilities; the
namespace enforces Pod Security `restricted` at admission; Azure Policy
denies privileged pods cluster-wide. Any single layer failing changes
nothing.
*See:* `app/Dockerfile`, `kubernetes/deployment.yaml`, `kubernetes/namespace.yaml`, `terraform/modules/policy`.

## 9. Segment by default

Default-deny NSG on the subnet, default-deny NetworkPolicy in the namespace,
private endpoints for PaaS, ClusterIP services. Exposure is an explicit,
reviewed act — never a default.
*See:* `terraform/modules/network`, `kubernetes/networkpolicy.yaml`, `kubernetes/service.yaml`.

## 10. Make evidence a build artifact

Every scan publishes its raw output (SARIF, SBOM, license inventory, plan
files) even when the gate fails — especially when it fails. Auditors and
incident responders get evidence; engineers get diffable history.
*See:* the `PublishBuildArtifacts` steps in every security template.

## 11. Least privilege is per-identity, not per-team

Four identities, four narrow grants: deployer (Contributor on one RG +
AcrPush), workload (read one vault), kubelet (pull from one registry),
humans (group-based, PIM-eligible). No identity can do another's job.
*See:* `docs/security-controls.md` § "RBAC summary".

## 12. Immutable, attributable releases

Image tag = commit SHA, signature in a public transparency log, approvals
recorded, audit logs shipped to Log Analytics. Every production binary
answers: which commit, which pipeline run, who approved, when.
*See:* `application-pipeline.yml` (imageTag), `templates/deploy/cosign-sign.yml`, `terraform/modules/aks` (diagnostics).
