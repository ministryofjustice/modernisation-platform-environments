# 0. Combined Data Flow — oas + edw-19c

How traffic and credentials move through both apps: end-user/admin/database access,
edw-19c's S3 Data Pump and cross-account replication, and the two OAS-only automation
paths. edw-19c has no compute tier and no automation of its own, so it only appears in
the access-patterns flowchart below.

## Access patterns

```mermaid
flowchart LR
    USER["End user<br/>(browser)"] -->|"1 . HTTPS 443"| ALB["ALB oas-lb<br/>(internal)"]
    ALB -->|"2 . HTTP/HTTPS 9500-9503<br/>/console /em /analytics /dv"| EC2["oas EC2<br/>WebLogic + Analytics"]
    EC2 -->|"3 . Oracle TNS 1521"| RDSOAS[("oas RDS Oracle 19c<br/>db.t3.medium")]

    ADMIN["Administrator"] -->|"4a . SSH 22"| BASTION["Bastion host"]
    BASTION -->|"5a . SSH 22"| EC2
    ADMIN -->|"4b . Start-Session"| SSM["SSM Session<br/>Manager"]
    SSM -.->|"5b . secure session"| EC2

    WS["LZ Workspaces"] -.->|"6 . SQL Developer 1521<br/>(direct, bypasses app tier)"| RDSOAS
    WS -.->|"7 . SQL Developer 1521<br/>(troubleshooting only)"| RDSEDW[("edw-19c RDS Oracle 19c<br/>db.m6i.2xlarge")]

    RDSEDW -->|"8 . assume role"| IAM["IAM Role<br/>rds-s3-access-role"]
    IAM -->|"9 . GetObject/ListBucket<br/>(Data Pump import/export)"| S3EDW[("S3<br/>edw-19c-preprod-replica-bucket")]
    REPL["Remote account 258180561819<br/>edw-upgrade replication role"] -.->|"10 . ReplicateObject/Delete/Tags<br/>(cross-account, versioned)"| S3EDW

    ALB -.->|"11 . access logs"| S3LOGS[("S3<br/>ALB access logs")]

    EC2 -.->|"planned, not active:<br/>Oracle 1521<br/>(SG rules commented out<br/>in Terraform on both sides)"| RDSEDW
```

## Automation: RDS master password rotation (oas only)

Manually invoked (`oas/new_lambda_rotate_db_password.tf`) — not wired to Secrets
Manager's automatic rotation schedule, so there's no EventBridge rule or fixed cadence.
edw-19c has no equivalent — its master password is generated once at creation and never
rotated by automation.

```mermaid
sequenceDiagram
    participant OP as Operator
    participant LAM as Lambda (rotate-db-master-password)
    participant SM as Secrets Manager
    participant RDS as oas RDS Oracle 19c

    OP->>LAM: invoke (console "Test" / aws lambda invoke)
    LAM->>SM: GetRandomPassword
    SM-->>LAM: new password
    LAM->>RDS: ModifyDBInstance (new password)
    RDS-->>LAM: applied
    LAM->>SM: PutSecretValue (persist new password)
```

## Automation: CloudWatch → Slack security alerting (oas only)

edw-19c has no CloudWatch alarms or SNS topic wired up — this alerting path is oas-only.

```mermaid
sequenceDiagram
    participant CW as CloudWatch Alarm
    participant SNS as SNS (oas-security-alerts)
    participant LAM as Lambda (security-alerts-to-slack)
    participant SM as Secrets Manager (slack webhook)
    participant SLACK as Slack channel

    CW->>SNS: alarm state change
    SNS->>LAM: invoke
    LAM->>SM: GetSecretValue (webhook URL)
    SM-->>LAM: webhook URL
    LAM->>SLACK: POST message
```

## Key facts

| | |
|---|---|
| **oas↔edw-19c direct link** | Declared in Terraform on both sides but commented out — not active traffic today, shown as the dashed red edge above |
| **Only shared consumer** | LZ Workspaces, which connects independently to each RDS instance over SQL Developer 1521 |
| **edw-19c automation** | None — no Lambdas, no CloudWatch alarms, no SNS topic; it's a passive RDS-only workload |
| **Direct DB access** | LZ Workspaces reach both RDS instances without going through any app tier |
| **Admin access (oas)** | Bastion (SSH) or SSM Session Manager only — edw-19c has no compute to administer |
| **Password rotation** | oas: manual Lambda invoke only. edw-19c: generated once, never rotated |

[← Back to index](README.md) · [See also: Combined General Infrastructure →](00-combined-general-infrastructure.md)
