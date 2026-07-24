# 2. Data Flow

How traffic and credentials move through the estate: end-user/admin/database access
patterns, and the two automation paths (manual DB password rotation, CloudWatch → Slack
security alerting).

## Access patterns

```mermaid
flowchart LR
    USER["End user<br/>(browser)"] -->|"1 . HTTPS 443"| ALB["ALB oas-lb<br/>(internal)"]
    ALB -->|"2 . HTTP/HTTPS 9500-9503<br/>/console /em /analytics /dv"| EC2["EC2<br/>WebLogic + Analytics"]
    EC2 -->|"3 . Oracle TNS 1521"| RDS[("RDS Oracle 19c<br/>db.t3.medium")]

    ADMIN["Administrator"] -->|"4a . SSH 22"| BASTION["Bastion host"]
    BASTION -->|"5a . SSH 22"| EC2
    ADMIN -->|"4b . Start-Session"| SSM["SSM Session<br/>Manager"]
    SSM -.->|"5b . secure session"| EC2

    WS["LZ Workspaces"] -.->|"6 . SQL Developer 1521<br/>(direct, bypasses app tier)"| RDS
    ALB -.->|"7 . access logs"| S3LOGS[("S3<br/>ALB access logs")]
```

## Automation: RDS master password rotation

Manually invoked (`new_lambda_rotate_db_password.tf`) — not wired to Secrets Manager's
automatic rotation schedule, so there's no EventBridge rule or fixed cadence.

```mermaid
sequenceDiagram
    participant OP as Operator
    participant LAM as Lambda (rotate-db-master-password)
    participant SM as Secrets Manager
    participant RDS as RDS Oracle 19c

    OP->>LAM: invoke (console "Test" / aws lambda invoke)
    LAM->>SM: GetRandomPassword
    SM-->>LAM: new password
    LAM->>RDS: ModifyDBInstance (new password)
    RDS-->>LAM: applied
    LAM->>SM: PutSecretValue (persist new password)
```

## Automation: CloudWatch → Slack security alerting

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
| **Console/EM ports** | 9500 (HTTP) / 9501 (HTTPS) |
| **Analytics/DV ports** | 9502 (HTTP) / 9503 (HTTPS) |
| **Direct DB access** | LZ Workspaces reach RDS on 1521 without going through the ALB or EC2 — allowed by a dedicated RDS security group rule for the management CIDR |
| **Admin access** | Bastion (SSH) or SSM Session Manager only — no other inbound to the EC2 security group |
| **Password rotation trigger** | Manual only — no schedule, no automatic Secrets Manager rotation |
| **Alerting path** | CloudWatch Alarm → SNS → Lambda → Slack webhook (URL stored in Secrets Manager) |

[← General Infrastructure](01-general-infrastructure.md) · [Back to index](README.md)
