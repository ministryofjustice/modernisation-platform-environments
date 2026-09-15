# 2. Data Flow

How a user account and WorkSpace actually get created (and torn down), and how
outbound traffic from WorkSpaces is filtered before it reaches the internet.

## Provisioning & deprovisioning

```mermaid
flowchart LR
    OPS["Ops engineer"] -->|"1 . edits"| SECLIST[("Secrets Manager<br/>user_list")]
    SECLIST -->|"2 . version change"| LIFECYCLE["Lambda<br/>user-lifecycle"]
    LIFECYCLE -->|"3a . new user"| CREATE["Lambda<br/>user-creation"]
    CREATE -->|"4 . SSM Send-Command"| EC2W["Windows EC2<br/>domain-joined"]
    EC2W -->|"5 . New-ADUser (RSAT)"| AD[("Microsoft AD")]
    CREATE -->|"6 . CreateWorkspaces"| WS["WorkSpace"]
    CREATE -->|"7 . welcome email"| SES["SES"]
    SES -->|"8 . enrollment link"| USER["New user"]

    LIFECYCLE -->|"3b . user removed"| TERM["TerminateWorkspaces +<br/>ds-data DeleteUser +<br/>SSM param cleanup"]
    TERM --> WS
    TERM --> AD
```

## Outbound web filtering

```mermaid
flowchart LR
    WSNODE["WorkSpace / ECS task"] -->|"0.0.0.0/0"| FW["Network Firewall<br/>stateful allow-list"]
    FW -->|"allowed: .microsoft.com<br/>.windowsupdate.com, .office.com …"| NAT["NAT Gateway"]
    FW -->|"denied: everything else"| DROP(["dropped"])
    NAT --> IGW["Internet Gateway"] --> NET(("Internet"))
```

## Key facts

| | |
|---|---|
| **Trigger** | EventBridge fires on a new version of the `user_list` secret |
| **Why an EC2 hop** | AD user creation runs as a PowerShell/RSAT script over SSM on a domain-joined Windows box — the Directory Service Data API alone can't set passwords |
| **Guardrail** | `ALLOW_MASS_DELETE=false` on user-lifecycle to prevent a bad secret edit from bulk-deleting users |
| **Egress allow-list covers** | AWS service endpoints, Windows Update/Defender, Microsoft 365 / Azure AD domains only |

[← General Infrastructure](01-general-infrastructure.md) · [Back to index](README.md) · [Next: Authentication →](03-authentication.md)
