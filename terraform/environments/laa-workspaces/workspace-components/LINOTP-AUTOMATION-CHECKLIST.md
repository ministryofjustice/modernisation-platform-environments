# LinOTP Automation - Deployment Checklist

Quick reference for deploying automated LinOTP configuration.

## ✅ Pre-Deployment Checklist

- [ ] Review `LINOTP-AUTOMATION.md` for detailed setup instructions
- [ ] Verify AWS Managed Microsoft AD is deployed and healthy
- [ ] Verify `lambda.workspace` service account exists in AD (already created for user-creation.ps1)
- [ ] Confirm ECS cluster and service are running
- [ ] Confirm RDS MySQL instance is accessible

## 📋 Deployment Steps

### 1. Deploy Terraform Changes

```bash
cd terraform/environments/laa-workspaces/workspace-components

# Add new files
git add new-adds-linotp-svc.tf
git add new-ecs-linotp3.tf  # Updated with AD config
git add dockerfiles/linotp3/configure_linotp.py
git add dockerfiles/linotp3/entrypoint.sh  # Updated
git add dockerfiles/linotp3/Dockerfile  # Updated
git add LINOTP-AUTOMATION.md
git add LINOTP-AUTOMATION-CHECKLIST.md

git commit -m "Add LinOTP automated configuration for AD integration

- Python script configures LDAP resolver, realms, and policies via API
- Runs automatically on container startup
- Creates AD service account secret in Secrets Manager
- Updates ECS task definition with AD configuration
- Fully idempotent - safe to run multiple times

See LINOTP-AUTOMATION.md for setup guide"

git push origin <branch-name>
```

**Wait for GitHub Actions workflow to complete** ⏳

### 2. Verify Terraform Deployment

```bash
# Check secret was created (mirrors lambda.workspace password from SSM)
aws secretsmanager describe-secret \
  --secret-id laa-workspaces/development/linotp-ad-bind-password \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager

# Verify it matches SSM parameter
aws ssm get-parameter \
  --name /laa-workspaces/development/ad-service-account-password \
  --with-decryption \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager
```

```bash
cd dockerfiles/linotp3

# Authenticate to ECR
aws ecr get-login-password --region eu-west-2 --profile mp-workspaces-dev \
  | docker login --username AWS --password-stdin 945484575162.dkr.ecr.eu-west-2.amazonaws.com

# Build
docker build --platform linux/amd64 -t laa-workspaces/linotp3 .

# Tag
docker tag laa-workspaces/linotp3:latest \
  945484575162.dkr.ecr.eu-west-2.amazonaws.com/laa-workspaces/linotp3:latest

# Push
docker push 945484575162.dkr.ecr.eu-west-2.amazonaws.com/laa-workspaces/linotp3:latest
```

### 3. Build and Push Docker Image

```bash
aws ecs update-service \
  --cluster laa-workspaces-development \
  --service laa-workspaces-development-linotp3 \
  --force-new-deployment \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager
```

### 4. Deploy to ECS

Watch CloudWatch Logs for configuration progress:

```bash
aws logs tail /aws/ecs/laa-workspaces-development-linotp3 \
  --since 5m \
  --follow \
  --region eu-west-2 \
  --profile mp-workspaces-dev | grep -E "(LinOTP|LDAP|Realm|Policy|✅)"
```

**Expected log output:**
```
Starting LinOTP automated configuration...
Waiting for LinOTP at http://localhost:5000...
LinOTP is ready
Configuration validated
--- Step 1: LDAP Resolver ---
Creating LDAP resolver 'ad-resolver'...
LDAP resolver 'ad-resolver' created successfully
--- Step 2: Realm Configuration ---
Creating realm 'laa-workspaces'...
Realm 'laa-workspaces' created successfully
Setting 'laa-workspaces' as default realm...
Default realm set to 'laa-workspaces'
--- Step 3: Policy Configuration ---
Creating authentication policy 'radius_auth'...
Authentication policy 'radius_auth' created successfully
Creating enrollment policy 'self_enrollment'...
Enrollment policy 'self_enrollment' created successfully
Creating self-service policy 'selfservice_portal'...
Self-service policy 'selfservice_portal' created successfully
✅ LinOTP configuration completed successfully
```

