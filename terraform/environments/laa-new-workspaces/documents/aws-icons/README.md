# laa-new-workspaces — Architecture Diagrams (AWS icon set)

Same three diagrams as the [Mermaid docs](../README.md), redrawn with the official
AWS Architecture Icons and AWS's standard account/VPC/subnet nesting convention,
for anyone who prefers that format (e.g. pasting into a slide deck or an AWS-style
design doc).

## Contents

1. [General Infrastructure](01-general-infrastructure.md)
2. [Data Flow](02-data-flow.md)
3. [Authentication](03-authentication.md)

Diagrams are static PNGs generated with the [`diagrams`](https://diagrams.mingrammer.com/)
Python library (Graphviz + official-style AWS service icons). Regenerate with
`python3 generate.py` (requires `brew install graphviz && pip install diagrams`)
if the infrastructure changes.

---
Derived from Terraform in `terraform/environments/laa-new-workspaces`, development
environment, as of 2026-07-22. Diagrams reflect declared infrastructure, not a live
account read.
