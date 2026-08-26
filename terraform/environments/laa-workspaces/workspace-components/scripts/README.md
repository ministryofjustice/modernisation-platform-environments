# RADIUS Server Installation Scripts

This directory contains user data scripts for deploying different RADIUS server solutions.

## Available Scripts

### 1. install-duo-proxy.sh (Recommended)

**Use Case:** Best for most organizations, especially those new to RADIUS/MFA

**What it installs:**
- Duo Authentication Proxy
- CloudWatch agent for logging
- AWS CLI for secrets retrieval

**Requirements:**
- Duo account (free for <10 users)
- Duo application created
- Integration key, secret key, and API hostname

**Pros:**
- ✅ Easiest to set up
- ✅ Cloud-managed MFA (no token management)
- ✅ Multiple MFA methods (push, SMS, phone call)
- ✅ Good documentation and support

**Setup Steps:**
1. Sign up at [https://signup.duo.com/](https://signup.duo.com/)
2. Create a RADIUS application in Duo Admin
3. Note the integration key, secret key, and API hostname
4. Add these to `application_variables.json` or Terraform variables
5. Uncomment the EC2 instances in `new-adds-radius-server.tf`
6. Update `user_data` to use this script
7. Deploy with `terraform apply`

**Cost:** Free for <10 users, then $3-6/user/month

---

### 2. install-freeradius.sh

**Use Case:** Organizations wanting open-source solution with TOTP (Google Authenticator)

**What it installs:**
- FreeRADIUS server
- Google Authenticator PAM module
- CloudWatch agent for logging
- AWS CLI for secrets retrieval

**Requirements:**
- None (all open source)
- Users need Google Authenticator app on phones

**Pros:**
- ✅ No licensing costs
- ✅ Full control over configuration
- ✅ Works with Google Authenticator, Authy, etc.

**Cons:**
- ❌ More complex user enrollment
- ❌ Self-managed (no vendor support)
- ❌ Users need to save backup codes

**Setup Steps:**
1. Uncomment the EC2 instances in `new-adds-radius-server.tf`
2. Update `user_data` to use this script
3. Deploy with `terraform apply`
4. SSH to RADIUS server
5. For each user:
   ```bash
   useradd username
   passwd username
   su - username
   google-authenticator  # Follow prompts
   ```
6. Users scan QR code with Google Authenticator app

**Cost:** ~$30/month (EC2 instances only)

---

## Deployment Process

### Step 1: Choose Your RADIUS Solution

Pick either Duo or FreeRADIUS based on your needs.

### Step 2: Update new-adds-radius-server.tf

Uncomment the `aws_instance.radius_server` resource:

```hcl
resource "aws_instance" "radius_server" {
  count = local.environment == "development" ? 2 : 0  # 2 for HA
  
  # ... other settings ...
  
  user_data = templatefile("${path.module}/scripts/install-duo-proxy.sh", {
    # OR
    # user_data = templatefile("${path.module}/scripts/install-freeradius.sh", {
    region            = "eu-west-2"
    radius_secret_arn = aws_secretsmanager_secret.radius_shared_secret[0].arn
    environment       = local.environment
    # For Duo only:
    # duo_integration_key = var.duo_integration_key
    # duo_secret_key      = var.duo_secret_key
    # duo_api_hostname    = var.duo_api_hostname
  })
}
```

### Step 3: Add Duo Variables (if using Duo)

Add to `application_variables.json`:

```json
{
  "accounts": {
    "development": {
      "duo_integration_key": "DI...",
      "duo_secret_key": "stored-in-secrets-manager",
      "duo_api_hostname": "api-xxxxxx.duosecurity.com"
    }
  }
}
```

Or create Terraform variables in `variables.tf`.

### Step 4: Deploy

```bash
cd terraform/environments/laa-workspaces
terraform workspace select laa-workspaces-development
terraform plan
terraform apply
```

### Step 5: Update RADIUS Configuration

After deployment, update `new-adds-radius.tf`:

```hcl
# Change from:
radius_servers = [
  # "10.200.1.10",
  # "10.200.2.10",
]

# To:
radius_servers = [for instance in aws_instance.radius_server : instance.private_ip]

# And add to depends_on:
depends_on = [
  aws_directory_service_directory.workspaces_ad,
  aws_instance.radius_server,
]
```

Apply again:
```bash
terraform apply
```

### Step 6: Test

```bash
# Get RADIUS server IP
terraform output radius_server_private_ips

# SSH to RADIUS server (via SSM Session Manager)
aws ssm start-session --target i-xxxxxxxxx

# Test RADIUS
# For Duo:
radtest username password localhost:1812 1 shared-secret

# For FreeRADIUS with Google Authenticator:
radtest username 'password123456' localhost:1812 1 testing123
# (where 123456 is the 6-digit token from Google Authenticator)
```

---

## Troubleshooting

### Duo Proxy Not Starting

```bash
# Check logs
tail -f /opt/duoauthproxy/log/authproxy.log

# Common issues:
# - Invalid Duo credentials
# - Network connectivity to api-*.duosecurity.com
# - Configuration file syntax errors
```

### FreeRADIUS Not Starting

```bash
# Check logs
tail -f /var/log/radius/radius.log

# Run in debug mode
radiusd -X

# Common issues:
# - Port 1812 already in use
# - Invalid clients.conf configuration
# - PAM authentication not configured
```

### Can't Connect from Microsoft AD

1. Check security group allows UDP 1812 from VPC CIDR
2. Verify RADIUS server is in same VPC as Microsoft AD
3. Test with `radtest` from another instance in same VPC
4. Check RADIUS shared secret matches in both places

---

## Monitoring

Both scripts install CloudWatch agent. Logs are sent to:

```
/aws/ec2/laa-workspaces-{environment}/radius/
```

Monitor:
- Authentication success/failure rates
- RADIUS response times
- Server CPU/memory usage
- Error logs

---

## Security Best Practices

1. **Secrets Management:**
   - Store Duo keys in AWS Secrets Manager
   - Rotate RADIUS shared secret periodically
   - Never commit secrets to git

2. **Network Security:**
   - RADIUS servers in private subnets only
   - No direct internet access (NAT Gateway for updates)
   - Security group allows only necessary ports

3. **High Availability:**
   - Deploy 2 instances in different AZs
   - Use both IPs in `radius_servers` list
   - Monitor both instances with CloudWatch alarms

4. **User Management:**
   - Regular audits of enrolled users
   - Disable MFA for terminated employees
   - Test MFA enrollment process regularly

---

## References

- [Duo Authentication Proxy Documentation](https://duo.com/docs/authproxy-reference)
- [FreeRADIUS Documentation](https://freeradius.org/documentation/)
- [Google Authenticator PAM](https://github.com/google/google-authenticator-libpam)
- [AWS Directory Service RADIUS](https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_mfa.html)
