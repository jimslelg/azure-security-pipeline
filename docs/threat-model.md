# Threat model — the delivery platform itself

Scope: the CI/CD platform (repo → pipeline → registry → cluster), modeled
with STRIDE. The sample app's business logic is intentionally trivial; the
interesting attack surface here is the *pipeline*, which in most real
organizations is the highest-privilege, least-scrutinized system they run.

## Assets

1. **Cloud credentials / identities** — the deployer identity can reshape the platform.
2. **The artifact stream** — whoever controls what lands in ACR controls production code execution.
3. **Terraform state** — a map of the estate, potentially containing secrets.
4. **Key Vault contents** — application secrets.
5. **The approval mechanism** — the last human gate before production.

## STRIDE analysis

| Threat | Scenario | Mitigations (control matrix ref) |
|---|---|---|
| **S**poofing | Attacker impersonates the pipeline to Azure | No secret to steal — OIDC federation with exact subject match on the service connection (D5); tokens are minutes-lived |
| | Attacker pushes a look-alike image to prod | Cosign verification against a pinned certificate identity at every deploy (D3, D4); Azure Policy allows only our ACR (I5) |
| **T**ampering | Malicious edit to pipeline YAML removes a gate | Approvals live on Environment resources, not YAML (D1/D2); branch policy requires review; the removal is visible in the diff (I1 keeps diffs readable) |
| | Plan swapped between review and apply | Apply consumes the published plan artifact byte-for-byte (I7) |
| | Base image tag repointed upstream | Digest pinning in the Dockerfile (A8) |
| **R**epudiation | "Nobody knows who deployed that" | Immutable tags = commit SHA; Rekor transparency log for signatures (D4); kube-audit + guard logs (D12); approvals recorded in ADO |
| **I**nformation disclosure | Secret committed to git | GitLeaks on full history, first gate in the pipeline (A1) |
| | Secrets read from the cluster | CSI tmpfs mounts — no K8s Secret objects, no env vars (D7); Key Vault RBAC read-only for the workload (D8) |
| | State file exfiltration | Entra-only auth on the state backend, no shared keys (I8) |
| **D**enial of service | Runaway/compromised pod starves the cluster | Resource limits (D11); one-at-a-time prod deploys via exclusive lock (D2) |
| | Malicious PR burns pipeline minutes / probes Azure | PR stages hold zero cloud credentials by design |
| **E**levation of privilege | Compromised pod pivots to Azure | Pod identity holds exactly one read-only role (D6/D8); NetworkPolicy default-deny bounds lateral movement (D10) |
| | Compromised pod escapes the container | Pod Security 'restricted': non-root, no caps, no escalation, seccomp, read-only rootfs (D9); Azure Policy denies privileged pods cluster-wide (I5) |
| | Developer self-approves own prod change | Requester ≠ approver on `app-prod` (D1) |

## Accepted risks (documented, not hidden)

| Risk | Rationale | Revisit when |
|---|---|---|
| AKS API server is public (IP-restricted, Entra-authed) rather than fully private | A private control plane requires self-hosted agents; out of scope for a reference implementation | Moving to self-hosted/managed DevOps agents |
| Microsoft-hosted build agents are shared infrastructure | Accepted for a portfolio project; regulated workloads should use isolated agent pools | Compliance requirements demand it |
| `--ignore-unfixed` on Trivy gates | Failing builds on CVEs with no available fix trains teams to bypass the gate; unfixed findings remain visible in reports | A fix ships (the gate then catches it) |
| No DAST stage | Requires a running review environment; on the roadmap | Roadmap post-v1 |
