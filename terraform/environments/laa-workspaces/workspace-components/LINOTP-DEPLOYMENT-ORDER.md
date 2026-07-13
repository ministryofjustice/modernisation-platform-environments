# LinOTP AD Integration - Deployment Order

## Problem

LinOTP ECS deployment and Active Directory have a dependency order:

1. **AD must exist first** - LinOTP needs to connect to AD for LDAP queries
2. **lambda.workspace service account must exist** - Created by AD deployment
3. **AD DNS must be resolvable** - ECS tasks need to reach the domain

## Deployment Strategy: Two-Stage Approach

### Stage 1: Initial Deployment (Auto-Config Disabled)

Deploy infrastructure without automated configuration:

```bash
# ECS task definition has: ENABLE_AUTO_CONFIG=false
# This allows LinOTP to start without trying to configure AD

git push origin <branch>
# Wait for GitHub Actions to complete
```

**At this stage:**
- ✅ ECS cluster created
- ✅ LinOTP container running
- ✅ Database initialized
- ✅ LinOTP portal accessible
- ❌ No LDAP resolver (manual config or automation disabled)

### Stage 2: Enable Auto-Configuration (After AD is Ready)

Once Active Directory is deployed and `lambda.workspace` service account exists:

#### Option A: Terraform Variable (Recommended for production)

Update task definition to enable auto-config:

1. Edit `new-ecs-linotp3.tf`:
   ```terraform
   { name = "ENABLE_AUTO_CONFIG", value = "true" }
   ```

2. Deploy via GitHub Actions:
   ```bash
   git add new-ecs-linotp3.tf
   git commit -m "Enable LinOTP auto-configuration now that AD is ready"
   git push origin <branch>
   ```

#### Option B: Manual ECS Service Update (Quick for testing)

Update the running service without changing Terraform:

```bash
# Get current task definition
TASK_DEF=$(aws ecs describe-services \
  --cluster laa-workspaces-development \
  --services laa-workspaces-development-linotp3 \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --query 'services[0].taskDefinition' \
  --output text --no-cli-pager)

# Get the task definition family and revision
FAMILY=$(echo $TASK_DEF | awk -F'/' '{print $2}' | awk -F':' '{print $1}')

# Describe the task definition and save to file
aws ecs describe-task-definition \
  --task-definition $TASK_DEF \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager \
  --query 'taskDefinition' > /tmp/task-def.json

# Update the ENABLE_AUTO_CONFIG environment variable in the JSON
# (Use jq or manually edit /tmp/task-def.json to change value to "true")

# Register new task definition revision
NEW_TASK_DEF=$(aws ecs register-task-definition \
  --cli-input-json file:///tmp/task-def.json \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager \
  --query 'taskDefinition.taskDefinitionArn' \
  --output text)

# Update service to use new task definition
aws ecs update-service \
  --cluster laa-workspaces-development \
  --service laa-workspaces-development-linotp3 \
  --task-definition $NEW_TASK_DEF \
  --force-new-deployment \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager
```

**Note:** Option B creates drift from Terraform state. Use for testing only.

#### Option C: One-Time Configuration Script

Run configuration manually after AD is ready:

```bash
# Get ECS task ID
TASK_ID=$(aws ecs list-tasks \
  --cluster laa-workspaces-development \
  --service laa-workspaces-development-linotp3 \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --query 'taskArns[0]' \
  --output text --no-cli-pager | awk -F'/' '{print $NF}')

# Execute configuration script inside container
aws ecs execute-command \
  --cluster laa-workspaces-development \
  --task $TASK_ID \
  --container linotp \
  --command "/usr/local/bin/configure_linotp.py" \
  --interactive \
  --region eu-west-2 \
  --profile mp-workspaces-dev
```

## Verification Checklist

### Before Enabling Auto-Config

- [ ] Active Directory is deployed and healthy
- [ ] `lambda.workspace` service account exists in AD
- [ ] Service account password is in SSM: `/laa-workspaces/development/ad-service-account-password`
- [ ] Service account password is mirrored to Secrets Manager: `laa-workspaces/development/linotp-ad-bind-password`
- [ ] AD DNS is resolvable from VPC (test: `nslookup laa-workspaces.local`)
- [ ] LinOTP ECS service is running and healthy

Verify AD readiness:
```bash
# Check AD directory status
aws ds describe-directories \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager

# Check lambda.workspace service account exists
aws ssm get-parameter \
  --name /laa-workspaces/development/ad-service-account-password \
  --with-decryption \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager
```

### After Enabling Auto-Config

Watch CloudWatch Logs for successful configuration:

```bash
aws logs tail /aws/ecs/laa-workspaces-development-linotp3 \
  --since 5m \
  --follow \
  --region eu-west-2 \
  --profile mp-workspaces-dev \
  --no-cli-pager | grep -E "(LinOTP|LDAP|Realm|Policy|✅|ERROR)"
```

Expected output:
```
Starting LinOTP automated configuration...
Successfully authenticated with LinOTP
LinOTP is ready and authenticated
Creating LDAP resolver 'ad-resolver'...
LDAP resolver 'ad-resolver' created successfully
Creating realm 'laa-workspaces'...
Realm 'laa-workspaces' created successfully
Creating authentication policy 'radius_auth'...
✅ LinOTP configuration completed successfully
```

## Alternative: Use Terraform Dependencies

For a fully automated approach, we could restructure to use data sources:

**In parent module (outputs.tf):**
```terraform
output "ad_directory_id" {
  value = aws_directory_service_directory.workspaces_ad[0].id
}

output "ad_dns_ips" {
  value = aws_directory_service_directory.workspaces_ad[0].dns_ip_addresses
}

output "lambda_workspace_password_arn" {
  value = aws_ssm_parameter.lambda_service_account_password[0].arn
}
```

**In workspace-components module:**
```terraform
data "terraform_remote_state" "parent" {
  backend = "s3"
  config = {
    # ... parent state location
  }
}

# Reference AD directory in ECS task definition
# This creates implicit dependency - workspace-components can't deploy until parent is done
```

However, this requires workspace-components to read parent state, which may not fit your current Terraform structure.

## Recommendation

For your current setup, use **Option A (Two-Stage Terraform):**

1. **Now:** Deploy with `ENABLE_AUTO_CONFIG=false`
2. **After AD ready:** Change to `true` and redeploy

This is:
- ✅ Simple and explicit
- ✅ No Terraform restructuring needed
- ✅ Clear deployment order
- ✅ Easy to understand and maintain

---

**Last Updated:** 2026-07-13  
**Status:** Two-stage deployment strategy recommended
