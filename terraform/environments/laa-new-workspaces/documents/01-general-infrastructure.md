# 1. General Infrastructure

Network topology and the resources sitting in each tier — VPC subnets, the AD
directory, the WorkSpaces fleet, the LinOTP/FreeRADIUS MFA stack, and the
Lambda/EC2 automation that provisions users.

```mermaid
flowchart TB
    CLIENT(["WorkSpaces Client<br/>Windows / macOS / Web"])
    VPN["Global Protect VPN Gateway<br/>4 allow-listed IPs"]

    subgraph ACCOUNT["laa-new-workspaces account"]
      direction TB

      subgraph VPC["VPC 10.26.130.0/23"]
        direction TB

        subgraph PUB["Public subnets · 2 AZs"]
          ALB["ALB radmfa<br/>HTTPS:443, ACM cert"]
        end

        subgraph PRIV["Private subnets · 2 AZs"]
          AD[("AWS Managed AD<br/>laa-workspaces.local")]
          WSDIR["WorkSpaces Directory<br/>+ Workspaces"]
          NLB["Internal NLB<br/>UDP:1812"]
          ECS["ECS Fargate task<br/>linotp:5000 + freeradius:1812/1813"]
          RDS[("RDS MySQL 8.0<br/>linotp3, db.t3.micro")]
          EC2W["Windows EC2<br/>domain-joined, RSAT-AD"]
          VPCE["VPC Endpoints<br/>SSM / Secrets Manager / S3"]
        end

        subgraph NATSUB["NAT subnet"]
          NATGW["NAT Gateway"]
        end

        subgraph FWSUB["Firewall subnets"]
          FW["Network Firewall<br/>FQDN allow-list"]
        end

        IGW["Internet Gateway"]
      end

      TGWATT["Transit Gateway<br/>attachment"]
      LAMBDA1["Lambda<br/>user-lifecycle"]
      LAMBDA2["Lambda<br/>user-creation"]
      SM[("Secrets Manager")]
      KMS["KMS key · ebs"]
      SES["SES"]
      ECR["ECR<br/>linotp3 / freeradius images"]
    end

    MOJ["MoJ shared Transit Gateway<br/>LAA network 10.0.0.0/8"]
    INTERNET(("Internet"))

    CLIENT --> VPN --> WSDIR
    VPN -. HTTPS 443 .-> ALB
    ALB --> ECS
    WSDIR <--> AD
    AD <--> NLB --> ECS
    ECS --> RDS
    ECS -. secrets .-> SM
    ECR -. image pull .-> ECS

    LAMBDA1 -- reads --> SM
    LAMBDA1 --> LAMBDA2
    LAMBDA2 -- SSM Send-Command --> EC2W
    EC2W -- LDAP / PowerShell --> AD
    LAMBDA2 --> WSDIR
    LAMBDA2 --> SES
    LAMBDA2 -. decrypt .-> KMS

    PRIV --> FW --> NATGW --> IGW --> INTERNET
    VPC --> TGWATT --> MOJ
```

## Key facts

| | |
|---|---|
| **VPC CIDR** | `10.26.130.0/23` (dev) · `10.27.130.0/23` (prod) |
| **WorkSpaces access** | IP group restricted to 4 Global Protect gateway IPs; only Windows, macOS and Web clients allowed |
| **MFA compute** | ECS Fargate, 1024 CPU / 2048 MB — `linotp` :5000 + `freeradius` :1812/1813 UDP |
| **RDS** | MySQL 8.0, db.t3.micro, private-only, SG allows port 3306 from the ECS task SG only |
| **Egress** | private subnets → Network Firewall (FQDN allow-list) → NAT Gateway → IGW |
| **Transit Gateway** | `tgw-053d9dd7f1222a554` — dev routes `10.0.0.0/8` to the wider LAA network |

[← Back to index](README.md) · [Next: Data Flow →](02-data-flow.md)
