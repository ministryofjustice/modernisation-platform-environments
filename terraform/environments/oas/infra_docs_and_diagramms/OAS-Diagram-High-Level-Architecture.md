# OAS High-Level Architecture Diagram

## Overview

This diagram shows the complete OAS infrastructure architecture including all AWS services, network layers, and user access patterns across the AWS Modernisation Platform.

---

## High-Level Architecture Diagram

```mermaid
---
config:
  layout: dagre
---
flowchart RL
 subgraph subGraph0["End Users"]
        Users["End Users"]
  end
 subgraph Administrators["Administrators"]
        Admins["Administrators"]
  end
 subgraph subGraph2["LZ Workspaces"]
        Workspaces["Developer Workstations"]
  end
 subgraph subGraph3["Public Subnet"]
        Bastion["Bastion Host"]
  end
 subgraph subGraph4["Private Subnet A"]
        ALB["Application Load Balancer<br>Internal"]
        EC2["EC2 Instance<br>r5a.large<br>Oracle Linux 8.10"]
        EBS1["EBS Volume 300GB<br>/oracle/software"]
        EBS2["EBS Volume 300GB<br>/stage"]
  end
 subgraph subGraph5["Data Subnet A/B/C"]
        RDS[("RDS Oracle 19c<br>db.t3.medium")]
  end
 subgraph subGraph6["Supporting Services"]
        SSM["AWS Systems Manager"]
        S3["S3 Buckets<br>ALB Logs, Software"]
        Secrets["Secrets Manager<br>SSH Keys, DB Passwords"]
        R53["Route53<br>DNS Management"]
        ACM["ACM Certificates<br>SSL/TLS"]
  end
 subgraph subGraph7["AWS Modernisation Platform - EU-West-2"]
        subGraph3
        subGraph4
        subGraph5
        subGraph6
  end
    Users -- HTTPS 443 --> ALB
    Workspaces -- SQL Developer 1521 --> RDS
    Admins -- SSH --> Bastion
    Admins -- SSM Session --> SSM
    Bastion -- SSH 22 --> EC2
    SSM -- Secure Session --> EC2
    ALB -- HTTP 9500/9502 --> EC2
    EC2 -- Oracle 1521 --> RDS
    EC2 -- Reads --> EBS1 & EBS2
    ALB -- Access Logs --> S3
    EC2 -- Software --> S3
    R53 -- DNS --> ALB
    ACM -- TLS Cert --> ALB
    EC2 -- Auth --> Secrets

    style ALB fill:#8c4fff
    style EC2 fill:#ff9900
    style RDS fill:#3b48cc
    style SSM fill:#dd344c
    style S3 fill:#569a31
    linkStyle 0 stroke:#FF6D00,fill:none
    linkStyle 2 stroke:#00C853,fill:none
    linkStyle 3 stroke:#00C853

---

## Key Components

### Compute
- **EC2 Instance** (Orange): r5a.large running Oracle Linux 8.10
- **Instance Type:** Memory-optimized for Oracle workloads
- **Location:** Private Subnet A in EU-West-2a

### Database
- **RDS Database** (Blue): Oracle 19c Enterprise Edition
- **Instance Class:** db.t3.medium
- **Location:** Data Subnets spanning multiple availability zones

### Load Balancing
- **Application Load Balancer** (Purple): Internal ALB handling HTTPS/HTTP traffic
- **Ports:** 80 (redirect), 443 (HTTPS), 9500 (Console/EM), 9502 (Analytics)
- **Scheme:** Internal (not internet-facing)

### Storage
- **S3 Buckets** (Green): 
  - ALB access logs (encrypted, lifecycle policies)
  - Software packages and installation media
- **EBS Volumes:** 2x 300GB gp3 encrypted volumes

### Security & Access
- **Systems Manager** (Red): SSM Session Manager for secure, audited access
- **Secrets Manager:** SSH keys, RDS master password
- **Bastion Host:** Traditional SSH gateway in public subnet

### Supporting Services
- **Route53:** DNS management for application and database endpoints
- **ACM:** SSL/TLS certificate management with automatic renewal

---

## Access Patterns

### End Users
- Connect via HTTPS (port 443) to Application Load Balancer
- ALB forwards to EC2 on HTTP ports 9500 or 9502
- Traffic flows through private subnets only

### Administrators
- **SSM Session Manager:** Secure, passwordless access (recommended)
- **SSH via Bastion:** Traditional SSH through jump host
- Both methods provide terminal access to EC2 instance

### Database Access
- **Application:** EC2 connects to RDS on port 1521
- **Developers:** Direct connection from LZ Workspaces using SQL Developer
- **Credentials:** Retrieved from AWS Secrets Manager

---

## Network Topology

### Subnet Layout
- **Public Subnet:** Bastion host for SSH access
- **Private Subnet A:** EC2 instance, ALB endpoints (AZ: eu-west-2a)
- **Private Subnet B/C:** Additional ALB endpoints for high availability
- **Data Subnets A/B/C:** RDS instance across multiple AZs

### Security Layers
- **Security Groups:** Granular ingress/egress rules per component
- **Encryption:** All data encrypted at rest (KMS) and in transit (SSL/TLS)
- **Network Isolation:** Private subnets with no direct internet access

---

## How to Use This Diagram

### View in VS Code
1. Install extension: `Markdown Preview Mermaid Support`
2. Open this file in VS Code
3. Press `Cmd+Shift+V` (Mac) or `Ctrl+Shift+V` (Windows/Linux)
4. Diagram will render in preview pane

### Export as Image
1. Visit https://mermaid.live
2. Copy the entire Mermaid code block above
3. Paste into the Mermaid Live Editor
4. Click "Export" button
5. Choose PNG (for presentations) or SVG (for documents)
6. Download your high-resolution diagram

### View in GitHub/GitLab
- Simply navigate to this file in your repository
- Mermaid syntax renders automatically
- No additional tools required

### Embed in Confluence
1. Install "Mermaid Diagrams for Confluence" plugin (if not already installed)
2. Add a Mermaid macro to your Confluence page
3. Paste the Mermaid code into the macro
4. Save the page to render the diagram

### Print or Present
1. Export as PNG at high resolution (see above)
2. Insert into PowerPoint, Word, or other presentation tools
3. Recommended: SVG format for scalable, crisp printing

---

## Diagram Updates

When infrastructure changes occur:

1. **Identify Changes:** Determine which components are added, modified, or removed
2. **Update Mermaid Code:** Edit the diagram code in this file
3. **Test Rendering:** Preview in VS Code or Mermaid Live to ensure correct display
4. **Update Documentation:** Sync changes with [OAS-Infrastructure-Documentation.md](OAS-Infrastructure-Documentation.md)
5. **Update Index:** Update [OAS-Infrastructure-Diagrams.md](OAS-Infrastructure-Diagrams.md) if needed
6. **Commit Changes:** Use descriptive commit message (e.g., "docs: add new CloudWatch integration to architecture diagram")

---
