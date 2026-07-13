# LinOTP Automated Configuration

This document explains the automated LinOTP configuration system that runs after ECS deployment.

## ⚠️ Important: Deployment Order

**LinOTP requires Active Directory to be deployed first!**

The automated configuration connects to AD for LDAP queries, so:
1. **First:** Deploy Active Directory (parent module)
2. **Then:** Deploy LinOTP ECS (workspace-components) with `ENABLE_AUTO_CONFIG=false`
3. **Finally:** Enable auto-config by setting `ENABLE_AUTO_CONFIG=true` and redeploying

See **LINOTP-DEPLOYMENT-ORDER.md** for detailed deployment strategy.

## Overview

The automated configuration system eliminates manual LinOTP setup by:
- Creating LDAP resolver for Active Directory integration
- Creating and configuring realms
- Setting up authentication policies
- Configuring token enrollment policies
- Setting up self-service portal policies

**All configuration happens automatically** when the ECS task starts, making LinOTP immediately ready for use.

## Architecture

```
ECS Task Start
     ↓
entrypoint.sh (runs bootstrap)
     ↓
LinOTP starts (HTTP on :5000)
     ↓
configure_linotp.py (runs in background)
     ├── Waits for LinOTP API
     ├── Creates LDAP resolver
     ├── Creates realm
     ├── Sets default realm
     └── Creates policies
     ↓
LinOTP fully configured ✅
```

## Prerequisites

### ✅ Using Existing Service Account

**Good news!** LinOTP will use the existing `lambda.workspace` service account that's already deployed for user creation. No additional AD account creation is needed.

**Service Account Details:**
- Username: `lambda.workspace`
- Domain: `LAAWORKSPACES`
- Bind DN: `CN=lambda.workspace,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local`
- Password: Stored in SSM Parameter Store at `/laa-workspaces/development/ad-service-account-password`

This account already has the necessary permissions to read AD user objects, which is all LinOTP needs for LDAP authentication.

## Deployment Process

### 1. Deploy Terraform Changes

```bash
# From workspace-components directory
git add new-adds-linotp-svc.tf new-ecs-linotp3.tf
git commit -m "Add LinOTP automated configuration"
git push origin <branch-name>

# Wait for GitHub Actions workflow to complete
```

This creates:
- `laa-workspaces/development/linotp-ad-bind-password` secret
- Updated ECS task definition with AD config environment variables
- Updated IAM permissions for secrets access

### 2. Build and Push Docker Image

```bash
cd dockerfiles/linotp3

# Authenticate to ECR
aws ecr get-login-password --region eu-west-2 --profile mp-workspaces-dev \
  | docker login --username AWS --password-stdin 945484575162.dkr.ecr.eu-west-2.amazonaws.com

# Build with updated entrypoint and configuration script
docker build --platform linux/amd64 -t laa-workspaces/linotp3 .
docker tag laa-workspaces/linotp3:latest 945484575162.dkr.ecr.eu-west-2.amazonaws.com/laa-workspaces/linotp3:latest
docker push 945484575162.dkr.ecr.eu-west-2.amazonaws.com/laa-workspaces/linotp3:latest
```

### 2. Build and Push Docker Image

```bash
aws ecs update-service \
  --cluster laa-workspaces-development \
  --service laa-workspaces-development-linotp3 \
  --force-new-deployment \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager
```

### 3. Deploy New ECS Task

Watch CloudWatch Logs for configuration progress:

```bash
aws logs tail /aws/ecs/laa-workspaces-development-linotp3 \
  --since 5m \
  --follow \
  --region eu-west-2 \
  --profile mp-workspaces-dev
```

Look for:
```
Starting LinOTP automated configuration...
Waiting for LinOTP at http://localhost:5000...
LinOTP is ready
--- Step 1: LDAP Resolver ---
Creating LDAP resolver 'ad-resolver'...
LDAP resolver 'ad-resolver' created successfully
--- Step 2: Realm Configuration ---
Creating realm 'laa-workspaces'...
Realm 'laa-workspaces' created successfully
Setting 'laa-workspaces' as default realm...
--- Step 3: Policy Configuration ---
Creating authentication policy 'radius_auth'...
Creating enrollment policy 'self_enrollment'...
Creating self-service policy 'selfservice_portal'...
✅ LinOTP configuration completed successfully
```

### 4. Verify Configuration

```bash
# Login to LinOTP portal
open https://workspace-mfa-ecs.laa-development.modernisation-platform.service.justice.gov.uk/manage

# Credentials
Username: admin
Password: (from Secrets Manager: laa-workspaces-development-linotp-admin-*)

# Verify configuration
1. Navigate to Config > UserIdResolvers
   - Should see "ad-resolver" with status Active
2. Navigate to Config > Realms
   - Should see "laa-workspaces" as default realm
   - Should show "ad-resolver" assigned
3. Navigate to Config > Policies
   - Should see 3 policies: radius_auth, self_enrollment, selfservice_portal
```

## Configuration Details

### LDAP Resolver Configuration

```
Name: ad-resolver
Type: LDAP
URI: ldap://laa-workspaces.local:389
Base DN: DC=laa-workspaces,DC=local
Bind DN: CN=lambda.workspace,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local
User Filter: (&(sAMAccountName=%s)(objectClass=user))
Search Filter: (sAMAccountName=*)
Login Attribute: sAMAccountName
```

**Note:** Uses existing `lambda.workspace` service account - no new AD account required.

### Realm Configuration

```
Name: laa-workspaces
Resolvers: ad-resolver
Default Realm: Yes
```

### Policies

**Authentication Policy (radius_auth)**
- Scope: authentication
- Action: otppin=1 (PIN + OTP concatenation)
- Realm: laa-workspaces
- Users: * (all)

