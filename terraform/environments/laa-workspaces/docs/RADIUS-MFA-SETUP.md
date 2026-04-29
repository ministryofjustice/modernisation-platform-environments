# RADIUS MFA Setup Guide for WorkSpaces

## Overview

This guide covers setting up RADIUS-based Multi-Factor Authentication (MFA) for AWS WorkSpaces using AWS Managed Microsoft AD.

## Architecture

```
User Login Attempt
       ↓
WorkSpaces Client
       ↓
AWS WorkSpaces Service
       ↓
AWS Managed Microsoft AD
       ↓
RADIUS Server (MFA Validation)
       ↓
MFA Provider (e.g., Duo, Azure MFA, etc.)
```

## Prerequisites

1. ✅ AWS Managed Microsoft AD deployed
2. ✅ WorkSpaces directory registered
3. ❌ RADIUS server deployed (required)
4. ❌ MFA provider configured (required)

## RADIUS Server Options

### Option 1: Duo Security (Recommended)

**Pros:**
- Easy integration with AWS
- Cloud-based, no server maintenance
- Supports multiple MFA methods (push, SMS, phone call)
- Free for up to 10 users

**Setup:**
1. Sign up for Duo account
2. Deploy Duo Authentication Proxy on EC2 instances
3. Configure proxy to connect to Duo cloud service
4. Point AWS Directory Service RADIUS settings to proxy

**Terraform resources needed:**
- EC2 instances for Duo Authentication Proxy (2 for HA)
- Auto Scaling Group (optional)
- Security groups
- Application Load Balancer (optional)

### Option 2: Azure MFA with NPS Extension

**Pros:**
- Native integration if using Azure AD
- Supports existing Azure MFA policies
- Good for organizations already using Microsoft ecosystem

**Cons:**
- Requires Windows Server for Network Policy Server (NPS)
- More complex setup

**Setup:**
1. Deploy Windows Server EC2 instances
2. Install Network Policy Server (NPS) role
3. Install Azure MFA NPS extension
4. Configure RADIUS client settings

### Option 3: FreeRADIUS with Time-based OTP

**Pros:**
- Open-source, no licensing costs
- Full control over configuration
- Supports Google Authenticator, etc.

**Cons:**
- Requires more technical expertise
- Self-managed infrastructure

## Implementation Steps

### Phase 1: Deploy RADIUS Server

Choose one of the options above and deploy:

#### Example: Duo Authentication Proxy on EC2

```hcl
# new-adds-radius-server.tf

resource "aws_instance" "duo_proxy" {
  count = 2 # For high availability

  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.small"
  subnet_id     = data.terraform_remote_state.workspace_components.outputs.private_subnet_ids[count.index]
  
  vpc_security_group_ids = [aws_security_group.radius_server[0].id]
  iam_instance_profile   = aws_iam_instance_profile.radius_server[0].name

  user_data = templatefile("${path.module}/scripts/install-duo-proxy.sh", {
    duo_ikey  = var.duo_integration_key
    duo_skey  = var.duo_secret_key
    duo_host  = var.duo_api_hostname
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-${local.environment}-duo-proxy-${count.index + 1}"
    }
  )
}

resource "aws_security_group" "radius_server" {
  count = local.environment == "development" ? 1 : 0

  name_prefix = "${local.application_name}-${local.environment}-radius-"
  description = "Security group for RADIUS server"
  vpc_id      = data.terraform_remote_state.workspace_components.outputs.vpc_id

  # Allow RADIUS from Microsoft AD
  ingress {
    from_port   = 1812
    to_port     = 1812
    protocol    = "udp"
    cidr_blocks = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
    description = "RADIUS authentication"
  }

  # Allow RADIUS accounting (optional)
  ingress {
    from_port   = 1813
    to_port     = 1813
    protocol    = "udp"
    cidr_blocks = [data.terraform_remote_state.workspace_components.outputs.vpc_cidr_block]
    description = "RADIUS accounting"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-radius-sg" }
  )
}
```

### Phase 2: Configure RADIUS Settings

1. Update `new-adds-radius.tf`:
   - Replace the placeholder `radius_servers` with your actual RADIUS server IPs
   - Ensure the shared secret is securely stored

