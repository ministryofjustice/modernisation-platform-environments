# LinOTP Automated Configuration Guide

**Status**: ✅ Production Ready  
**Last Updated**: 2026-07-13

## Quick Start

```bash
# 1. Build and push Docker image
cd dockerfiles/linotp3
docker build --platform linux/amd64 -t laa-workspaces/linotp3 .
docker tag laa-workspaces/linotp3:latest 945484575162.dkr.ecr.eu-west-2.amazonaws.com/laa-workspaces/linotp3:latest
docker push 945484575162.dkr.ecr.eu-west-2.amazonaws.com/laa-workspaces/linotp3:latest

# 2. Deploy Terraform (handles AD dependency automatically)
git push origin <branch>

# 3. Watch it configure automatically
aws logs tail /aws/ecs/laa-workspaces-development-linotp3 --since 5m --follow --region eu-west-2 --profile mp-workspaces-dev --no-cli-pager | grep -E "(LinOTP|✅)"
```

## What's Automated

✅ **LDAP UserIdResolver** - Connects to Active Directory  
✅ **Realm Creation** - Creates and sets `laa-workspaces` as default  
✅ **Authentication Policies** - PIN + OTP concatenation  
✅ **Enrollment Policies** - Token limits and issuer  
✅ **Self-Service Policies** - User portal permissions  

**No manual configuration needed!**

## How It Works

### Architecture
```
ECS Task Starts
     ↓
entrypoint.sh runs bootstrap
     ↓
LinOTP starts (port 5000)
     ↓
configure_linotp.py runs in background
     ├── Waits for LinOTP API
     ├── Logs in via /manage/login (session auth)
     ├── Creates LDAP resolver (uses lambda.workspace account)
     ├── Creates realm
     └── Creates policies
     ↓
✅ Fully configured
```

### Deployment Order (Automatic)
Terraform ensures correct order via data source dependency:

```
Parent Module
├── Creates Active Directory
├── Creates lambda.workspace service account
└── Stores password in SSM
         │
         ▼ (data source waits)
Workspace-Components Module
├── Reads SSM parameter
├── Deploys LinOTP ECS
└── Auto-config runs on startup
```

**Key:** `depends_on = [data.aws_ssm_parameter.lambda_service_account_password]` ensures AD exists first.

## Configuration Details

### LDAP Resolver
```
Name: ad-resolver
URI: ldap://laa-workspaces.local:389
Base DN: DC=laa-workspaces,DC=local
Bind DN: CN=lambda.workspace,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local
User Filter: (&(sAMAccountName=%s)(objectClass=user))
Login Attribute: sAMAccountName
```

**Service Account:** Reuses existing `lambda.workspace` from user-creation.ps1

### Policies Created

**radius_auth** (authentication)
- Scope: authentication
- Action: `otppin=1` (concatenate PIN + OTP)
- Users: all in laa-workspaces realm

**self_enrollment** (enrollment)  
- Scope: enrollment
- Action: `maxtoken=5, tokenissuer=LAA WorkSpaces MFA`
- Users: all in laa-workspaces realm

**selfservice_portal** (selfservice)
- Scope: selfservice  
- Actions: enrollHMAC, setOTPPIN, setMOTPPIN, resync, disable, delete, history
- Users: all in laa-workspaces realm

## Verification

### Check Logs
```bash
aws logs tail /aws/ecs/laa-workspaces-development-linotp3 \
  --since 10m \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager | grep -E "(LinOTP|LDAP|Realm|Policy|✅|ERROR)"
```

**Expected output:**
```
Starting LinOTP automated configuration...
Successfully authenticated with LinOTP
LinOTP is ready and authenticated
Creating LDAP resolver 'ad-resolver'...
LDAP resolver 'ad-resolver' created successfully
Creating realm 'laa-workspaces'...
Realm 'laa-workspaces' created successfully
Setting 'laa-workspaces' as default realm...
Creating authentication policy 'radius_auth'...
Creating enrollment policy 'self_enrollment'...
Creating self-service policy 'selfservice_portal'...
✅ LinOTP configuration completed successfully
```

