# EQuiP AWS WorkSpaces — eucs-appstream

## Overview

This environment provisions Amazon WorkSpaces Personal desktops for the EQuiP application within the MoJ Modernisation Platform. Users are authenticated against the `equip.local` Active Directory domain via an AD Connector — there is no SAML federation to WorkSpaces itself. Entra ID serves only as a launch portal; all desktop authentication is handled by the on-premises AD.

The Terraform is structured as a reusable local module so that adding or removing workspaces is a single JSON edit.

---

## Architecture

```
User → Entra App (launch portal) → AWS WorkSpaces Web Access
                                        │
                                        ▼
                                  WorkSpaces Directory
                                        │
                                        ▼
                                    AD Connector
                                        │
                                        ▼
                                equip.local Domain Controllers
                                   (LDAP / Kerberos)
```

SAML, IAM federation (the SAML provider and IAM role), and networking (VPC, subnets, routing) are managed outside this Terraform — they are pre-provisioned by the Modernisation Platform and/or other teams.

---

## File Structure

```
eucs-appstream/
├── application_variables.json          # Per-environment configuration
├── locals.tf                           # deploy_workspaces flag
├── secrets.tf                          # AD connector password from Secrets Manager
├── equip-workspaces.tf                 # Root module call
├── outputs.tf                          # Registration code, directory ID, SG ID
├── modules/
│   └── workspaces/
│       ├── main.tf                     # All AWS resources
│       ├── variables.tf                # Module inputs
│       └── outputs.tf                  # Module outputs
│
│   (Platform-managed — do not edit)
├── platform_backend.tf
├── platform_base_variables.tf
├── platform_data.tf
├── platform_locals.tf
├── platform_providers.tf
├── platform_secrets.tf
├── networking.auto.tfvars.json
├── versions.tf
├── data.tf
└── README.md
```

---

## How the Modernisation Platform Environment Pattern Works

There are no `.tfvars` files per environment. Instead, Terraform **workspaces** represent environments. The CI/CD pipeline selects the workspace (e.g. `eucs-appstream-development`, `eucs-appstream-production`) and the same `.tf` files execute in each.

- `terraform.workspace` → `"eucs-appstream-production"`
- `platform_locals.tf` strips the app name to derive `local.environment` → `"production"`
- `application_variables.json` holds config per environment in an `accounts` map
- Values are accessed via `local.application_data.accounts[local.environment].your_key`

This means `application_variables.json` is the single place to configure environment-specific settings.

---

## What Each File Does

### `application_variables.json`

The central configuration file. Contains an `accounts` object keyed by environment name (`development`, `test`, `preproduction`, `production`). Each environment can define:

| Key | Type | Purpose |
|---|---|---|
| `deploy_workspaces` | `bool` | Whether to deploy the WorkSpaces infrastructure in this environment. If `false`, nothing is created. |
| `ad_connector_secret_name` | `string` | Name of the Secrets Manager secret holding the AD Connector service account password. |
| `security_group_name` | `string` | Override the security group name (to match existing click-ops resources). If omitted, defaults to `{app}-{env}-workspaces-sg`. |
| `ip_group_name` | `string` | Override the IP access control group name. If omitted, defaults to `{app}-{env}-ip-group`. |
| `ip_group_description` | `string` | Override the IP access control group description. |
| `domain_name` | `string` | The on-premises AD domain (e.g. `equip.local`). |
| `ad_connector_size` | `string` | AD Connector size — `"Small"` or `"Large"`. |
| `ad_connector_username` | `string` | Service account username used by AD Connector for LDAP binds (e.g. `svc_workspaces`). |
| `dns_ips` | `list(string)` | IP addresses of the `equip.local` domain controllers. |
| `default_ou` | `string` | Distinguished Name of the OU where WorkSpaces computer objects are placed. |
| `bundle_id` | `string` | Custom WorkSpaces bundle ID. Leave empty (`""`) until the golden image and bundle have been created via the console. When empty, no individual workspaces are provisioned — infrastructure (AD Connector, directory, SG, IP group) is still created. |
| `running_mode` | `string` | `"AUTO_STOP"` or `"ALWAYS_ON"`. |
| `auto_stop_timeout` | `number` | Minutes of inactivity before an AUTO_STOP workspace is stopped. |
| `ip_group_allowed_cidrs` | `list(object)` | Client IP ranges permitted to connect. Each object has `source` (CIDR) and `description`. |
| `workspace_users` | `map(string)` | Map of identifier keys to AD usernames. Each entry provisions one WorkSpace. |

