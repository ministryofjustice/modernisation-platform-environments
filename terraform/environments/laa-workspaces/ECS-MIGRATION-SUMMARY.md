# LinOTP ECS Migration to Root Module

## What Changed

Successfully moved ECS task definition and service from `workspace-components` to root `laa-workspaces` module to enable direct AD references.

### Architecture Before:
```
workspace-components/
  ├── VPC, subnets, security groups
  ├── ALB, NLB, target groups  
  ├── RDS, Secrets, ECR
  ├── ECS cluster
  └── ECS task definition & service ❌ (couldn't reference AD)
```

### Architecture After:
```
laa-workspaces/ (root)
  ├── Active Directory
  └── ECS task definition & service ✅ (references AD DNS IPs)

workspace-components/
  ├── VPC, subnets, security groups
  ├── ALB, NLB, target groups
  ├── RDS, Secrets, ECR
  └── ECS cluster
```

## Key Changes

### 1. Added Outputs to workspace-components (`outputs.tf`)
```terraform
output "linotp_portal_target_group_arn" { ... }
output "ecs_task_execution_role_arn" { ... }
output "ecs_linotp3_security_group_id" { ... }
output "linotp3_db_endpoint" { ... }
output "linotp3_enc_key_secret_arn" { ... }
output "linotp3_db_password_secret_arn" { ... }
output "linotp_ad_bind_password_secret_arn" { ... }
```

### 2. Created ECS Resources in Root (`ecs-linotp3.tf`)
- Task definition with AD LDAP URI using actual AD DNS IP:
  ```terraform
  { name = "AD_LDAP_URI", value = "ldap://${aws_directory_service_directory.workspaces_ad[0].dns_ip_addresses[0]}:389" }
  ```
- ECS service with `depends_on = [aws_directory_service_directory.workspaces_ad]`
- References workspace-components via existing `data.terraform_remote_state.workspace_components`

### 3. Removed from workspace-components (`new-ecs-linotp3.tf`)
- Deleted ECS task definition (lines 156-331)
- Deleted ECS service (lines 337-378)
- Kept all infrastructure (cluster, IAM roles, target groups, etc.)

### 4. Updated RADIUS Health Check (`new-nlb-radius-ecs.tf`)
- Changed `unhealthy_threshold = 2` → `6`
- Gives 180 seconds for LinOTP to start (was 60 seconds)

## Deployment Order

### First Time Setup:
1. **Deploy workspace-components** (creates infrastructure + new outputs):
   ```bash
   cd workspace-components
   terraform apply
   ```

2. **Deploy root** (creates ECS with AD references):
   ```bash
   cd ..
   terraform apply
   ```

### Future Updates:
- Infrastructure changes → apply workspace-components
- AD or ECS service changes → apply root
- Both modules can be applied independently

## Benefits

✅ **Proper AD Integration**: LDAP URI uses actual AD DNS IP from `aws_directory_service_directory`  
✅ **Correct Deployment Order**: `depends_on` ensures AD exists before ECS starts  
✅ **No Hardcoded IPs**: Dynamic reference to AD DNS servers  
✅ **Automated Configuration**: LinOTP auto-configures on first boot with correct AD connection  
✅ **Clean Separation**: Infrastructure vs. application deployment

## Testing

After deployment:
1. Check ECS service: `aws ecs describe-services --cluster laa-workspaces-development --services laa-workspaces-development-linotp3`
2. Verify task is running and healthy
3. Check logs for "✅ LinOTP configuration completed successfully"
4. Access portal: https://workspace-mfa-ecs.laa-development.modernisation-platform.service.justice.gov.uk/
5. Verify resolver, realm, and policies exist in LinOTP

## Rollback Plan

If issues occur:
1. Scale ECS service to 0: `aws ecs update-service --desired-count 0`
2. Revert terraform changes
3. Re-apply workspace-components with original task definition
