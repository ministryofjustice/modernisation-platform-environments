# OAS (Oracle Application Server) Infrastructure Documentation

**Document Version:** 1.0  
**Last Updated:** 23 April 2026  
**Environment:** AWS Modernisation Platform  
**Regions:** EU-West-2 (London)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Infrastructure Components](#infrastructure-components)
4. [Network Architecture](#network-architecture)
5. [Security & Access Control](#security--access-control)
6. [Storage Architecture](#storage-architecture)
7. [High Availability & Load Balancing](#high-availability--load-balancing)
8. [DNS & Routing](#dns--routing)
9. [Monitoring & Logging](#monitoring--logging)
10. [Backup & Disaster Recovery](#backup--disaster-recovery)
11. [Deployment Process](#deployment-process)
12. [Operational Procedures](#operational-procedures)
13. [Troubleshooting Guide](#troubleshooting-guide)
14. [Appendices](#appendices)

---

## Executive Summary

The Oracle Application Server (OAS) infrastructure is hosted on the AWS Modernisation Platform, providing a scalable, secure environment for Oracle-based applications. The infrastructure consists of compute instances running Oracle Linux 8.10, RDS Oracle databases, application load balancers, and comprehensive security controls.

### Key Highlights

- **Operating System:** Oracle Linux 8.10 (upgraded from 7.9 using Leapp)
- **Compute:** EC2 r5a.large instances with dedicated EBS storage
- **Database:** RDS Oracle 19c Enterprise Edition
- **Load Balancer:** Application Load Balancer with SSL/TLS termination
- **Access Methods:** SSM Session Manager, SSH via Bastion
- **Environments:** Development, Pre-production
- **Region:** EU-West-2 (London), Availability Zone 2a

---

## Architecture Overview

**📊 Infrastructure Diagrams:**
- [Diagram Index](OAS-Infrastructure-Diagrams.md) | [High-Level Architecture](OAS-Diagram-High-Level-Architecture.md) | [Component Flow](OAS-Diagram-Component-Flow.md)

### High-Level Architecture

The OAS infrastructure consists of the following major components:

- **Compute Layer:** EC2 r5a.large instances running Oracle Linux 8.10
- **Database Layer:** RDS Oracle 19c Enterprise Edition (db.t3.medium)
- **Load Balancing:** Internal Application Load Balancer with SSL/TLS termination
- **Storage:** 2x 300GB EBS volumes (gp3, encrypted) for Oracle software and staging
- **Access:** Bastion host and AWS Systems Manager Session Manager
- **Supporting Services:** Route53 DNS, ACM certificates, S3 buckets, Secrets Manager

### Network Architecture

- **Region:** EU-West-2 (London)
- **Availability Zone:** 2a (primary)
- **VPC:** Shared Modernisation Platform VPC
- **Subnets:** Private subnets for application, data subnets for RDS, public subnet for bastion
- **Security:** Multi-layered security groups, encrypted storage, private networking

### Component Flow

**User Traffic:**
1. End users connect via HTTPS (443) to Application Load Balancer
2. ALB forwards to EC2 on HTTP ports 9500 (Console/EM) or 9502 (Analytics)
3. Application connects to RDS Oracle on port 1521

**Administrative Access:**
1. SSH via bastion host (port 22)
2. SSM Session Manager (secure, audited sessions)
3. Direct database access from LZ workspaces via SQL Developer (port 1521)

---

## Infrastructure Components

### Compute Resources

#### EC2 Instance Specifications

| **Attribute** | **Value** |
|---------------|-----------|
| **Instance Name** | `oas Apps Server` |
| **Instance Type** | r5a.large (2 vCPU, 16 GiB RAM) |
| **Operating System** | Oracle Linux Server 8.10 |
| **Kernel** | 5.4.17-2136.354.4.1.el8uek (UEK) |
| **Availability Zone** | eu-west-2a |
| **Monitoring** | Enabled (CloudWatch detailed monitoring) |
| **EBS Optimized** | Yes |
| **Private IP** | 10.26.56.148 (development) |
| **Root Volume** | 40 GB gp2, encrypted |
| **Python Version** | 3.6.8 (default) |
| **SELinux** | Enforcing |

#### SSH Key Management

- **Key Type:** ED25519 (Terraform-generated)
- **Storage:** AWS Secrets Manager (`oas-development/ec2-ssh-private-key`)
- **Key Name:** `oas-development-key`
- **Key Rotation:** Managed via Terraform (regenerates on redeploy if count changes)
- **Access:** Private key stored securely in Secrets Manager

### Database Resources

#### RDS Oracle Configuration

| **Attribute** | **Value** |
|---------------|-----------|
| **Engine** | Oracle Enterprise Edition 19c |
| **Version** | 19.0.0.0.ru-2021-10.rur-2021-10.r1 |
| **Instance Class** | db.t3.medium (2 vCPU, 4 GiB RAM) |
| **Allocated Storage** | 50 GB |
| **Storage Type** | General Purpose SSD (gp2) |
| **Multi-AZ** | Disabled (development) |
| **Availability Zone** | eu-west-2a |
| **Backup Retention** | 35 days |
| **Backup Window** | 22:00-01:00 UTC |
| **Maintenance Window** | Monday 01:15-06:00 UTC |
| **Character Set** | AL32UTF8 |
| **License Model** | Bring Your Own License (BYOL) |
| **Encryption** | Enabled (KMS) |
| **Deletion Protection** | False (development environment) |
| **Auto Minor Upgrades** | Disabled |
| **Allow Major Upgrades** | True |

#### RDS Parameter Group

- **Family:** oracle-ee-19
- **Parameters:**
  - `remote_dependencies_mode`: SIGNATURE
  - `sqlnetora.sqlnet.allowed_logon_version_server`: 10

#### Database Credentials

- **Master Username:** `sysdba`
- **Master Password:** Randomly generated (16 characters, alphanumeric)
- **Storage:** AWS Secrets Manager (`oas/app/db-master-password`)
- **Lifecycle:** Password persists across Terraform runs

#### DNS Record

- **CNAME:** `rds.oas.laa-development.modernisation-platform.service.justice.gov.uk`
- **Target:** RDS endpoint address
- **TTL:** 60 seconds

---

## Storage Architecture

### EBS Volumes

#### Volume 1: Oracle Software Home

| **Attribute** | **Value** |
|---------------|-----------|
| **Volume Name** | `oas-EC2ServerVolumeORAHOME` |
| **Size** | 300 GB |
| **Type** | gp3 (General Purpose SSD) |
| **Device Name** | /dev/sdb |
| **Mount Point** | `/oracle/software` |
| **Encryption** | Yes (KMS encrypted) |
| **Snapshot ID** | snap-0ce71d391351de5c5 (development) |
| **Usage** | Oracle binaries, application files |
| **Permissions** | 777, owned by oracle:dba |
| **Current Utilization** | ~196 GB / 295 GB (66%) |

#### Volume 2: Staging Volume

| **Attribute** | **Value** |
|---------------|-----------|
| **Volume Name** | `oas-EC2ServerVolumeSTAGE` |
| **Size** | 300 GB |
| **Type** | gp3 (General Purpose SSD) |
| **Device Name** | /dev/sdc |
| **Mount Point** | `/stage` |
| **Encryption** | Yes (KMS encrypted) |
| **Snapshot ID** | snap-05f2f12f265bdb020 (development) |
| **Usage** | Staging data, temporary files |
| **Permissions** | 777, owned by oracle:dba |
| **Current Utilization** | ~241 GB / 295 GB (86%) |

#### Volume Mounting Strategy

The userdata script dynamically identifies and mounts EBS volumes based on size:
- **Largest volume** → `/oracle/software`
- **Second largest** → `/stage`
- **Skip** volumes < 100GB (assumed to be system volumes)

Volumes are configured with `nofail` option in `/etc/fstab` to prevent boot failures.

### S3 Storage

#### ALB Access Logs Bucket

- **Bucket Name:** `oas-lb-access-logs-*` (prefixed)
- **Encryption:** aws:kms
- **Versioning:** Enabled
- **Public Access:** Blocked (all settings)
- **Lifecycle Policy:**
  - **90 days:** Transition to STANDARD_IA
  - **365 days:** Transition to GLACIER
  - **730 days:** Expiration
  - **Multipart uploads:** Abort after 7 days

#### Modernisation Platform Software Bucket

- **Bucket:** `modernisation-platform-software20230224000709766100000001`
- **Access:** Read/write via EC2 IAM role
- **Usage:** Software packages, installation media

---

## Network Architecture

### VPC Configuration

- **VPC:** Shared VPC (Modernisation Platform)
- **Region:** eu-west-2
- **CIDR Block:** 10.26.0.0/16 (inferred from private IPs)

### Subnet Layout

| **Subnet Type** | **Availability Zone** | **Usage** |
|-----------------|----------------------|-----------|
| Private Subnet A | eu-west-2a | EC2 instances, ALB |
| Private Subnet B | eu-west-2b | ALB (multi-AZ) |
| Private Subnet C | eu-west-2c | ALB (multi-AZ) |
| Data Subnet A | eu-west-2a | RDS primary |
| Data Subnet B | eu-west-2b | RDS standby (if multi-AZ) |
| Data Subnet C | eu-west-2c | RDS standby (if multi-AZ) |
| Public Subnet | Multiple AZs | Bastion host |

### Network Interface (ENI)

- **Name:** `oas-eni`
- **Subnet:** Private Subnet A
- **Private IP:** 10.26.56.148 (static)
- **Security Group:** `oas-development-ec2-security-group`

### DNS Configuration

#### Route53 Hosted Zone

- **Zone Name:** `laa-development.modernisation-platform.service.justice.gov.uk`
- **Zone Type:** Private
- **DNS Records:**
  - `oas.laa-development.modernisation-platform.service.justice.gov.uk` → ALB (A record, alias)
  - `oas-lb.laa-development.modernisation-platform.service.justice.gov.uk` → ALB (A record, alias)
  - `rds.oas.laa-development.modernisation-platform.service.justice.gov.uk` → RDS (CNAME, 60s TTL)

#### Hostname Configuration

- **Instance Hostname:** `oas`
- **Search Domain:** `laa-development.modernisation-platform.service.justice.gov.uk`
- **NTP Source:** 169.254.169.123 (AWS NTP)
- **NTP Daemon:** chronyd (for OL8)

---

## Security & Access Control

### Security Groups

#### EC2 Security Group

**Name:** `oas-development-ec2-security-group`

**Ingress Rules:**

| **Port** | **Protocol** | **Source** | **Description** |
|----------|-------------|-----------|-----------------|
| 22 | TCP | Bastion SG | SSH from Bastion |
| 1521 | TCP | RDS SG | Database connections from RDS |
| 9500 | TCP | ALB SG | Console/EM traffic from load balancer |
| 9502 | TCP | ALB SG | Analytics/DV traffic from load balancer |
| 9514 | TCP | 10.200.0.0/20 | Managed server access from workspaces |

**Egress Rules:**

| **Port** | **Protocol** | **Destination** | **Description** |
|----------|-------------|-----------------|-----------------|
| 1521 | TCP | RDS SG | Database connections to RDS |
| 80 | TCP | 0.0.0.0/0 | HTTP for yum repositories |
| 443 | TCP | 0.0.0.0/0 | HTTPS for yum, SSM |
| 443 | TCP | S3 VPC Endpoint | S3 access via VPC endpoint |

#### RDS Security Group

**Name:** `oas-development-rds-security-group`

**Ingress Rules:**

| **Port** | **Protocol** | **Source** | **Description** |
|----------|-------------|-----------|-----------------|
| 1521 | TCP | EC2 SG | Database connections from OAS EC2 |
| 1521 | TCP | 10.200.0.0/20 | SQL Developer from workspaces |

**Egress Rules:**

| **Port** | **Protocol** | **Destination** | **Description** |
|----------|-------------|-----------------|-----------------|
| 1521 | TCP | EC2 SG | Database responses to EC2 |
| 1521 | TCP | 10.200.0.0/20 | SQL Developer to workspaces |

#### Load Balancer Security Group

**Name:** `oas-lb-sg`

**Ingress Rules:**

| **Port** | **Protocol** | **Source** | **Description** |
|----------|-------------|-----------|-----------------|
| 80 | TCP | MOJ CIDRs | HTTP (redirects to HTTPS) |
| 443 | TCP | MOJ CIDRs + EC2 SG | HTTPS from allowed sources |
| 9500 | TCP | MOJ CIDRs | Console/EM access |
| 9502 | TCP | MOJ CIDRs | Analytics/DV access |

**Allowed CIDR Blocks:**
- `35.176.254.38/32` - Workspace
- `52.56.212.11/32` - Workspace
- `35.177.173.197/32` - Workspace
- `10.200.0.0/16` - Internal network
- `10.200.16.0/20` - LZ Prod Shared-Service Workspaces

**Egress Rules:**

| **Port** | **Protocol** | **Destination** | **Description** |
|----------|-------------|-----------------|-----------------|
| All | All | 0.0.0.0/0 | All traffic |

### IAM Configuration

#### EC2 IAM Role

**Role Name:** `oas-role`

**Assume Role Policy:**
- Service: `ec2.amazonaws.com`

**Attached Policies:**
1. `AmazonSSMManagedInstanceCore` (AWS managed)
   - Enables SSM Session Manager connectivity
   - Allows SSM agent to communicate with AWS Systems Manager

2. Custom Inline Policy: `oas-ec2-policy`
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": ["ec2:Describe*"],
         "Resource": "*"
       },
       {
         "Effect": "Allow",
         "Action": ["s3:ListBucket"],
         "Resource": [
           "arn:aws:s3:::modernisation-platform-software20230224000709766100000001",
           "arn:aws:s3:::modernisation-platform-software20230224000709766100000001/*"
         ]
       },
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:PutObject",
           "s3:PutObjectAcl"
         ],
         "Resource": [
           "arn:aws:s3:::modernisation-platform-software20230224000709766100000001/*"
         ]
       }
     ]
   }
   ```

**Instance Profile:** `oas-ec2-profile`

### Access Methods

#### 1. SSM Session Manager (Recommended)

**Advantages:**
- No bastion required
- Fully audited sessions
- No inbound security group rules needed
- Works through private network

**Connection Command:**
```bash
aws ssm start-session --target i-INSTANCE_ID --region eu-west-2
```

**Requirements:**
- AWS CLI installed
- Session Manager plugin installed
- IAM permissions for SSM
- SSM agent running on instance (enabled by default)

#### 2. SSH via Bastion

**Advantages:**
- Traditional SSH access
- Port forwarding support
- SCP/SFTP file transfer

**Connection Method:**
1. SSH to bastion host
2. SSH from bastion to OAS instance

**SSH Configuration:**
- **Port:** 22
- **KeepAlive:** 60 seconds interval, 120 retries (2 hours max idle)
- **Root Login:** Prohibited (key-based only)
- **Authorized Users:** ec2-user, root (key-based), oracle

### Secrets Management

#### AWS Secrets Manager Secrets

1. **EC2 SSH Private Key**
   - Secret Name: `oas-development/ec2-ssh-private-key`
   - Content: ED25519 private key (JSON format)
   - Used for: SSH access to EC2 instances

2. **RDS Master Password**
   - Secret Name: `oas/app/db-master-password`
   - Content: Master username and password (JSON format)
   - Lifecycle: Persists across Terraform runs
   - Rotation: Manual

---

## High Availability & Load Balancing

### Application Load Balancer

#### ALB Configuration

| **Attribute** | **Value** |
|---------------|-----------|
| **Name** | `oas-lb` |
| **Type** | Application Load Balancer |
| **Scheme** | Internal |
| **Subnets** | Private subnets across all AZs |
| **Security Groups** | `oas-lb-sg` |
| **Idle Timeout** | 60 seconds |
| **HTTP/2** | Enabled |
| **Drop Invalid Headers** | Disabled |
| **Preserve Host Header** | Disabled |
| **Deletion Protection** | Disabled (development) |

#### Target Groups

##### Console/EM Target Group

| **Attribute** | **Value** |
|---------------|-----------|
| **Name Prefix** | `oas-ec` |
| **Port** | 9500 |
| **Protocol** | HTTP |
| **Target Type** | Instance |
| **Deregistration Delay** | 30 seconds |
| **Stickiness** | LB cookie (86400 seconds / 24 hours) |

**Health Check:**
- Path: `/console`
- Port: 9500
- Protocol: HTTP
- Healthy Threshold: 3
- Unhealthy Threshold: 3
- Interval: 30 seconds
- Timeout: 5 seconds
- Success Codes: 200-399

##### Analytics/DV Target Group

| **Attribute** | **Value** |
|---------------|-----------|
| **Name Prefix** | `oas-an` |
| **Port** | 9502 |
| **Protocol** | HTTP |
| **Target Type** | Instance |
| **Deregistration Delay** | 30 seconds |
| **Stickiness** | LB cookie (86400 seconds / 24 hours) |

**Health Check:**
- Path: `/analytics`
- Port: 9502
- Protocol: HTTP
- Healthy Threshold: 3
- Unhealthy Threshold: 3
- Interval: 30 seconds
- Timeout: 5 seconds
- Success Codes: 200-399

#### Listeners & Routing

##### HTTP Listener (Port 80)

- **Action:** Redirect to HTTPS (port 443)
- **Status Code:** HTTP 301 (Permanent Redirect)

##### HTTPS Listener (Port 443)

- **Protocol:** HTTPS
- **Certificate:** ACM certificate (validated)
- **Default Action:** Fixed response (404 Not Found)
- **Security Policy:** Default TLS policy
- **Content Security Policy:** `upgrade-insecure-requests`

##### HTTP Listener (Port 9500) - Console/EM

- **Protocol:** HTTP
- **Default Action:** Forward to Console/EM target group
- **Path-based Routing:**
  - `/console*` → Console target group (priority 100)
  - `/em*` → EM target group (priority 101)

##### HTTP Listener (Port 9502) - Analytics

- **Protocol:** HTTP
- **Default Action:** Forward to Analytics target group
- **Path-based Routing:**
  - `/analytics*` → Analytics target group

### SSL/TLS Configuration

#### ACM Certificate

- **Primary Domain:** `modernisation-platform.service.justice.gov.uk`
- **Subject Alternative Name:** `*.laa-development.modernisation-platform.service.justice.gov.uk`
- **Validation Method:** DNS
- **Certificate Type:** Public
- **Auto-Renewal:** Yes (ACM managed)

**Validation Records:**
- Parent domain validates in `modernisation-platform.service.justice.gov.uk` zone
- Environment-specific domains validate in `laa-development.modernisation-platform.service.justice.gov.uk` zone

---

## DNS & Routing

### Route53 Configuration

#### Application DNS Record

- **Record Name:** `oas.laa-development.modernisation-platform.service.justice.gov.uk`
- **Type:** A (Alias)
- **Target:** Application Load Balancer DNS name
- **Evaluate Target Health:** Yes

#### Load Balancer DNS Record

- **Record Name:** `oas-lb.laa-development.modernisation-platform.service.justice.gov.uk`
- **Type:** A (Alias)
- **Target:** Application Load Balancer DNS name
- **Evaluate Target Health:** Yes

#### Database DNS Record

- **Record Name:** `rds.oas.laa-development.modernisation-platform.service.justice.gov.uk`
- **Type:** CNAME
- **Target:** RDS endpoint address
- **TTL:** 60 seconds

### URL Access Patterns

| **URL** | **Port** | **Target** | **Purpose** |
|---------|----------|-----------|-------------|
| `https://oas.laa-development.modernisation-platform.service.justice.gov.uk` | 443 | ALB → EC2 | Main application (default 404) |
| `http://oas-lb.laa-development.modernisation-platform.service.justice.gov.uk:9500/console` | 9500 | ALB → EC2 | WebLogic Console |
| `http://oas-lb.laa-development.modernisation-platform.service.justice.gov.uk:9500/em` | 9500 | ALB → EC2 | Enterprise Manager |
| `http://oas-lb.laa-development.modernisation-platform.service.justice.gov.uk:9502/analytics` | 9502 | ALB → EC2 | Analytics/Data Visualization |

---

## Monitoring & Logging

### CloudWatch Monitoring

#### EC2 Monitoring

- **Detailed Monitoring:** Enabled
- **Metrics Collection Interval:** 1 minute
- **Available Metrics:**
  - CPU Utilization
  - Network In/Out
  - Disk Read/Write Ops
  - Disk Read/Write Bytes
  - Status Check Failed

#### RDS Monitoring

- **Enhanced Monitoring:** Configurable
- **Performance Insights:** Configurable
- **Available Metrics:**
  - CPU Utilization
  - Database Connections
  - Free Storage Space
  - Read/Write IOPS
  - Read/Write Latency

#### ALB Monitoring

- **Metrics:**
  - Request Count
  - Active Connection Count
  - Target Response Time
  - HTTP 2xx/3xx/4xx/5xx counts
  - Healthy/Unhealthy Host Count

### Logging

#### ALB Access Logs

- **Location:** S3 bucket (`oas-lb-access-logs-*`)
- **Prefix:** `oas/`
- **Format:** Standard ALB access log format
- **Retention:** See S3 lifecycle policy (730 days)
- **Encryption:** KMS encrypted

#### EC2 System Logs

- **Userdata Log:** `/var/log/userdata.log`
  - Contains complete userdata execution output
  - Useful for troubleshooting initialization issues

- **SSH Log:** `/var/log/secure`
  - SSH authentication attempts
  - Session establishment/termination

- **System Log:** `/var/log/messages`
  - General system messages
  - Service start/stop events

- **SSM Agent Log:** `/var/log/amazon/ssm/amazon-ssm-agent.log`
  - SSM agent activity
  - Session Manager connections

#### RDS Logs

- **Available Logs:**
  - Error log
  - General log
  - Slow query log (if enabled)
  - Audit log (if enabled)

- **Access:** Via AWS Console or CLI
- **Export:** Can be exported to CloudWatch Logs

---

## Backup & Disaster Recovery

### RDS Automated Backups

| **Parameter** | **Value** |
|---------------|-----------|
| **Retention Period** | 35 days |
| **Backup Window** | 22:00-01:00 UTC (Daily) |
| **Point-in-Time Recovery** | Enabled (last 35 days) |
| **Backup Type** | Automated snapshots |
| **Storage** | S3 (AWS managed) |
| **Encryption** | Encrypted with KMS |

### Manual Snapshots

#### EBS Volume Snapshots

**Current Snapshots:**
- **Oracle Home:** snap-0ce71d391351de5c5 (development)
- **Stage:** snap-05f2f12f265bdb020 (development)

**Strategy:**
- Create snapshots before major changes
- Tag snapshots with environment and purpose
- Retain critical snapshots beyond instance lifecycle

#### EC2 AMI Creation

**Latest AMI:**
- **Name:** `oas-mp-dev-ol8.10-clean-20260422`
- **OS:** Oracle Linux 8.10
- **Description:** Clean OL8.10 AMI after successful Leapp upgrade from 7.9
- **Status:** Validated, ready for production deployment
- **Creation Date:** 22 April 2026

**AMI Strategy:**
- Create AMI after successful OS upgrades
- Create AMI before major application changes
- Document AMI ID in application_variables.json
- Test AMI in non-production before production use

### Recovery Procedures

#### EC2 Instance Recovery

1. **From AMI:**
   ```bash
   # Update application_variables.json with recovery AMI ID
   # Run Terraform apply
   terraform apply -target=aws_instance.oas_app_instance_new
   ```

2. **From Snapshot:**
   ```bash
   # Create volumes from snapshots
   # Update application_variables.json with snapshot IDs
   # Run Terraform apply
   ```

#### RDS Recovery

1. **Point-in-Time Restore:**
   - Available for last 35 days
   - Restore to any point within backup retention window
   - Creates new RDS instance

2. **From Snapshot:**
   - Manual or automated snapshots
   - Full database restore
   - Update DNS to point to new instance

### Recovery Time Objective (RTO)

- **EC2 Instance:** ~15-30 minutes (from AMI)
- **RDS Instance:** ~30-60 minutes (point-in-time restore)
- **Complete Environment:** ~45-90 minutes

### Recovery Point Objective (RPO)

- **RDS Database:** 5 minutes (point-in-time recovery)
- **EC2 Data:** Depends on snapshot frequency
- **Application State:** Depends on application backup strategy

---

## Deployment Process

### Terraform Workflow

#### Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (version constraints in versions.tf)
3. Access to Modernisation Platform shared services
4. Appropriate IAM permissions

#### Deployment Steps

```bash
# 1. Navigate to OAS Terraform directory
cd terraform/environments/oas

# 2. Initialize Terraform
terraform init

# 3. Select workspace (environment)
terraform workspace select oas-development

# 4. Review planned changes
terraform plan

# 5. Apply changes
terraform apply

# 6. Verify deployment
terraform show
```

#### Configuration Files

##### application_variables.json

Contains environment-specific configuration:
```json
{
  "accounts": {
    "development": {
      "ec2amiid": "ami-02637525ccfc684ac",
      "ec2instancetype": "r5a.large",
      "orahomesize": "300",
      "orahome_snapshot": "snap-0ce71d391351de5c5",
      "stageesize": "300",
      "stage_snapshot": "snap-05f2f12f265bdb020",
      "ec2_private_ip": "10.26.56.148",
      ...
    }
  }
}
```

##### networking.auto.tfvars.json

Contains network configuration (auto-loaded by Terraform).

### Userdata Script Flow

The userdata script (`new-userdata.sh`) executes during EC2 instance initialization:

#### 1. SSH Key Replacement
- Fetches public key from EC2 metadata service
- Updates authorized_keys for ec2-user, root, oracle

#### 2. Hostname Configuration
- Sets hostname to `oas`
- Updates DNS resolver configuration

#### 3. EBS Volume Detection & Mounting
- Waits for EBS volumes to attach (max 150 seconds)
- Dynamically identifies volumes by size
- Mounts largest to `/oracle/software`
- Mounts second-largest to `/stage`
- Updates `/etc/fstab` with `nofail` option

#### 4. SSH Host Key Generation
- Checks for missing SSH host keys
- Regenerates if needed using `ssh-keygen -A`

#### 5. Swap Configuration
- Creates 1GB swap file at `/root/myswapfile`
- Activates swap
- Adds to `/etc/fstab`

#### 6. NTP Configuration
- Detects OS version (OL7 vs OL8)
- Configures chronyd (OL8) or ntpd (OL7)
- Uses AWS NTP source (169.254.169.123)

#### 7. Package Installation
- Disables deltarpm (OS-version aware)
- Installs: sshpass, jq, xorg-x11-xauth, xclock, xterm

#### 8. SSM Agent Configuration
- Checks if SSM agent already installed
- Installs if missing
- Starts and enables SSM service

#### 9. Firewall Disable
- Stops firewalld
- Disables firewalld (not needed in AWS security group model)

#### 10. SSH KeepAlive Configuration
- Adds ClientAliveInterval and ClientAliveCountMax to sshd_config
- Tests sshd configuration before restart
- Restarts SSH service

#### Logging

All userdata output is logged to `/var/log/userdata.log` for troubleshooting.

### Deployment Validation

After deployment, verify:

1. **EC2 Instance:**
   ```bash
   aws ec2 describe-instances --instance-ids i-XXXXX --region eu-west-2
   ```

2. **SSM Connectivity:**
   ```bash
   aws ssm start-session --target i-XXXXX --region eu-west-2
   ```

3. **Volume Mounts:**
   ```bash
   df -h | grep -E "oracle|stage"
   ```

4. **Services:**
   ```bash
   systemctl --failed
   ```

5. **Load Balancer Health:**
   ```bash
   aws elbv2 describe-target-health --target-group-arn <TG_ARN>
   ```

---

## Operational Procedures

### Accessing the Environment

#### Via SSM Session Manager (Recommended)

```bash
# Find instance ID
aws ec2 describe-instances \
  --region eu-west-2 \
  --filters "Name=tag:Name,Values=*oas*" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],PrivateIpAddress,State.Name]' \
  --output table

# Connect via SSM
aws ssm start-session --target i-INSTANCE_ID --region eu-west-2
```

#### Via SSH (Bastion)

```bash
# SSH to bastion (obtain bastion details from bastion.tf)
ssh -i ~/.ssh/bastion-key.pem ec2-user@bastion-hostname

# From bastion, SSH to OAS instance
ssh ec2-user@10.26.56.148
# or
ssh oracle@10.26.56.148
```

### Common Maintenance Tasks

#### Restarting Services

```bash
# WebLogic Managed Servers (as oracle user)
su - oracle
cd /oracle/software/domains/oas_domain/bin
./stopManagedWebLogic.sh oas_server1
./startManagedWebLogic.sh oas_server1

# Check service status
./status.sh
```

#### Checking Logs

```bash
# Application logs
tail -f /oracle/software/domains/oas_domain/servers/*/logs/*.log

# System logs
sudo tail -f /var/log/messages

# Userdata execution log
sudo cat /var/log/userdata.log
```

#### Volume Space Management

```bash
# Check disk usage
df -h

# Find large files in /oracle/software
sudo du -sh /oracle/software/* | sort -hr | head -20

# Find large files in /stage
sudo du -sh /stage/* | sort -hr | head -20

# Clean up old logs (with caution)
find /oracle/software -name "*.log" -mtime +30 -exec rm -f {} \;
```

#### Database Connectivity Test

```bash
# Test RDS connectivity
telnet rds.oas.laa-development.modernisation-platform.service.justice.gov.uk 1521

# Oracle SQL*Plus test (as oracle user)
su - oracle
sqlplus sysdba/PASSWORD@rds.oas.laa-development.modernisation-platform.service.justice.gov.uk:1521/SERVICENAME

# Quick connection test
echo "SELECT 1 FROM DUAL;" | sqlplus -s sysdba/PASSWORD@//rds.oas...:1521/SID
```

### Updating Infrastructure

#### Changing Instance Type

1. Update `application_variables.json`:
   ```json
   "ec2instancetype": "r5a.xlarge"
   ```

2. Plan and apply:
   ```bash
   terraform plan
   terraform apply
   ```

3. Note: This will cause instance recreation and brief downtime.

#### Updating AMI (OS Upgrade)

1. Create new AMI from upgraded test instance
2. Update `application_variables.json`:
   ```json
   "ec2amiid": "ami-NEW_AMI_ID"
   ```

3. Plan and apply:
   ```bash
   terraform plan
   terraform apply
   ```

4. Verify userdata execution and volume mounts
5. Test application functionality

#### Adding Security Group Rules

1. Edit appropriate security group file:
   - `new-ec2-sg.tf` for EC2 rules
   - `new-rds-sg.tf` for RDS rules
   - `new-alb.tf` for ALB rules

2. Add rule resource:
   ```hcl
   resource "aws_security_group_rule" "new_rule" {
     type              = "ingress"
     security_group_id = aws_security_group.ec2_sg[0].id
     from_port         = 8080
     to_port           = 8080
     protocol          = "tcp"
     cidr_blocks       = ["10.0.0.0/8"]
     description       = "New application port"
   }
   ```

3. Apply changes:
   ```bash
   terraform apply
   ```

---

## Troubleshooting Guide

### Common Issues

#### Issue 1: SSH Connection Refused

**Symptoms:**
```
channel 0: open failed: connect failed: Connection refused
stdio forwarding failed
```

**Root Causes:**
- SSH service not running
- SSH host keys missing
- Userdata still executing

**Resolution:**

1. Connect via SSM:
   ```bash
   aws ssm start-session --target i-INSTANCE_ID --region eu-west-2
   ```

2. Check SSH service:
   ```bash
   sudo systemctl status sshd
   sudo journalctl -xeu sshd
   ```

3. Check for missing host keys:
   ```bash
   sudo ls -la /etc/ssh/ssh_host_*
   ```

4. Regenerate if missing:
   ```bash
   sudo ssh-keygen -A
   sudo systemctl restart sshd
   ```

5. Check userdata completion:
   ```bash
   tail -f /var/log/userdata.log
   ps aux | grep userdata
   ```

#### Issue 2: EBS Volumes Not Mounted

**Symptoms:**
- `/oracle/software` or `/stage` not accessible
- Application fails to start

**Resolution:**

1. Check if volumes are attached:
   ```bash
   lsblk
   ```

2. Check mount status:
   ```bash
   df -h
   mount | grep -E "oracle|stage"
   ```

3. Check `/etc/fstab`:
   ```bash
   cat /etc/fstab
   ```

4. Manual mount attempt:
   ```bash
   sudo mount -a
   ```

5. Check userdata log for errors:
   ```bash
   sudo grep -i "error\|fail" /var/log/userdata.log
   ```

6. Verify volumes in AWS Console:
   - EC2 → Volumes
   - Check attachment status
   - Verify instance ID matches

#### Issue 3: SSM Agent Not Responding

**Symptoms:**
- Cannot start SSM session
- "TargetNotConnected" error

**Resolution:**

1. Check SSM agent status (via SSH if available):
   ```bash
   sudo systemctl status amazon-ssm-agent
   sudo systemctl restart amazon-ssm-agent
   ```

2. Check agent logs:
   ```bash
   sudo tail -100 /var/log/amazon/ssm/amazon-ssm-agent.log
   ```

3. Verify IAM role attachment:
   ```bash
   aws ec2 describe-instances --instance-ids i-XXXXX \
     --query 'Reservations[*].Instances[*].IamInstanceProfile'
   ```

4. Check security group allows HTTPS egress (port 443)

5. Reinstall SSM agent if needed:
   ```bash
   sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
   sudo systemctl enable amazon-ssm-agent
   sudo systemctl start amazon-ssm-agent
   ```

#### Issue 4: Load Balancer Health Checks Failing

**Symptoms:**
- Targets showing "unhealthy" in target group
- Application not accessible via ALB

**Resolution:**

1. Check application is listening on correct port:
   ```bash
   sudo netstat -tlnp | grep -E "9500|9502"
   ```

2. Test health check endpoint locally:
   ```bash
   curl http://localhost:9500/console
   curl http://localhost:9502/analytics
   ```

3. Check security group allows traffic from ALB:
   ```bash
   # Verify ingress rules from ALB security group
   aws ec2 describe-security-groups --group-ids sg-XXXXX
   ```

4. Check target group configuration:
   ```bash
   aws elbv2 describe-target-health --target-group-arn arn:aws:...
   ```

5. Review ALB access logs in S3

#### Issue 5: RDS Connection Timeout

**Symptoms:**
- Cannot connect to RDS from EC2
- "ORA-12170: TNS:Connect timeout occurred"

**Resolution:**

1. Test network connectivity:
   ```bash
   telnet rds.oas.laa-development.modernisation-platform.service.justice.gov.uk 1521
   ```

2. Check security group rules:
   - RDS SG allows inbound 1521 from EC2 SG
   - EC2 SG allows outbound 1521 to RDS SG

3. Verify RDS status:
   ```bash
   aws rds describe-db-instances --db-instance-identifier oas-development
   ```

4. Check DNS resolution:
   ```bash
   nslookup rds.oas.laa-development.modernisation-platform.service.justice.gov.uk
   ```

5. Verify database is running:
   - Check RDS console
   - Review RDS events

#### Issue 6: Terraform Apply Failures

**Common Errors and Solutions:**

**"Error: Resource already exists"**
```bash
# Import existing resource
terraform import aws_instance.oas_app_instance_new i-INSTANCE_ID

# Or remove from state and reapply
terraform state rm aws_instance.oas_app_instance_new
terraform apply
```

**"Error: InvalidParameterValue: Invalid IAM Instance Profile name"**
- Check IAM role and instance profile exist
- Verify naming matches Terraform configuration

**"Error: DependencyViolation"**
- Resource still in use (ENI, security group, etc.)
- Manually detach/delete blocking resources
- Retry Terraform operation

### Performance Troubleshooting

#### High CPU Usage

```bash
# Check CPU usage
top
htop

# Identify processes
ps aux --sort=-%cpu | head -20

# Check WebLogic thread dumps (as oracle user)
su - oracle
kill -3 <JAVA_PID>  # Creates thread dump in server logs
```

#### High Memory Usage

```bash
# Check memory usage
free -h
vmstat 1 10

# Identify memory-consuming processes
ps aux --sort=-%mem | head -20

# Check for memory leaks in Java
# Review heap dumps if enabled
```

#### Disk I/O Issues

```bash
# Check I/O stats
iostat -x 1 10

# Identify processes with high I/O
iotop

# Check for disk space issues
df -h
du -sh /* | sort -hr
```

### Log Analysis

#### Useful Log Commands

```bash
# Search for errors in all logs
sudo grep -r "ERROR\|FATAL" /var/log/

# Check recent system messages
sudo journalctl -xe

# Monitor multiple logs simultaneously
sudo tail -f /var/log/messages /var/log/secure /var/log/userdata.log

# Search application logs
find /oracle/software -name "*.log" -exec grep -l "ERROR" {} \;

# Count error occurrences
grep -c "ERROR" /oracle/software/domains/*/servers/*/logs/*.log
```

---

## Appendices

### Appendix A: Port Reference

| **Port** | **Protocol** | **Service** | **Direction** |
|----------|-------------|------------|---------------|
| 22 | TCP | SSH | Inbound (from Bastion) |
| 80 | TCP | HTTP (redirect) | Inbound (ALB) |
| 443 | TCP | HTTPS | Inbound/Outbound |
| 1521 | TCP | Oracle Database | Bidirectional (EC2↔RDS) |
| 9500 | TCP | WebLogic Console/EM | Inbound (from ALB) |
| 9502 | TCP | Analytics/DV | Inbound (from ALB) |
| 9514 | TCP | Managed Server | Inbound (from Workspaces) |

### Appendix B: File Locations

#### Configuration Files

| **File** | **Location** | **Purpose** |
|----------|-------------|------------|
| SSH Config | `/etc/ssh/sshd_config` | SSH daemon configuration |
| Userdata Log | `/var/log/userdata.log` | Instance initialization log |
| fstab | `/etc/fstab` | Filesystem mount configuration |
| Chrony Config | `/etc/chrony.conf` | NTP configuration (OL8) |
| YUM Config | `/etc/yum.conf` (OL7) | Package manager config |
| DNF Config | `/etc/dnf/dnf.conf` (OL8) | Package manager config |
| SSH Host Keys | `/etc/ssh/ssh_host_*` | SSH server identity keys |
| Authorized Keys | `~/.ssh/authorized_keys` | SSH public keys for authentication |

#### Application Files

| **Component** | **Location** |
|---------------|-------------|
| Oracle Home | `/oracle/software` |
| Stage Area | `/stage` |
| WebLogic Domain | `/oracle/software/domains/oas_domain/` |
| Application Logs | `/oracle/software/domains/*/servers/*/logs/` |

### Appendix C: Terraform File Structure

```
terraform/environments/oas/
├── application_variables.json       # Environment-specific config
├── networking.auto.tfvars.json     # Network configuration
├── bastion.tf                       # Bastion host configuration
├── data.tf                          # Data sources
├── lambda.tf                        # Lambda functions
├── locals.tf                        # Local variables
├── new-acm.tf                       # ACM certificates
├── new-alb.tf                       # Application Load Balancer
├── new-ec2.tf                       # EC2 instance (main)
├── new-ec2-ebs.tf                  # EBS volumes
├── new-ec2-iam.tf                  # IAM roles and policies
├── new-ec2-sg.tf                   # EC2 security groups
├── new-ec2-upgrade.tf              # EC2 upgrade test instance
├── new-rds.tf                      # RDS database
├── new-rds-sg.tf                   # RDS security groups
├── new-route53.tf                  # DNS records
├── platform_backend.tf             # Terraform backend config
├── platform_base_variables.tf      # Base variables
├── platform_data.tf                # Platform data sources
├── platform_locals.tf              # Platform local variables
├── platform_providers.tf           # AWS provider configuration
├── platform_secrets.tf             # Secrets configuration
├── versions.tf                     # Terraform version constraints
├── weblogic.tf                     # Legacy WebLogic config
├── README.md                       # Service runbook
├── files/
│   ├── bastion_linux.json         # Bastion configuration
│   └── new-userdata.sh            # EC2 userdata script
└── docs/
    ├── OAS-Infrastructure-Documentation.md   # This document
    ├── OAS-Infrastructure-Diagrams.md        # Diagram index
    ├── OAS-Diagram-High-Level-Architecture.md  # Architecture diagram
    ├── OAS-Diagram-Component-Flow.md         # Component flow diagram
    └── OL7-to-OL8-Upgrade-Steps.md          # OS upgrade report
```

### Appendix D: Useful Commands Reference

#### AWS CLI Commands

```bash
# EC2 Instance Information
aws ec2 describe-instances --instance-ids i-XXXXX --region eu-west-2

# RDS Instance Information
aws rds describe-db-instances --db-instance-identifier oas-development

# Load Balancer Target Health
aws elbv2 describe-target-health --target-group-arn arn:aws:...

# Security Group Rules
aws ec2 describe-security-groups --group-ids sg-XXXXX

# Secrets Manager
aws secretsmanager get-secret-value --secret-id oas-development/ec2-ssh-private-key

# SSM Parameter Store
aws ssm get-parameter --name /oas/development/config

# CloudWatch Logs
aws logs tail /aws/ec2/instance/i-XXXXX --follow
```

#### System Administration Commands

```bash
# Service Management
sudo systemctl status SERVICE_NAME
sudo systemctl restart SERVICE_NAME
sudo systemctl enable SERVICE_NAME

# Log Analysis
sudo journalctl -u SERVICE_NAME
sudo journalctl -xe
sudo tail -f /var/log/messages

# Network Troubleshooting
sudo netstat -tlnp
sudo ss -tlnp
sudo tcpdump -i any port 1521

# Disk Management
df -h
du -sh /path/*
lsblk
mount -a

# Process Management
ps aux | grep PATTERN
top
htop
kill -15 PID
```

### Appendix E: Contact Information

#### Support Channels

- **Primary Contact:** OAS Team via internal ticketing system
- **Modernisation Platform Support:** `#ask-modernisation-platform` Slack channel
- **Emergency Contact:** On-call rotation (PagerDuty)

#### Related Documentation

- **Infrastructure Diagrams:** [OAS-Infrastructure-Diagrams.md](OAS-Infrastructure-Diagrams.md) (Index)
  - [High-Level Architecture](OAS-Diagram-High-Level-Architecture.md)
  - [Component Flow](OAS-Diagram-Component-Flow.md)
- **OS Upgrade Report:** [OL7-to-OL8-Upgrade-Steps.md](OL7-to-OL8-Upgrade-Steps.md)
- **Oracle Linux Documentation:** https://docs.oracle.com/en/operating-systems/oracle-linux/8/
- **AWS Modernisation Platform:** Internal documentation portal
- **Terraform AWS Provider:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs

### Appendix F: Change Log

| **Date** | **Version** | **Changes** | **Author** |
|----------|------------|------------|-----------|
| 2026-04-23 | 1.0 | Initial documentation creation | DevOps Team |

---

## Document Revision Information

**Document Owner:** OAS DevOps Team  
**Review Frequency:** Quarterly  
**Next Review Date:** July 2026  
**Classification:** Internal Use Only

---

**End of Document**