Environments set to `"deploy_workspaces": false` (like `test` and `preproduction`) only need that single key — all other keys are ignored.

### `locals.tf`

Defines a single local:

- **`deploy_workspaces`** — reads `deploy_workspaces` from `application_variables.json` for the current environment, defaulting to `false` via `try()`. Controls whether the module is instantiated and whether the Secrets Manager lookup runs.

### `secrets.tf`

Manages the AD connector service account password in AWS Secrets Manager:

- **Secret name:** configured per environment via `ad_connector_secret_name` in `application_variables.json` (currently `equip-local-domain-join-account`)
- Only created when `deploy_workspaces` is `true`
- The secret is created by the CI/CD pipeline with a placeholder value (`CHANGE_ME`)
- After the first deploy, edit the secret value in the console (Secrets Manager → Retrieve secret value → Edit) using the `developer` SSO role
- `lifecycle { ignore_changes = [secret_string] }` ensures Terraform never overwrites the real password
- For environments where the secret already exists, a one-time `import` block is needed on first deploy

### `equip-workspaces.tf`

The root module call. Uses `count` with `local.deploy_workspaces` to conditionally instantiate the module. Passes:

- VPC ID and private subnet IDs (from `platform_data.tf` data sources — the shared `hmpps-{environment}` VPC)
- All configuration from `application_variables.json`
- The AD connector password from Secrets Manager
- The platform tags

### `outputs.tf`

Exposes key values from the module after `terraform apply`:

| Output | Purpose |
|---|---|
| `equip_workspaces_registration_code` | The WorkSpaces registration code — needed for the Entra app relay state URL (`https://workspaces.euc-sso.eu-west-2.aws.amazon.com/sso-idp?registrationCode=<CODE>`) |
| `equip_workspaces_directory_id` | The WorkSpaces directory ID |
| `equip_workspaces_security_group_id` | The security group ID attached to WorkSpaces |

All outputs return `null` when `deploy_workspaces` is `false`.

---

## Module: `modules/workspaces/`

A single-purpose local module containing all AWS resources needed for the WorkSpaces deployment. Called once from the root.

### Resources Created (in `main.tf`)

#### 1. WorkSpaces Service IAM Role (`workspaces_DefaultRole`)

- **Resource:** `aws_iam_role.workspaces_default`
- **What it does:** The IAM role that the WorkSpaces service itself assumes to manage resources on your behalf. Without this role, WorkSpaces cannot provision or manage desktops.
- **Policies attached:**
  - `AmazonWorkSpacesServiceAccess` — allows WorkSpaces to manage EC2 instances, ENIs, and volumes
  - `AmazonWorkSpacesSelfServiceAccess` — allows users to restart/rebuild their own workspace
  - `workspaces-directory-service-access` (inline policy) — grants `ds:AuthorizeApplication`, `ds:UnauthorizeApplication`, `ds:DescribeDirectories`, `ds:CheckAlias`, `ds:CreateAlias`, `ds:DescribeTrusts`, `ds:ListAuthorizedApplications`. Required for the WorkSpaces service to register and authorize itself against the AD Connector directory.
- **Conditional:** controlled by `var.create_service_role` (default `true`). Set to `false` if the role already exists in the account (e.g. if someone has previously used WorkSpaces via the console).

#### 2. AD Connector (`aws_directory_service_directory`)

- **Resource:** `aws_directory_service_directory.ad_connector`
- **Type:** `ADConnector` — a lightweight directory proxy, not a full directory replica
- **What it does:** Connects AWS WorkSpaces to the existing `equip.local` Active Directory. It forwards authentication requests (LDAP/Kerberos) to the on-premises domain controllers. It does not store or replicate any directory data.
- **Key settings:**
  - `customer_dns_ips` — the domain controller IPs (from `dns_ips` in the JSON)
  - `customer_username` — the `svc_workspaces` service account
  - `password` — from Secrets Manager (ignored on subsequent applies via `lifecycle.ignore_changes`)
  - `subnet_ids` — two private subnets in different AZs (eu-west-2a and eu-west-2b)
  - `vpc_id` — the shared HMPPS VPC

#### 3. Security Group (`aws_security_group.workspaces`)

