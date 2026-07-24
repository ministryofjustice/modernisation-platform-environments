# oas — Architecture Diagrams

## Contents

1. [General Infrastructure](01-general-infrastructure.md) — network topology and the
   resources in each tier, drawn with the official AWS Architecture Icons and AWS's
   standard account/VPC/subnet nesting convention (e.g. for pasting into a slide deck
   or an AWS-style design doc).
2. [Data Flow](02-data-flow.md) — end-user/admin/database access patterns, and the
   password-rotation + security-alerting automation, drawn as Mermaid flowcharts/sequence
   diagrams (rendered natively by GitHub/GitLab in the web UI).

The general infrastructure diagram is a static PNG generated with the
[`diagrams`](https://diagrams.mingrammer.com/) Python library (Graphviz + official-style
AWS service icons). Regenerate with `python3 generate.py` (requires
`brew install graphviz && pip install diagrams`) if the infrastructure changes. The data
flow diagrams are plain Mermaid in the markdown — edit them directly.

---
Derived from Terraform in `terraform/environments/oas`, development environment, as of
2026-07-24. Diagrams reflect declared infrastructure, not a live account read.
