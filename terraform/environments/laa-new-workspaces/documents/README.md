# laa-new-workspaces — Architecture Diagrams

AWS WorkSpaces estate for LAA, built on an AWS Managed Microsoft AD directory with a
self-hosted LinOTP + FreeRADIUS stack for MFA.

- Region: `eu-west-2`
- Account type: member (Modernisation Platform)
- Environments: `development`, `production`
- Directory: `laa-workspaces.local` (MicrosoftAD, Standard edition)

## Contents

1. [General Infrastructure](01-general-infrastructure.md) — network topology and the
   resources in each tier.
2. [Data Flow](02-data-flow.md) — how a user account and WorkSpace get created and
   torn down, and how outbound traffic is filtered.
3. [Authentication](03-authentication.md) — WorkSpaces login with RADIUS-backed MFA,
   and self-service MFA enrollment.

Diagrams are Mermaid, rendered natively by GitHub/GitLab in the web UI.

---
Derived from Terraform in `terraform/environments/laa-new-workspaces` (root module +
`workspace-components` + `ad-radius-mfa-config`), development environment, as of
2026-07-22. Diagrams reflect declared infrastructure, not a live account read.
