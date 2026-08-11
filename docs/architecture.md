# Architecture

## Platform overview

```mermaid
flowchart TB
    subgraph ado["Azure DevOps"]
        pipe["Pipelines<br/>(infra + app)"]
        env["Environments<br/>approvals · branch control · locks"]
    end

    subgraph azure["Azure — rg-azsecpipe-&lt;env&gt;"]
        subgraph vnet["VNet 10.100.0.0/16"]
            subgraph snetaks["snet-aks (NSG: deny internet)"]
                aks["AKS<br/>Entra RBAC · local accounts OFF<br/>workload identity · Azure Policy add-on<br/>Calico · Defender"]
            end
            subgraph snetpe["snet-pe"]
                pekv["PE: Key Vault"]
                peacr["PE: ACR"]
            end
        end
        kv["Key Vault<br/>RBAC-only · purge protection<br/>default-deny firewall"]
        acr["ACR Premium<br/>admin OFF · anonymous pull OFF<br/>export OFF · retention"]
        pol["Azure Policy<br/>deny privileged/untrusted-registry pods<br/>audit KV + storage posture"]
        log["Log Analytics<br/>kube-audit · guard · Defender"]
        mi["Managed identities<br/>deployer (OIDC↔ADO) · workload (OIDC↔pods)"]
    end

    sigstore["Sigstore<br/>Fulcio CA + Rekor log"]

    pipe -- "OIDC federation<br/>(no stored secrets)" --> mi
    pipe -- "push signed images" --> acr
    pipe -- "cosign sign/verify" --> sigstore
    pipe -- "kubectl via kubelogin" --> aks
    env -. "gates every deploy stage" .- pipe
    aks -- "AcrPull (kubelet MI)" --> peacr --> acr
    aks -- "CSI driver, workload identity" --> pekv --> kv
    pol -. "admission + compliance" .- aks
    aks -- "audit logs" --> log
```

## Trust boundaries

| Boundary | Crossing mechanism | Control |
|---|---|---|
| Developer → repo | git push / PR | Branch policies, GitLeaks full-history scan |
| Repo → pipeline | trigger | PR stage runs with **zero** cloud credentials |
| Pipeline → Azure | service connection | Workload identity federation (OIDC) — no client secret exists |
| Pipeline → registry | `az acr login` | Entra token, AcrPush scoped to the deployer identity |
| Registry → cluster | image pull | Kubelet managed identity (AcrPull); Azure Policy rejects other registries |
| Cluster → Key Vault | CSI driver | Pod workload identity, read-only role, private endpoint |
| Human → production | Environment approval | Separation of duties; requester ≠ approver |

## Identity model — no credential anywhere

Every arrow in the diagram above authenticates with a **federated, short-lived
token**. The platform stores no passwords, no client secrets, no signing
keys, and no kubeconfig with embedded certs:

- **Azure DevOps → Azure**: the service connection federates to
  `id-…-deployer` via OIDC (`terraform/modules/identity`).
- **Pods → Key Vault**: the app service account federates to
  `id-…-workload`, which holds only *Key Vault Secrets User*.
- **AKS → ACR**: the kubelet's managed identity holds *AcrPull*.
- **Humans → AKS**: Entra ID + `kubelogin`; Kubernetes local accounts are
  disabled at cluster creation.
- **Artifact signing**: Cosign keyless — ephemeral certificates from Fulcio,
  bound to the pipeline's OIDC identity, logged in Rekor.

## Network model

- PaaS data planes (Key Vault, ACR) sit behind **private endpoints** in a
  dedicated subnet; private DNS zones make FQDNs resolve to VNet addresses.
- The AKS subnet carries a **default-deny-inbound-from-internet** NSG.
- Inside the cluster, Calico enforces **default-deny NetworkPolicies** per
  namespace; the app's policy allows exactly DNS, HTTPS egress, and ingress
  from the ingress-controller namespace.
