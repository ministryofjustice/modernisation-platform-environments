# 2. Data Flow

Database access, Data Pump export/import via S3, cross-account S3 replication, and the
one-time snapshot restore that provisioned the instance.

```mermaid
flowchart LR
    WS["LZ Workspaces"] -->|"1 . SQL Developer 1521<br/>(troubleshooting only)"| RDS[("RDS Oracle 19c EE<br/>db.m6i.2xlarge")]
    RDS -->|"2 . assume role"| IAM["IAM Role<br/>rds-s3-access-role"]
    IAM -->|"3 . GetObject/ListBucket<br/>(Data Pump import/export)"| S3[("S3<br/>edw-19c-preprod-replica-bucket")]

    REPL["Remote account 258180561819<br/>edw-upgrade replication role"] -.->|"4 . ReplicateObject/Delete/Tags<br/>(cross-account, versioned)"| S3
    SNAP["Remote account 758955050340<br/>snapshot"] -.->|"5 . restore from snapshot<br/>(one-time provisioning)"| RDS
    RDS -.->|"6 . master password<br/>persists across applies"| SM[("Secrets Manager")]
```

## Key facts

| | |
|---|---|
| **No application tier** | Unlike `oas`, this is a database-only workload — step 1 is a direct, troubleshooting-only path, not a production integration |
| **Data Pump path** | RDS's `S3_INTEGRATION` option assumes `rds-s3-access-role` to read/write the replica bucket for export/import |
| **Cross-account replication** | One-directional: account `258180561819` (the `edw-upgrade` migration project) replicates objects **into** the bucket; edw-19c does not write to any bucket it doesn't own |
| **Provisioning** | The instance was created once from a snapshot in account `758955050340` — `terraform apply` ignores changes to `snapshot_identifier` afterwards, so this never re-runs |
| **Secrets** | Master password generated once, stored in Secrets Manager, `ignore_changes` prevents accidental regeneration |

[← General Infrastructure](01-general-infrastructure.md) · [Back to index](README.md)