### 5. Monitor Deployment

```bash
# Open portal
open https://workspace-mfa-ecs.laa-development.modernisation-platform.service.justice.gov.uk/manage
```

**Login credentials:**
```
Username: admin
Password: (get from Secrets Manager)
```

```bash
aws secretsmanager get-secret-value \
  --secret-id laa-workspaces-development-linotp-admin-* \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --query SecretString \
  --output text \
  --no-cli-pager
```

**Verify in portal:**
- [ ] Navigate to **Config > UserIdResolvers** → See "ad-resolver" (Active)
- [ ] Navigate to **Config > Realms** → See "laa-workspaces" (default)
- [ ] Navigate to **Config > Policies** → See 3 policies

### 6. Verify Configuration in Portal

1. Navigate to self-service portal:
   ```
   https://workspace-mfa-ecs.laa-development.modernisation-platform.service.justice.gov.uk/selfservice
   ```

2. Login as AD user (e.g., test user from your domain)

3. Enroll HOTP or TOTP token

4. Test authentication

### 7. Test Token Enrollment

### Configuration Failed - Check Logs

```bash
aws logs filter-log-events \
  --log-group-name /aws/ecs/laa-workspaces-development-linotp3 \
  --start-time $(date -u -d '10 minutes ago' +%s)000 \
  --filter-pattern "ERROR" \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager
```

### LDAP Connection Issues

Test from ECS container:
```bash
# Get task ID
TASK_ID=$(aws ecs list-tasks \
  --cluster laa-workspaces-development \
  --service laa-workspaces-development-linotp3 \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --query 'taskArns[0]' \
  --output text | awk -F'/' '{print $NF}')

# Test DNS resolution
aws ecs execute-command \
  --cluster laa-workspaces-development \
  --task $TASK_ID \
  --container linotp \
  --command "nslookup laa-workspaces.local" \
  --interactive \
  --region eu-west-2 \
  --profile mp-workspaces-dev
```

### AD Service Account Issues

Verify `lambda.workspace` account exists and is enabled:
```powershell
Get-ADUser -Identity "lambda.workspace" -Properties Enabled,PasswordNeverExpires
```

Test authentication with the service account:
```powershell
# Get password from SSM
$password = (Get-SSMParameterValue -Name "/laa-workspaces/development/ad-service-account-password" -WithDecryption $true -Region eu-west-2).Parameters[0].Value
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("LAAWORKSPACES\lambda.workspace", $securePassword)

# This should succeed
Get-ADUser -Identity "Administrator" -Credential $credential
```

### Restart Configuration

If configuration failed and you need to retry:

```bash
# Disable automation temporarily
# Edit task definition, set ENABLE_AUTO_CONFIG=false
# Deploy

# Fix the issue (e.g., create AD account)

# Re-enable automation
# Edit task definition, set ENABLE_AUTO_CONFIG=true
# Deploy
```

## 📝 Post-Deployment

- [ ] Update LINOTP-ECS-DEPLOYMENT.md status
- [ ] Document any environment-specific changes
- [ ] Test RADIUS authentication via NLB
- [ ] Configure WorkSpaces Directory to use LinOTP RADIUS
- [ ] Set up monitoring and alerting
- [ ] Plan production rollout

## 🔗 Related Documentation

- **LINOTP-AUTOMATION.md** - Comprehensive automation guide
- **LINOTP-ECS-DEPLOYMENT.md** - Deployment architecture and status
- **dockerfiles/README.md** - Docker build instructions

---

**Last Updated**: 2026-07-10  
**Environment**: Development  
**Status**: Ready for deployment
