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
10. [Deployment Process](#deployment-process)

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

## Deployment Process

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