### Check Portal
```bash
# URL
open https://workspace-mfa-ecs.laa-development.modernisation-platform.service.justice.gov.uk/manage

# Get admin password
aws secretsmanager get-secret-value \
  --secret-id laa-workspaces-development-linotp-admin-* \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --query SecretString \
  --output text \
  --no-cli-pager
```

**Verify:**
- Config > UserIdResolvers → See "ad-resolver" (Active)
- Config > Realms → See "laa-workspaces" (default)
- Config > Policies → See 3 policies

## Environment Variables

### Required (set in ECS task definition)
- `LINOTP_ADMIN_PASSWORD` - From Secrets Manager
- `AD_LDAP_URI` - `ldap://laa-workspaces.local:389`
- `AD_BASE_DN` - `DC=laa-workspaces,DC=local`
- `AD_BIND_DN` - `CN=lambda.workspace,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local`
- `AD_BIND_PASSWORD` - From Secrets Manager (mirrors SSM parameter)

### Optional (with defaults)
- `ENABLE_AUTO_CONFIG` - `true` (set to `false` to disable)
- `LINOTP_RESOLVER_NAME` - `ad-resolver`
- `LINOTP_REALM_NAME` - `laa-workspaces`

## Troubleshooting

### Configuration Not Running

**Check if disabled:**
```bash
aws ecs describe-task-definition \
  --task-definition laa-workspaces-development-linotp3 \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager | grep ENABLE_AUTO_CONFIG
```

Should show: `"value": "true"`

### Authentication Errors (401)

The script now uses session-based login. If you see 401 errors, check admin password:
```bash
aws secretsmanager get-secret-value \
  --secret-id laa-workspaces-development-linotp-admin-* \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager
```

### LDAP Connection Failures

Verify lambda.workspace account:
```powershell
Get-ADUser -Identity "lambda.workspace" -Properties Enabled
```

Test authentication:
```powershell
$password = (Get-SSMParameterValue -Name "/laa-workspaces/development/ad-service-account-password" -WithDecryption $true).Parameters[0].Value
$credential = New-Object System.Management.Automation.PSCredential("LAAWORKSPACES\lambda.workspace", (ConvertTo-SecureString $password -AsPlainText -Force))
Get-ADUser -Identity "Administrator" -Credential $credential
```

### Manually Trigger Configuration

If auto-config is disabled or failed:
```bash
# Get task ID
TASK_ID=$(aws ecs list-tasks \
  --cluster laa-workspaces-development \
  --service laa-workspaces-development-linotp3 \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --query 'taskArns[0]' \
  --output text --no-cli-pager | awk -F'/' '{print $NF}')

# Run configuration script
aws ecs execute-command \
  --cluster laa-workspaces-development \
  --task $TASK_ID \
  --container linotp \
  --command "/usr/local/bin/configure_linotp.py" \
  --interactive \
  --region eu-west-2 \
  --profile mp-workspaces-dev
```

## Idempotency

The script is **fully idempotent**:
- Checks if resolver exists before creating
- Checks if realm exists before creating  
- Checks if policies exist before creating
- Safe to run multiple times
- Safe to restart ECS tasks

## Files

### Docker
- `dockerfiles/linotp3/configure_linotp.py` - Configuration script
- `dockerfiles/linotp3/entrypoint.sh` - Runs config in background
- `dockerfiles/linotp3/Dockerfile` - Includes requests library

### Terraform
- `workspace-components/new-ecs-linotp3.tf` - Task definition with AD config
- `workspace-components/new-adds-linotp-svc.tf` - AD service account secret
- `laa-workspaces/outputs.tf` - AD outputs for dependency

## Production Rollout

1. Update `application_variables.json` for test/preproduction/production
2. Create environment-specific task definitions
3. Deploy AD first in each environment
4. Deploy LinOTP ECS (auto-configures on first start)
5. Test token enrollment
6. Configure WorkSpaces Directory to use LinOTP RADIUS NLB

---

For architecture details see **LINOTP-ECS-DEPLOYMENT.md**