**Enrollment Policy (self_enrollment)**
- Scope: enrollment
- Action: maxtoken=5, tokenissuer=LAA WorkSpaces MFA
- Realm: laa-workspaces
- Users: * (all)

**Self-Service Policy (selfservice_portal)**
- Scope: selfservice
- Actions: enrollHMAC, setOTPPIN, setMOTPPIN, resync, disable, delete, history
- Realm: laa-workspaces
- Users: * (all)

## Environment Variables

The following environment variables control the automated configuration:

### Required (set in ECS task definition)
- `LINOTP_ADMIN_PASSWORD` - Admin password (from Secrets Manager)
- `AD_LDAP_URI` - LDAP URI (e.g., ldap://laa-workspaces.local:389)
- `AD_BASE_DN` - LDAP base DN (e.g., DC=laa-workspaces,DC=local)
- `AD_BIND_DN` - Service account DN
- `AD_BIND_PASSWORD` - Service account password (from Secrets Manager)

### Optional (set in ECS task definition with defaults)
- `LINOTP_URL` - LinOTP API URL (default: http://localhost:5000)
- `LINOTP_ADMIN_USER` - Admin username (default: admin)
- `LINOTP_RESOLVER_NAME` - Resolver name (default: ad-resolver)
- `LINOTP_REALM_NAME` - Realm name (default: laa-workspaces)
- `AD_USER_FILTER` - User filter (default: (&(sAMAccountName=%s)(objectClass=user)))
- `AD_SEARCH_FILTER` - Search filter (default: (sAMAccountName=*))
- `ENABLE_AUTO_CONFIG` - Enable automation (default: true, set to "false" to disable)

## Disabling Automation

To disable automated configuration and configure manually:

```bash
# Update ECS task definition environment variable
ENABLE_AUTO_CONFIG=false

# Force new deployment
aws ecs update-service \
  --cluster laa-workspaces-development \
  --service laa-workspaces-development-linotp3 \
  --force-new-deployment \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager
```

## Idempotency

The configuration script is **idempotent** - safe to run multiple times:
- Checks if resolver exists before creating
- Checks if realm exists before creating
- Checks if policies exist before creating
- Skips existing configuration, logs "already exists"

This means:
- ✅ Restarting the ECS task is safe
- ✅ Forcing new deployment is safe
- ✅ Configuration won't be duplicated

## Troubleshooting

### Configuration Not Running

Check CloudWatch Logs:
```bash
aws logs tail /aws/ecs/laa-workspaces-development-linotp3 \
  --since 10m \
  --filter-pattern "LinOTP" \
  --region eu-west-2 \
  --profile mp-workspaces-dev
```

### LDAP Connection Failures

Verify:
1. `lambda.workspace` service account exists and is enabled in AD
2. Service account password in SSM matches AD
3. AD is accessible from ECS tasks (check security groups)
4. Domain name resolves from ECS (should use AWS Managed AD DNS)

Verify service account:
```powershell
Get-ADUser -Identity "lambda.workspace" -Properties Enabled
```

Test DNS resolution:
```bash
# Get ECS task ID
TASK_ID=$(aws ecs list-tasks --cluster laa-workspaces-development --service laa-workspaces-development-linotp3 --region eu-west-2 --profile mp-workspaces-dev --query 'taskArns[0]' --output text | awk -F'/' '{print $NF}')

# Run command in container
aws ecs execute-command \
  --cluster laa-workspaces-development \
  --task $TASK_ID \
  --container linotp \
  --command "nslookup laa-workspaces.local" \
  --interactive \
  --region eu-west-2 \
  --profile mp-workspaces-dev
```

### API Authentication Failures

Check admin password:
```bash
aws secretsmanager get-secret-value \
  --secret-id laa-workspaces-development-linotp-admin-* \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --query SecretString \
  --output text \
  --no-cli-pager
```

### Configuration Timeout

If LinOTP takes too long to start:
- Check container health status
- Increase sleep delay in entrypoint.sh (currently 30s)
- Check CloudWatch Logs for startup errors

## Manual Configuration Override

If you need to reconfigure LinOTP manually:

1. Disable automation: `ENABLE_AUTO_CONFIG=false`
2. Login to portal
3. Delete existing resolver/realm/policies if needed
4. Recreate with custom settings

## Next Steps

After automated configuration completes:

1. **Enroll Test Token**
   - Login to self-service portal as AD user
   - Enroll HOTP/TOTP token
   - Test authentication

2. **Configure RADIUS Testing**
   - Test authentication via NLB
   - Configure WorkSpaces Directory to use LinOTP RADIUS

3. **Production Rollout**
   - Add production environment configuration
   - Update application_variables.json
   - Deploy to preproduction and production

## Files

### Docker
- `dockerfiles/linotp3/configure_linotp.py` - Configuration script
- `dockerfiles/linotp3/entrypoint.sh` - Updated entrypoint
- `dockerfiles/linotp3/Dockerfile` - Updated with requests library

### Terraform
- `new-adds-linotp-svc.tf` - AD service account secret
- `new-ecs-linotp3.tf` - Updated task definition with AD config

### Documentation
- `LINOTP-AUTOMATION.md` - This file
- `LINOTP-ECS-DEPLOYMENT.md` - Deployment status (update pending section)

## Support

For issues or questions:
- Check CloudWatch Logs first
- Review this documentation
- Check LinOTP 3.x documentation: https://linotp.org/doc/latest/
- Consult AWS Managed Microsoft AD documentation

---

**Document Version**: 1.0  
**Last Updated**: 2026-07-10  
**Status**: Ready for deployment