- **Resource:** `aws_security_group.workspaces`
- **What it does:** Network-level access control applied to WorkSpaces instances. Controls what traffic can flow in and out of the desktops.
- **Current rules:**
  - **Egress:** all outbound traffic allowed (required for WorkSpaces to reach domain controllers, the WorkSpaces streaming service, Windows Update, and the EQuiP application backend)
  - **Inbound:** none defined (as per the LLD — WorkSpaces service manages inbound connectivity for streaming)
- The security group name can be overridden via `security_group_name` in `application_variables.json` to match existing click-ops resources.

#### 4. IP Access Control Group (`aws_workspaces_ip_group`)

- **Resource:** `aws_workspaces_ip_group.this`
- **What it does:** Restricts which client IP addresses can connect to WorkSpaces. Only devices on the allowed networks (e.g. MoJ corporate network via Prisma Access) can establish a session.
- **Configuration:** the `ip_group_allowed_cidrs` array in `application_variables.json`. Each entry is a CIDR and description. Currently set to `128.77.75.64/26` (MoJ corporate network).
- Uses `dynamic` blocks so CIDRs are purely data-driven from the JSON.

#### 5. WorkSpaces Directory Registration (`aws_workspaces_directory`)

- **Resource:** `aws_workspaces_directory.this`
- **What it does:** Registers the AD Connector with the WorkSpaces service, making it available for provisioning desktops. This is the bridge between the directory service and WorkSpaces.
- **Self-service permissions:** users can rebuild and restart their own workspace, but cannot change compute type, increase volume size, or switch running mode.
- **Access properties:** only Windows client and web access are allowed. Android, ChromeOS, iOS, Linux, macOS, and zero clients are denied.
- **Creation properties:**
  - Internet access disabled
  - Maintenance mode enabled (AWS auto-patches monthly)
  - Local administrator disabled
  - Default OU set to the EQuiP OU in `equip.local`
  - Custom security group attached
- **IP group:** the IP access control group is attached here, enforcing client IP restrictions.
- **Depends on:** the WorkSpaces service IAM role policy attachments (ensures the role is ready before directory registration).

#### 6. Individual WorkSpaces (`aws_workspaces_workspace`)

- **Resource:** `aws_workspaces_workspace.this`
- **What it does:** Provisions one persistent personal desktop per user. Each workspace is a dedicated Windows Server 2022 virtual machine running the EQuiP application.
- **Conditional:** only created when `bundle_id` is not empty AND `workspace_users` has entries. This allows the infrastructure (AD Connector, directory, SG, IP group) to be deployed first, with workspaces added later once the golden image and custom bundle are ready.
- **`for_each`:** iterates over the `workspace_users` map. The key is a human-readable identifier (e.g. `smith-j`), the value is the AD username (e.g. `john.smith`).
- **Properties:**
  - `running_mode` — `AUTO_STOP` by default (stops after 1 hour of inactivity to save costs)
  - `bundle_id` — references the custom bundle built from the golden image

### Module Inputs (`variables.tf`)

| Variable | Type | Description |
|---|---|---|
| `application_name` | `string` | Used for resource naming (e.g. `eucs-appstream`) |
| `environment` | `string` | Current environment (e.g. `development`, `production`) |
| `vpc_id` | `string` | The shared HMPPS VPC ID |
| `subnet_ids` | `list(string)` | Two private subnets in different AZs |
| `domain_name` | `string` | AD domain name (`equip.local`) |
| `ad_connector_size` | `string` | `"Small"` or `"Large"` |
| `ad_connector_username` | `string` | Service account for AD Connector |
| `ad_connector_password` | `string` (sensitive) | Service account password from Secrets Manager |
| `dns_ips` | `list(string)` | Domain controller IP addresses |
| `default_ou` | `string` | OU for WorkSpaces computer objects |
| `bundle_id` | `string` | Custom bundle ID (empty = skip workspace provisioning) |
| `running_mode` | `string` | `AUTO_STOP` or `ALWAYS_ON` |
| `auto_stop_timeout` | `number` | Inactivity timeout in minutes |
| `ip_group_allowed_cidrs` | `list(object)` | Allowed client IP ranges |
| `workspace_users` | `map(string)` | User key → AD username mapping |
| `security_group_name` | `string` | Override SG name (for importing existing resources) |
| `ip_group_name` | `string` | Override IP group name |
| `ip_group_description` | `string` | Override IP group description |
| `tags` | `map(string)` | Resource tags (passed from platform) |
| `create_service_role` | `bool` | Whether to create the `workspaces_DefaultRole` IAM role |

