# SSOGEN Infrastructure - Terraform Configuration Guide

## Overview

The SSOGEN (Single Sign-On Generation) infrastructure in the CCMS EBS environment consists of a comprehensive set of Terraform configuration files that deploy and manage a highly available WebLogic/Oracle HTTP Server-based single sign-on solution. All SSOGEN infrastructure is controlled by the `local.ssogen_enabled` variable, allowing for easy enablement/disablement across different environments.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Component Breakdown](#component-breakdown)
3. [File Reference](#file-reference)
4. [Deployment Considerations](#deployment-considerations)
5. [Monitoring and Observability](#monitoring-and-observability)

---

## Architecture Overview

SSOGEN is deployed as a highly available infrastructure with the following key characteristics:

- **Compute**: Multiple EC2 instances running WebLogic and Oracle HTTP Server (OHS)
- **Storage**: Shared EFS (Elastic File System) for persistent storage
- **Load Balancing**: Internal Application Load Balancers (ALBs) for traffic distribution
- **Networking**: Private subnets with security groups for secure access
- **Monitoring**: CloudWatch logs and metrics with predefined alarms
- **Security**: IAM roles, KMS encryption, WAF protection, and Secrets Manager integration

---

## Component Breakdown

### Compute & Infrastructure

#### [ssogen-ec2.tf](ssogen-ec2.tf)
**Purpose**: Manages EC2 instances and launch templates for SSOGEN application servers

**Key Resources**:

1. **User Data Templates**:
   - `launch-template1` & `launch-template2`: Configure hostname, disk mounts, EFS mount points
   - Variables passed to templates:
     - Hostname: `ccms-{application_name}-as1/as2`
     - MP FQDN: `{business-unit}-{environment}.modernisation-platform.service.justice.gov.uk`
     - Disk array and EFS mount point configuration
     - Log paths for AdminServer, OHS, and Managed Servers

2. **Launch Templates** (Primary & Secondary):
   - **Primary Template** (`ssogen-ec2-launch-template-primary`):
     - Uses primary AMI ID: `ssogen_ami_id-1`
   - **Secondary Template** (`ssogen-ec2-launch-template-secondary`):
     - Uses secondary AMI ID: `ssogen_ami_id-2`
   
   **Configuration for both**:
   - Instance type: `ec2_oracle_instance_type_ssogen` (environment-specific)
   - EBS optimized: enabled
   - Monitoring: enabled (CloudWatch detailed monitoring)
   - IAM instance profile: `ssogen_instance_profile`
   - Public IP association: disabled
   - Security groups: `ssogen_sg`
   - User data: base64-encoded template files
   
   **Block Device Mappings** (encrypted EBS volumes with KMS):
   - `/dev/sda1`: Root volume (`ec2_disk_size_ssogen`)
   - `/dev/sdb`: Framework volume (`ec2_disk_size_ssogen_fmw`) for WebLogic framework
   - `/dev/sdc`: Managed Server volume (`ec2_disk_size_ssogen_mserver`)
   - `/dev/sdd`: Temp volume (`ec2_disk_size_ssogen_temp`)
   
   **Tagging**:
   - Instance role reference
   - Backup: enabled
   - Instance scheduling: skip-scheduling (prevents automatic shutdown)
   - Volume tags for tracking

3. **Auto-Scaling Groups**:
   - **Primary ASG**: `ssogen-scaling-group-primary`
     - Capacity: `ssogen_desired_capacity`, `ssogen_max_capacity`, `ssogen_min_capacity`
     - Target groups: both application and console load balancers
     - Spans all shared private subnets
   - **Secondary ASG**: Similar configuration for secondary instances

**Enable/Disable**: Controlled by `local.ssogen_enabled` variable

---

#### [ssogen-storage.tf](ssogen-storage.tf)
**Purpose**: Provisions shared EFS storage for SSOGEN instances

**Key Resources**:
- **EFS File System**:
  - Encrypted at rest
  - Performance mode configurable per environment
  - Automatic backups enabled (tagged with `backup = "true"`)
  
- **Mount Targets**:
  - Three mount targets across availability zones (A, B, C)
  - Placed in data subnets for high availability
  - Secured by EFS security group

**Use Case**: Shared WebLogic/OHS configuration and runtime data across instances

---

### Networking & Load Balancing

#### [ssogen-load-balancer.tf](ssogen-load-balancer.tf)
**Purpose**: Deploys Application Load Balancers and target groups for SSOGEN traffic

**Key Load Balancers**:
1. **Main ALB** (`lb-{application_name}-internal`)
   - Internal load balancer in shared private subnets
   - Routes main application traffic (port 443 via HTTPS)
   - Deletion protection enabled for production safety
   - Access logs stored in S3 with prefix `{application_name}-alb-logs`

2. **Console ALB** (`lb-console-{application_name}-internal`)
   - Internal load balancer for admin console access
   - Routes admin traffic (port 443 via HTTPS)
   - Same protection and logging as main ALB

**Target Groups**:
1. **Main Application Target Group** (`ssogen_internal_tg_ssogen_enc_app`):
   - Protocol: HTTPS
   - Port: `tg_ssogen_apps_enc_port` (from application data)
   - Target type: EC2 instances
   - Health check:
     - Path: `/`
     - Protocol: HTTPS
     - Expected response: HTTP 200
     - Interval: 30 seconds
     - Timeout: 5 seconds
     - Healthy threshold: 3
     - Unhealthy threshold: 3
   - **Sticky sessions**: Enabled (LB cookie, 3600s duration) for session persistence

2. **Console Target Group** (`ssogen_internal_tg_ssogen_console`):
   - Protocol: HTTPS
   - Port: `tg_ssogen_admin_enc_port`
   - Same health check configuration as above
   - No stickiness configuration

**Listeners**:
1. **Main ALB Listener** (`ssogen_internal_app_listener`):
   - Port: 443
   - Protocol: HTTPS
   - SSL Policy: `ELBSecurityPolicy-TLS13-1-2-2021-06` (modern TLS)
   - Certificate: `data.aws_acm_certificate.external_ssogen` (external certificate)
   - Forwards traffic to main target group
   - Depends on certificate validation

2. **Console ALB Listener** (`ssogen_internal_console_listener`):
   - Port: 443
   - Protocol: HTTPS
   - SSL Policy: `ELBSecurityPolicy-TLS13-1-2-2021-06`
   - Certificate: Same as main ALB
   - Forwards traffic to console target group

**Configuration**:
- Drop invalid HTTP headers: enabled
- Both ALBs configured for HTTPS with modern TLS policies
- Access logging enabled for audit and troubleshooting
- Targets registered via auto-scaling groups

---

#### [ssogen-lb-sg.tf](ssogen-lb-sg.tf)
**Purpose**: Security groups controlling traffic to load balancers

**Ingress Rules**:
- **Port 443 (HTTPS)**: From AWS WorkSpaces CIDR blocks for user access
- **Port 4443**: From WorkSpaces subnets for secure admin console

**Security Groups**:
- `sg_ssogen_internal_alb`: Main application ALB
- `sg_ssogen_console_internal_alb`: Console ALB

---

#### [ssogen-ec2-sg.tf](ssogen-ec2-sg.tf)
**Purpose**: Security groups for EC2 instances

**Active Rules**:
- Port 443: From WorkSpaces subnets (secure console)


---

#### [ssogen-r53.tf](ssogen-r53.tf)
**Purpose**: Route53 DNS records for SSOGEN services

**DNS Records Created**:

1. **Load Balancer Aliases** (ALB endpoints):
   - `ccmsebs-sso`: Points to main application ALB via alias record
   - `ccmsebs-sso-admin`: Points to console ALB via alias record
   - Zone ID: External hosted zone
   - Health check evaluation: enabled (automatic failover)

2. **Instance A Records** (for direct EC2 access):
   - `ccms-{application_name}-as1.{business-unit}-{environment}.modernisation-platform.service.justice.gov.uk`
     - Records primary instance IP from ASG
     - TTL: 300 seconds
   - `ccms-{application_name}-as2.{business-unit}-{environment}.modernisation-platform.service.justice.gov.uk`
     - Records secondary instance IP from ASG
     - TTL: 300 seconds

3. **Admin Primary Record**:
   - `ccms-{application_name}-admin.{business-unit}-{environment}.modernisation-platform.service.justice.gov.uk`
     - Points to primary instance private IP
     - TTL: 300 seconds
     - Used for admin direct access

**Features**:
- ALB alias records with health check evaluation for automatic failover
- Data sources query EC2 instances by auto-scaling group tags
- Filters for running instances to ensure fresh IP data
- Provider: `aws.core-vpc` for cross-account DNS management

---

### Clustering & Failover
** Failover to admin will be manually controlled

### Security & Access Control

#### [ssogen-iam.tf](ssogen-iam.tf)
**Purpose**: IAM roles and permissions for SSOGEN infrastructure

**Key Resources**:

1. **EC2 Role** (`ssogen_ec2_role_{environment}`):
   - Assumed by EC2 instances
   - Service principal: `ec2.amazonaws.com`
   - Tags reference environment

2. **Instance Profile** (`ssogen_instance_profile_{environment}`):
   - Attaches EC2 role to instances
   - Referenced in launch template IAM instance profile

3. **Managed Policies**:
   - `AmazonSSMManagedInstanceCore`: 
     - Session Manager access for remote connection
     - CloudWatch agent deployment
     - AWS Systems Manager patching
     - Parameter Store access

4. **Additional Permissions** (via inline policies):
   - CloudWatch agent configuration upload/download
   - Specific to monitoring and observability

5. **KMS Key Alias**:
   - Managed here: `alias/ssogen-key-alias`
   - Target: `ssogen_kms_key` from ssogen-key.tf

**Security Model**: 
- Least privilege: Only SSM managed core policy
- Session Manager enables secure shell access without SSH keys
- No direct SSH access needed (uses Systems Manager)
- CloudWatch permissions enable comprehensive logging

---

#### [ssogen-key.tf](ssogen-key.tf)
**Purpose**: KMS encryption keys and SSH key pair management for SSOGEN

**Security Features**:
- All keys encrypted at rest
- Cross-account access restricted to known account IDs


---

#### [ssogen-secrets.tf](ssogen-secrets.tf)
**Purpose**: AWS Secrets Manager secrets for account credentials

**Secrets Stored**:
- `{application_name}-dev-account-secrets`: Contains account IDs for:
  - Dev account ID
  - Preprod account ID
  - Prod account ID

**Usage**:
- Referenced by KMS key policies for cross-account access
- Updated manually (lifecycle: `ignore_changes`)

---

### Monitoring & Observability

#### [ssogen-cloudwatch.tf](ssogen-cloudwatch.tf)
**Purpose**: CloudWatch log groups, metrics, and alarms

**Log Groups** (configured per application data):
```
/aws/ssogen/admin-server
/aws/ssogen/ohs
/aws/ssogen/managed-server
```

**CloudWatch Agent**:
- Configuration stored in SSM Parameter Store: `ssogen-cloud-watch-config`
- References template file: `templates/cw_agent_config_ssogen.json`
- Deployed to EC2 instances via IAM role

**Alarms**:
1. **ALB 5xx Errors** (`{application_name}-{environment}-5xx-errors`)
   - Triggers when > 10 5xx errors in 3 minutes
   - Indicates application server issues

2. **Additional Alarms**: (Expandable)
   - Target unavailability
   - High latency
   - Unhealthy target count

---

#### [ssogen-athena.tf](ssogen-athena.tf)
**Purpose**: SQL query interface for analyzing load balancer access logs

**Components**:
1. **Athena Database**: `ssogen_loadbalancer_access_logs`
   - S3 bucket: logging bucket
   - Encryption: SSE-S3

2. **Workgroup**: `{application_name}-{environment}-lb-access-logs`
   - Enforces configuration per workgroup
   - CloudWatch metrics enabled
   - Results stored in S3 output/

3. **Named Queries**:
   - `create-table`: Generates ALB access logs table structure
   - `http-get-requests`: Counts HTTP GET requests grouped by source IP

---

#### [ssogen-athena-query-execution.tf](ssogen-athena-query-execution.tf)
**Purpose**: Automatically executes Athena table creation queries

**Execution**:
- Triggers via `null_resource` after Athena resources are created
- Assumes IAM role: `MemberInfrastructureAccess`
- Executes queries for both main ALB and console ALB logs
- Queries:
  - Main ALB table creation
  - Console ALB table creation
  - HTTP GET request analysis for both ALBs

**Result**: Access logs are automatically queryable immediately after deployment

---

### Web Application Firewall

#### [ssogen-waf.tf](ssogen-waf.tf)
**Purpose**: AWS WAF protection for console ALB

**WAF Configuration**:

1. **IP Set** (`ssogen_console_waf_ip_set`):
   - Name: `{application_name}-console-waf-ip-set`
   - Scope: REGIONAL
   - IP Version: IPv4
   - Whitelisted IPs: AWS WorkSpaces CIDR blocks (`lz_aws_workspace_nonprod_prod`)
   - Only allowed sources can access console

2. **Web ACL** (`ssogen_console_web_acl`):
   - Name: `{application_name}-console-web-acl`
   - Scope: REGIONAL
   - Description: AWS WAF Web ACL for SSOGEN Console ALB
   
   **Rules**:
   - **Priority 1**: AWS Managed Rules - Common Rule Set
     - Vendor: AWS
     - Override action: none (enforces rules)
     - Blocks common web exploits and attacks
     - CloudWatch metrics enabled
   
   - **Priority 2**: IP Whitelist Rule
     - Action: ALLOW
     - References: IP set (`ssogen_console_waf_ip_set`)
     - Allows traffic only from trusted IPs
     - Visibility: CloudWatch metrics enabled
   
   **Default Action**: BLOCK (deny all traffic by default)

3. **WAF Logging**:
   - **Log Group** (`ssogen_console_waf_logs`):
     - Name: `aws-waf-logs-ssogen/ssogen-console-waf-logs`
     - Retention: 30 days
     - Tracks all WAF actions and blocked requests

4. **Visibility Configuration**:
   - CloudWatch metrics: enabled for all rules
   - Sampled requests: enabled for troubleshooting
   - Metric names: Rule-specific (e.g., AWS-AWSManagedRulesCommonRuleSet, {app}-console-waf-ip-set)

**Applied To**: Console ALB only (main ALB has no WAF)

**Security Model**: 
- Default-deny policy with explicit whitelist
- Protects console from unauthorized access and web attacks
- Only AWS WorkSpaces users can reach console

---

### EFS Security

#### [ssogen-efs-sg.tf](ssogen-efs-sg.tf)
**Purpose**: Security group for EFS file system access

**Ingress Rules**:
- **NFS**: From all private subnets
  - Dynamically creates rules for each private subnet CIDR
  - Allows EC2 instances to mount EFS

**Egress Rules**:
- Allow all outbound traffic (0.0.0.0/0)

**Security**: NFS access isolated to private subnets only

---

## Auto-Scaling Configuration

Auto-Scaling Groups manage EC2 instance lifecycle for SSOGEN:

### Primary ASG (`ssogen-scaling-group-primary`)
- **Name**: `{application_name}-asg-primary`
- **Launch Template**: `ssogen-ec2-launch-template-primary`
- **Desired Capacity**: `ssogen_desired_capacity`
- **Min Size**: `ssogen_min_capacity`
- **Max Size**: `ssogen_max_capacity`
- **Target Groups**: 
  - Main application target group (`ssogen_internal_tg_ssogen_enc_app`)
  - Console target group (`ssogen_internal_tg_ssogen_console`)
- **Subnets**: All shared private subnets (spans all availability zones)

### Secondary ASG (`ssogen-scaling-group-secondary`)
- **Name**: `{application_name}-asg-secondary`
- **Launch Template**: `ssogen-ec2-launch-template-secondary`
- **Same configuration** as primary ASG
- **Separate AMI ID**: Uses `ssogen_ami_id-2` instead of `ssogen_ami_id-1`

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS WorkSpaces CIDR                          │
│                 (Allowed via WAF & SG)                          │
└────────────────────────────┬──────────────────────────────────────┘
                             │ HTTPS/443
                    ┌────────┴────────┐
                    │   Route53 DNS   │
          ┌─────────┤  (ccmsebs-sso) │──────────┐
          │         │ (ccmsebs-sso-  │          │
          │         │    admin)       │          │
          │         └─────────────────┘          │
          │                                      │
    ┌─────┴─────┐                         ┌─────┴──────┐
    │   Main ALB │                         │ Console ALB │
    │ (internal) │                         │ (internal)  │
    └─────┬─────┘                         └─────┬───────┘
          │                                      │
    ┌─────┴──────────────────────┬──────────────┴─────┐
    │       TG: enc-app          │  TG: console      │
    │       Port: 443/HTTPS      │  Port: 443/HTTPS  │
    │       Sticky: enabled      │  Sticky: disabled │
    └─────┬──────────────────────┴──────────────┬────┘
          │                                      │
    ┌─────────────────────┬───────────────────────────┐
    │   EC2 Instance: as1 │   EC2 Instance: as2      │
    ├─────────────────────┼───────────────────────────┤
    │ WebLogic 12c        │  WebLogic 12c            │
    │ OHS (Oracle HTTP)   │  OHS (Oracle HTTP)       │
    │ Volumes: /u01-/u04  │  Volumes: /u01-/u04      │
    │ EFS Mount: shared   │  EFS Mount: shared       │
    └─────────────────────┴───────────────────────────┘
          │                                      │
          └──────────────┬───────────────────────┘
                         │
                    ┌────┴──────┐
                    │    EFS    │
                    │  (shared) │
                    └───────────┘
```

---

## Configuration Parameters (from application_data)

The following parameters must be defined in your Terraform variables/locals:

```hcl
local.application_data.accounts[local.environment] = {
  # EC2 Configuration
  ec2_oracle_instance_type_ssogen        = "r5.2xlarge"      # Instance type
  ssogen_ami_id-1                         = "ami-primary"     # Primary AMI
  ssogen_ami_id-2                         = "ami-secondary"   # Secondary AMI
  ec2_disk_size_ssogen                    = 100              # Root volume GB
  ec2_disk_size_ssogen_fmw                = 50               # Framework volume GB
  ec2_disk_size_ssogen_mserver            = 200              # Managed server volume GB
  ec2_disk_size_ssogen_temp               = 100              # Temp volume GB
  
  # Scaling
  ssogen_desired_capacity                 = 2                # Initial instances
  ssogen_min_capacity                     = 2                # Minimum instances
  ssogen_max_capacity                     = 4                # Maximum instances
  
  # Load Balancer
  tg_ssogen_apps_enc_port                 = 443             # App traffic port
  tg_ssogen_admin_enc_port                = 7001            # Admin traffic port
  
  # EFS
  ssogen_efs_performance_mode              = "generalPurpose" # or "maxIO"
  
  # Security
  lz_aws_workspace_nonprod_prod           = "10.200.0.0/19"    # WorkSpaces CIDR

}
```

---

| File | Purpose | Key Components | Status |
|------|---------|----------------|--------|
| ssogen-ec2.tf | Launch templates, instances, ASGs | User data templates, launch configs, ASGs (primary/secondary) | Active |
| ssogen-storage.tf | EFS file system | File system, mount targets (3 AZs) | Active |
| ssogen-load-balancer.tf | ALBs, target groups, listeners | 2 ALBs, 2 TGs, 2 listeners, HTTPS, sticky sessions | Active |
| ssogen-lb-sg.tf | ALB security groups | 2 SGs, HTTPS/443 ingress from WorkSpaces | Active |
| ssogen-ec2-sg.tf | EC2 security groups | 1 SG, port 443 from WorkSpaces, commented rules | Under Review |
| ssogen-r53.tf | DNS records | Alias records for ALBs, A records for instances | Active |
| ssogen-iam.tf | IAM roles & policies | EC2 role, instance profile, SSM managed policy, KMS alias | Active |
| ssogen-key.tf | KMS keys & SSH keys | TLS key pair, 2 KMS keys, KMS aliases, policies | Active |
| ssogen-secrets.tf | Secrets management | Account IDs secret (dev/preprod/prod) | Active |
| ssogen-cloudwatch.tf | Logs, metrics, alarms | Log groups, SSM parameter, 5xx alarm, more alarms expandable | Active |
| ssogen-athena.tf | Log analysis | Database, workgroup, named queries (main & console) | Active |
| ssogen-athena-query-execution.tf | Query automation | Null resource executing Athena queries | Active |
| ssogen-waf.tf | Web application firewall | IP set, Web ACL, 2 rules (managed + IP whitelist), CloudWatch logs | Active |
| ssogen-efs-sg.tf | EFS security | 1 SG, NFS port 2049 from all private subnets | Active |

---

## Deployment Considerations

### Prerequisites
1. **VPC & Subnets**: Modernisation Platform VPC with private subnets required
2. **Application Data**: Environment-specific configuration in locals (AMI IDs, instance types, etc.)
3. **Secrets**: Account IDs pre-populated in Secrets Manager
4. **IAM**: Sufficient permissions to assume `MemberInfrastructureAccess` role

### Enable SSOGEN
Set in environment-specific configuration:
```hcl
local.ssogen_enabled = true
```

### Deployment Order
1. Secrets & KMS (key.tf, secrets.tf)
2. Networking (security groups: ec2-sg.tf, lb-sg.tf, efs-sg.tf)
3. Storage (storage.tf)
4. Compute (ec2.tf)
5. Load Balancing (load-balancer.tf)
6. DNS & Routing (r53.tf)
7. Monitoring (cloudwatch.tf, athena.tf)
8. WAF (waf.tf)

### Terraform State
All resources use `local.ssogen_enabled` conditional logic - safe to disable/enable without destroying infrastructure (if resources are already created).

---

## Monitoring and Observability

### CloudWatch Logs
Monitor application behaviour via log groups:
- `/aws/ssogen/admin-server`: WebLogic AdminServer logs
- `/aws/ssogen/ohs`: Oracle HTTP Server logs
- `/aws/ssogen/managed-server`: Managed server logs
- `aws-waf-logs-ssogen/ssogen-console-waf-logs`: WAF logs for console access attempts (30-day retention)

### CloudWatch Alarms
- **5xx Error Alarm** (`{application_name}-{environment}-5xx-errors`):
  - Metric: HTTPCode_ELB_5XX_Count
  - Threshold: > 10 errors
  - Evaluation period: 3 minutes (3 periods × 60 seconds)
  - Indicates application server or backend issues
  - Triggers when ALB encounters 5xx errors from targets

### CloudWatch Metrics
- **ALB Metrics**: RequestCount, TargetResponseTime, HTTPCode_Target_5XX_Count
- **WAF Metrics**: Enabled per rule (Common Rule Set, IP whitelist rule)
- **EC2 Metrics**: CPU utilization, network I/O, disk I/O via detailed monitoring
- **Target Health**: Active connection count, request count, latency

### Athena Queries
Query load balancer access logs:
```sql
-- Count HTTP requests by source IP
SELECT client_ip, COUNT(*) as request_count 
FROM ssogen_loadbalancer_access_logs 
GROUP BY client_ip 
ORDER BY request_count DESC;

-- Check response codes distribution
SELECT http_code, COUNT(*) as count 
FROM ssogen_loadbalancer_access_logs 
GROUP BY http_code 
ORDER BY count DESC;
```

### Health Checks
- **ALB Target Health**: 
  - Path: `/`
  - Protocol: HTTPS
  - Expected: HTTP 200
  - Interval: 30 seconds
  - Failed after 3 consecutive failures
- Unhealthy targets automatically removed from load balancer
- DNS failover enables failover to healthy instances via Route53

---

## Common Tasks

### Accessing SSOGEN Services

**Main Application** (OHS):
1. From AWS WorkSpaces in allowed CIDR block
2. Navigate to: `https://ccmsebs-sso` (or instance record: `ccms-{app-name}-as1.{business-unit}-{environment}.modernisation-platform.service.justice.gov.uk`)
3. Port: 443 (HTTPS)
4. Routed through main ALB → EC2 instances → OHS

**Admin Console** (WebLogic):
1. From AWS WorkSpaces in allowed CIDR block
2. Navigate to: `https://ccmsebs-sso-admin`
3. Port: 443 (HTTPS)
4. WAF checks source IP against whitelist
5. Routed through console ALB → EC2 instances → WebLogic AdminServer
6. Target port: `tg_ssogen_admin_enc_port` (from application data


### Retrieving Access Logs
```bash
# Query ALB access logs via Athena
aws athena start-query-execution \
  --query-string "SELECT * FROM ssogen_loadbalancer_access_logs LIMIT 10" \
  --work-group ssogen-lb-access-logs \
  --query-execution-context Database=ssogen_loadbalancer_access_logs

# Check WAF logs
aws logs tail aws-waf-logs-ssogen/ssogen-console-waf-logs --follow
```

### Scaling Instances
- Modify desired/max/min capacity in `local.application_data.accounts[local.environment]`
- Or use AWS Console: ASG → Edit group → modify desired capacity
- New instances deployed with latest launch template
- Old instances terminate when capacity reduced

### Updating Security Groups
- Edit ingress/egress rules in:
  - `ssogen-ec2-sg.tf`: EC2 instance rules
  - `ssogen-lb-sg.tf`: Load balancer rules
  - `ssogen-efs-sg.tf`: EFS mount rules
- Apply changes: `terraform apply`
- Changes take effect immediately

### SSL Certificate Management
- Certificates from `data.aws_acm_certificate.external_ssogen` (external certificate)
- ALB listeners use: `ELBSecurityPolicy-TLS13-1-2-2021-06` (modern TLS only)
- Certificate validation required before listener can serve traffic

---

## Troubleshooting

### 5xx Errors on ALB
1. Check ALB listener configuration and target group health status:
   ```bash
   aws elbv2 describe-target-health --target-group-arn <arn>
   ```
2. Review CloudWatch logs for errors:
   ```bash
   aws logs get-log-events --log-group-name /aws/ssogen/managed-server
   ```
3. SSH to instance and check WebLogic server status:
   ```bash
   tail -f /u01/product/runtime/Domain/mserver/domains/EAGDomain/servers/WLS_EAG1/logs
   ```
4. Verify security group rules between ALB and EC2:
   ```bash
   aws ec2 describe-security-groups --group-ids <sg-id>
   ```
5. Check certificate validation:
   ```bash
   aws elbv2 describe-listeners --load-balancer-arn <arn>
   ```

### DNS Not Resolving
1. Verify Route53 records exist:
   ```bash
   aws route53 list-resource-record-sets --hosted-zone-id <zone-id> | grep ccmsebs-sso
   ```
2. Check alias targets point to correct ALB:
   ```bash
   aws route53 list-resource-record-sets --hosted-zone-id <zone-id> | grep ccms-ssogen
   ```
3. Verify ALB is healthy:
   ```bash
   aws elbv2 describe-load-balancers --names lb-ssogen-internal
   ```
4. Test DNS resolution:
   ```bash
   nslookup ccmsebs-sso.{business-unit}-{environment}.modernisation-platform.service.justice.gov.uk
   ```

### WAF Blocking Traffic
1. Check WAF logs:
   ```bash
   aws logs tail aws-waf-logs-ssogen/ssogen-console-waf-logs --follow
   ```
2. Verify source IP is whitelisted in IP set:
   ```bash
   aws wafv2 get-ip-set --name ssogen-console-waf-ip-set --scope REGIONAL
   ```
3. Check your current IP:
   ```bash
   curl https://checkip.amazonaws.com
   # Or get from CloudWatch logs
   aws logs filter-log-events --log-group-name aws-waf-logs-ssogen/ssogen-console-waf-logs
   ```
4. Add IP to whitelist if needed:
   ```bash
   # Update application data with new WorkSpaces CIDR
   # Redeploy: terraform apply
   ```
5. Review AWS Managed Rules violations:
   ```bash
   # Check specific rule metrics in CloudWatch
   aws cloudwatch get-metric-statistics --metric-name AWS-AWSManagedRulesCommonRuleSet \
     --namespace AWS/WAFV2 --start-time <time> --end-time <time>
   ```

### Certificate Issues
1. Check certificate status and expiration:
   ```bash
   aws acm describe-certificate --certificate-arn <arn>
   ```
2. Verify certificate validation records (if DNS validation):
   ```bash
   aws acm describe-certificate --certificate-arn <arn> --query 'Certificate.DomainValidationOptions'
   ```
3. Check listener SSL policy compatibility:
   ```bash
   # ELBSecurityPolicy-TLS13-1-2-2021-06 requires TLS 1.2+
   openssl s_client -connect ccmsebs-sso.internal:443 -tls1_2
   ```

---

## References

- [Modernisation Platform Terraform Style Guide](https://user-guide.modernisation-platform.service.justice.gov.uk/team/terraform-style-guide)
- [AWS WebLogic on EC2](https://docs.oracle.com/en/cloud/paas/weblogic-cloud/aws/)
- [AWS WAF Documentation](https://docs.aws.amazon.com/waf/)
- [Amazon EFS Best Practices](https://docs.aws.amazon.com/efs/latest/ug/best-practices.html)

---

## Support & Contributions

For issues, feature requests, or contributions related to SSOGEN infrastructure, please refer to the main [CONTRIBUTING.md](../../CONTRIBUTING.md) guide and the Modernisation Platform standards.