2. Update the configuration:

```hcl
radius_servers = [
  aws_instance.duo_proxy[0].private_ip,  # Primary
  aws_instance.duo_proxy[1].private_ip,  # Secondary
]
```

### Phase 3: Test RADIUS Connectivity

Before deploying, test RADIUS:

```bash
# From a management instance or bastion
radtest username password radius-server-ip:1812 1 shared-secret
```

### Phase 4: Enable MFA on WorkSpaces Directory

Once RADIUS is configured, the `aws_directory_service_radius_settings` resource will:
- Link Microsoft AD to RADIUS server
- Enable MFA for WorkSpace logins
- Users will be prompted for MFA token after entering AD password

## User Experience

1. User opens WorkSpaces client
2. Enters AD username and password
3. Prompted for MFA token/approval
4. If approved, WorkSpace launches

## RADIUS Configuration Details

| Setting | Value | Description |
|---------|-------|-------------|
| `radius_port` | 1812 | Standard RADIUS authentication port |
| `radius_timeout` | 5 seconds | How long to wait for RADIUS response |
| `radius_retries` | 3 | Number of retry attempts |
| `authentication_protocol` | MS-CHAPv2 | Microsoft-compatible protocol |
| `display_label` | MFA | Label shown to users during login |
| `use_same_username` | true | Use AD username for RADIUS auth |

## Security Considerations

1. **Shared Secret**: Stored in AWS Secrets Manager, not in Terraform state
2. **RADIUS Servers**: Deployed in private subnets, no internet access
3. **High Availability**: Deploy 2+ RADIUS servers in different AZs
4. **Monitoring**: Set up CloudWatch alarms for RADIUS server health
5. **Backup**: Regular backups of RADIUS configuration

## Cost Estimation (Monthly)

### Option 1: Duo Security
- Duo Account: $3-6/user/month (or free for <10 users)
- EC2 instances (2x t3.small): ~$30/month
- **Total**: ~$30-60/month (plus per-user Duo costs)

### Option 2: Azure MFA
- Azure MFA: Included with Azure AD P1/P2
- Windows Server licenses: Bring your own or ~$50/month per instance
- EC2 instances (2x t3.medium): ~$60/month
- **Total**: ~$120-180/month

### Option 3: FreeRADIUS
- EC2 instances (2x t3.small): ~$30/month
- **Total**: ~$30/month (no licensing)

## Troubleshooting

### RADIUS authentication fails

1. Check security group rules allow UDP 1812
2. Verify RADIUS shared secret matches on both sides
3. Check RADIUS server logs
4. Ensure Microsoft AD can reach RADIUS servers
5. Test with `radtest` utility

### Users not prompted for MFA

1. Verify RADIUS settings are applied to directory
2. Check `aws_directory_service_radius_settings` resource status
3. Ensure RADIUS servers are healthy
4. Review CloudWatch Logs for directory service

### High latency during login

1. Check RADIUS timeout settings (reduce if needed)
2. Monitor RADIUS server performance
3. Verify network latency between AD and RADIUS
4. Consider adding more RADIUS servers

## Monitoring

Set up CloudWatch alarms for:

```hcl
resource "aws_cloudwatch_metric_alarm" "radius_server_health" {
  alarm_name          = "${local.application_name}-${local.environment}-radius-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "RADIUS server is unhealthy"
  
  dimensions = {
    InstanceId = aws_instance.duo_proxy[0].id
  }
}
```

## Next Steps

1. Choose RADIUS server option
2. Deploy RADIUS infrastructure
3. Configure MFA provider (Duo, Azure, etc.)
4. Update `radius_servers` in `new-adds-radius.tf`
5. Test RADIUS connectivity
6. Apply Terraform configuration
7. Test WorkSpace login with MFA
8. Document user enrollment process

## References

- [AWS Directory Service RADIUS Documentation](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_mfa.html)
- [Duo Authentication Proxy Documentation](https://duo.com/docs/authproxy-reference)
- [Azure MFA NPS Extension](https://docs.microsoft.com/en-us/azure/active-directory/authentication/howto-mfa-nps-extension)
- [FreeRADIUS Documentation](https://freeradius.org/documentation/)
