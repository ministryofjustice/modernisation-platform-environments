# edw-19c — Architecture Diagrams (AWS icon set)

Standalone Oracle RDS 19c instance for the Enterprise Data Warehouse (EDW), hosted on
the AWS Modernisation Platform. Unlike `oas`, there is no compute/ALB tier — this is a
database-only workload accessed directly by Landing Zone Workspaces, with data movement
via S3 (Data Pump import/export and cross-account replication from the source EDW
upgrade account).

- Region: `eu-west-2`
- Account type: member (Modernisation Platform)
- Environments: `preproduction` only (development/production are placeholders in
  `application_variables.json` with no resources defined)
- Engine: Oracle Enterprise Edition 19c, `db.m6i.2xlarge`, restored from a snapshot
  taken in a separate migration account

## Contents

1. [General Infrastructure](01-general-infrastructure.md) — the RDS instance, its
   security group, S3 replication target, and supporting IAM/Secrets/KMS/logging, drawn
   with the official AWS Architecture Icons.
2. [Data Flow](02-data-flow.md) — Workspaces database access, Data Pump import via S3,
   cross-account S3 replication, and the one-time snapshot restore, drawn as a Mermaid
   flowchart (rendered natively by GitHub/GitLab in the web UI).

The general infrastructure diagram is a static PNG generated with the
[`diagrams`](https://diagrams.mingrammer.com/) Python library (Graphviz + official-style
AWS service icons). Regenerate with `python3 generate.py` (requires
`brew install graphviz && pip install diagrams`) if the infrastructure changes. The data
flow diagram is plain Mermaid in the markdown — edit it directly.

---
Derived from Terraform in `terraform/environments/edw-19c`, preproduction environment,
as of 2026-07-24. Diagrams reflect declared infrastructure, not a live account read.