### Module Outputs (`outputs.tf`)

| Output | Description |
|---|---|
| `directory_id` | The AD Connector directory ID |
| `equip_workspaces_directory_id` | The WorkSpaces directory registration ID |
| `registration_code` | The WorkSpaces registration code — used in the Entra app relay state URL and by the WorkSpaces client |
| `security_group_id` | The WorkSpaces security group ID |
| `ip_group_id` | The IP access control group ID |

---

## Deployment Workflow

### Phase 1: Infrastructure

1. The Secrets Manager secret is created automatically by the CI/CD pipeline. After the first deploy, edit the secret value in the console with the real `svc_workspaces` password
2. Add the Prisma Access egress CIDRs to `ip_group_allowed_cidrs` in `application_variables.json`
3. Merge and deploy — this creates the AD Connector, WorkSpaces directory, security group, and IP access control group
4. Note the `registration_code` output — this is needed for the Entra app relay state URL

### Phase 2: Golden Image & Bundle

1. Provision a temporary WorkSpace from a standard AWS bundle via the console
2. Install the EQuiP Authors Client, remove Firefox/Edge, set registry keys, configure shortcuts
3. Create an image from the WorkSpace (Console → WorkSpaces → Actions → Create Image)
4. Create a custom bundle from that image (Console → WorkSpaces → Bundles → Create Bundle) with: Power compute (4 vCPU / 16 GB RAM), 175 GB root volume, 100 GB user volume
5. Copy the bundle ID and set it as `bundle_id` in `application_variables.json`

### Phase 3: User Provisioning

Add users to `workspace_users` in `application_variables.json`:

```json
"workspace_users": {
  "smith-j": "john.smith",
  "doe-j": "jane.doe"
}
```

Merge and deploy. Each user gets a persistent personal desktop.

### Decommissioning a WorkSpace

Remove the user's entry from `workspace_users` and deploy. Terraform will destroy that workspace.

---

## What Is NOT Managed Here

| Component | Managed By |
|---|---|
| VPC, subnets, routing | Modernisation Platform (core-vpc) |
| SAML identity provider in AWS | Pre-provisioned (IAM) |
| IAM role for SAML federation | Pre-provisioned (IAM) |
| Entra enterprise application | Azure / Entra ID team |
| Entra security group | Azure / Entra ID team |
| equip.local Active Directory | On-premises AD team |
| Golden image / custom bundle | Manual process via AWS console |

---

## Service Runbook

### **Last review date:**

2026-08-12

### **Description:**

Amazon WorkSpaces Personal desktops delivering the EQuiP Authoring application to MoJ users, authenticated against the equip.local domain via AD Connector.

### **Service URLs:**

WorkSpaces Web Access: `https://clients.amazonworkspaces.com`

### **Incident response hours:**

Office hours (9am–5pm, working days)

### **Incident contact details:**

EUCS Cloud Platforms team via `#eucs-cloud-platforms` Slack channel

### **Service team contact:**

EUCS Cloud Platforms team via `#eucs-cloud-platforms` Slack channel

### **Hosting environment:**

Modernisation Platform (AWS, eu-west-2)

### **Restrictions on access:**

- WorkSpaces access is IP-restricted to the MoJ corporate network (Prisma Access) via IP Access Control Groups
- Desktop authentication requires valid `equip.local` domain credentials
- Users must be assigned to the `MoJO-G-Users-AWS-EQuiP` Entra security group

### **Impact of an outage:**

EQuiP authors cannot access the EQuiP Authoring application. No alternative access method exists.

### **Services consumed by this:**

- equip.local Active Directory (authentication)
- Microsoft Entra ID (launch portal)
- MoJ corporate network / Prisma Access (connectivity)

### **How to resolve specific issues:**

| Issue | Check |
|---|---|
| User cannot see the Entra app | Verify user is in the `MoJO-G-Users-AWS-EQuiP` Entra group |
| User cannot log in to desktop | Verify equip.local credentials; check AD Connector health in AWS console |
| WorkSpace stuck launching | Check AD Connector connectivity, subnet routing, and domain controller availability |
| Cannot connect from device | Verify client IP is in the IP access control group allowed CIDRs |
| Slow login / poor performance | Check latency to domain controllers; review compute type sizing |
