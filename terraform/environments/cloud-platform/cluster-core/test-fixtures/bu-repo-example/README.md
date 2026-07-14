# BU Repo Example Structure (ADR-015)

This directory contains a reference implementation of the per-BU workload repo
structure defined in ADR-015. When the real BU repos are created (e.g.,
`container-platform-octo`), they should follow this layout.

## Structure

```
container-platform-<bu>/
├── _bu-config.yaml                 # BU metadata
├── hello-world/                    # One directory per application
│   ├── app.yaml                    # App metadata
│   ├── namespaces.yaml             # Namespace declarations
│   └── deployment/
│       ├── nonlive/                # ArgoCD syncs from here (auto-sync)
│       │   ├── deployment.yaml
│       │   └── service.yaml
│       └── live/                   # ArgoCD syncs from here (manual sync)
│           ├── deployment.yaml
│           └── service.yaml
└── CODEOWNERS
```

## How ArgoCD Picks This Up

1. The ApplicationSet uses a git-directory-generator with path `*/deployment/nonlive`
2. When a new app directory appears (e.g., `hello-world/deployment/nonlive/`),
   ArgoCD automatically creates an Application named `<bu>-hello-world-nonlive`
3. The Application syncs the manifests from that directory to the spoke cluster
4. The namespace is auto-created via `CreateNamespace=true` sync option

## Validation Steps

1. Deploy hub cluster with ArgoCD enabled
2. Deploy spoke cluster (auto-registers via Access Entry)
3. Create the BU repo with this structure
4. Verify ArgoCD creates an Application from the ApplicationSet
5. Verify the deployment appears on the spoke cluster
