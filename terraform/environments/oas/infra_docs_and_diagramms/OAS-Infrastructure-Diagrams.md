# OAS Infrastructure Diagrams - Index

**Version:** 1.0  
**Last Updated:** 23 April 2026  
**Related Documentation:** [OAS-Infrastructure-Documentation.md](OAS-Infrastructure-Documentation.md)

---

## Overview

This index provides access to all infrastructure diagrams for the Oracle Application Server (OAS) environment on AWS Modernisation Platform. Each diagram is maintained in a separate file for better organization and version control.

All diagrams are rendered using Mermaid syntax and can be viewed directly in GitHub, GitLab, VS Code (with Mermaid extension), or exported using [Mermaid Live Editor](https://mermaid.live).

---

## Available Diagrams

### 1. High-Level Architecture Diagram
**📄 [OAS-Diagram-High-Level-Architecture.md](OAS-Diagram-High-Level-Architecture.md)**

**Description:** Complete OAS infrastructure architecture showing all AWS services, network layers, and user access patterns.

**Key Content:**
- EC2 compute instances
- RDS database configuration
- Application Load Balancer setup
- Security groups and network topology
- Supporting AWS services (S3, SSM, Secrets Manager, Route53, ACM)
- User and administrator access patterns

**Best For:**
- Architecture reviews
- New team member onboarding
- Infrastructure presentations
- Compliance documentation

---

### 2. Component Flow Diagram
**📄 [OAS-Diagram-Component-Flow.md](OAS-Diagram-Component-Flow.md)**

**Description:** Data flow between different layers of the OAS application stack, illustrating how traffic moves through the infrastructure.

**Key Content:**
- User traffic flow (Web → ALB → Application → Database)
- Administrative access patterns
- Port mappings and protocols
- Storage mount points
- Direct database access from workspaces

**Best For:**
- Troubleshooting connectivity issues
- Performance analysis
- Security audits
- Network design reviews

---

## How to Use Diagrams

Each diagram file contains detailed instructions for viewing and exporting. Here's a quick reference:

### View in VS Code
1. Install extension: `Markdown Preview Mermaid Support`
2. Open any diagram file (e.g., OAS-Diagram-High-Level-Architecture.md)
3. Press `Cmd+Shift+V` (Mac) or `Ctrl+Shift+V` (Windows/Linux)
4. Diagram will render in the preview pane

### Export as Images
1. Open the diagram file and copy the Mermaid code block
2. Visit https://mermaid.live
3. Paste the code into the editor
4. Click "Export" → Choose PNG (presentations) or SVG (documents)
5. Download your high-resolution diagram

### View in GitHub/GitLab
- Navigate to any diagram file in your repository
- Mermaid syntax renders automatically
- No additional tools or extensions required

### Embed in Confluence
1. Install "Mermaid Diagrams for Confluence" plugin
2. Add a Mermaid macro to your page
3. Copy and paste the Mermaid code from the diagram file
4. Save the page to render the diagram

---

## Diagram Maintenance

### When to Update
- Infrastructure changes (new services, modified configurations)
- Network topology changes (new subnets, security groups)
- Access pattern changes (new users, authentication methods)
- Quarterly reviews (even if no changes)

### Update Process
1. **Identify the diagram(s)** that need updating based on infrastructure changes
2. **Open the specific diagram file** (e.g., OAS-Diagram-High-Level-Architecture.md)
3. **Edit the Mermaid code** to reflect the changes
4. **Test rendering** in VS Code or Mermaid Live Editor
5. **Update descriptions** in the diagram file if needed
6. **Update this index** if you add new diagrams or significantly change purpose
7. **Update main documentation** in [OAS-Infrastructure-Documentation.md](OAS-Infrastructure-Documentation.md)
8. **Commit with descriptive message** (e.g., "docs: add CloudWatch integration to architecture diagram")

### Adding New Diagrams
When creating a new diagram:
1. Create a new file: `OAS-Diagram-[Name].md`
2. Follow the structure of existing diagram files
3. Add entry to this index with description and "Best For" section
4. Update the file structure in Appendix C of main documentation
5. Link from relevant sections in main documentation

---

## Planned Future Diagrams

Consider creating these additional diagrams for comprehensive documentation:

### Security Architecture Diagram
- Security group rules and flows
- IAM roles and policies
- Network ACLs
- Encryption points (KMS, SSL/TLS)

### Deployment Pipeline Diagram
- Terraform workflow
- CI/CD process
- Approval gates
- Rollback procedures

### Disaster Recovery Diagram
- Backup locations and schedules
- Recovery procedures
- Failover paths
- RTO/RPO timelines

### Network Topology Diagram
- VPC structure
- Subnet layout across AZs
- Route tables
- VPC endpoints

---

**Document Owner:** OAS DevOps Team  
**Review Frequency:** Quarterly or when infrastructure changes  
**Next Review Date:** July 2026

---

**End of Diagrams Document**
