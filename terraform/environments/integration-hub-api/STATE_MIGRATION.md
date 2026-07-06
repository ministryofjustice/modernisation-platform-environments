# Integration Hub API State Migration

This runbook moves the existing API Terraform state from the legacy component path:

- `terraform/environments/integration-hub/api-platform`

to the new owning environment:

- `terraform/environments/integration-hub-api`

It assumes the application code already lives in `ministryofjustice/integration-hub-file-transfer-api` and that the Terraform configuration in `integration-hub-api` is the active source of truth.

## What moves

Old backend object:

```text
s3://modernisation-platform-terraform-state/environments/members/integration-hub/api-platform/integration-hub-development/terraform.tfstate
```

New backend object:

```text
s3://modernisation-platform-terraform-state/environments/members/integration-hub-api/integration-hub-api-development/terraform.tfstate
```

The resource addresses inside the state do not need to change because the copied Terraform keeps the same root-level resource and module names.

## Preconditions

1. Pause any manual applies for both `integration-hub` and `integration-hub-api`.
2. Do not merge or apply any further changes to the legacy `terraform/environments/integration-hub/api-platform` stack during the migration window.
3. Ensure the new companion application repository is cloned locally next to this repository:

```bash
cd ..
git clone git@github.com:ministryofjustice/integration-hub-file-transfer-api.git
```

4. Ensure you are authenticated for the target AWS account:

```bash
AWS_PROFILE=integration-hub-development aws sts get-caller-identity --region eu-west-2
```

## Migration sequence

### 1. Back up the legacy state

```bash
AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub/api-platform init -reconfigure
AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub/api-platform workspace select integration-hub-development
AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub/api-platform state pull > /tmp/integration-hub-api-platform-development-pre-migration.tfstate
```

Optional sanity check:

```bash
jq '.resources | length' /tmp/integration-hub-api-platform-development-pre-migration.tfstate
```

### 2. Initialise the new owning environment

```bash
AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub-api init -reconfigure
AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub-api workspace new integration-hub-api-development || AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub-api workspace select integration-hub-api-development
```

### 3. Push the saved state into the new backend location

```bash
AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub-api state push /tmp/integration-hub-api-platform-development-pre-migration.tfstate
```

### 4. Verify the migrated state landed where expected

```bash
AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub-api workspace select integration-hub-api-development
AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub-api state list
```

Compare with the legacy state if you want a quick count check:

```bash
AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub/api-platform state list | wc -l
AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub-api state list | wc -l
```

### 5. Run a no-apply verification plan from the new environment

```bash
AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub-api plan
```

Expected outcome:

- no resource replacement
- likely tag updates where `environment-name` changes from `integration-hub-development` to `integration-hub-api-development`
- no changes to API names, Lambda names, secret names, or DynamoDB table names because those are pinned to the legacy resource prefix

### 6. Apply only from the new environment after reviewing the plan

```bash
AWS_PROFILE=integration-hub-development terraform -chdir=terraform/environments/integration-hub-api apply
```

## Rollback

If the new environment does not plan cleanly, stop before apply.

The safest rollback is:

1. leave the legacy state object untouched
2. keep the backup file from `/tmp`
3. do not apply from `integration-hub-api`
4. continue to use `terraform/environments/integration-hub/api-platform` until the drift is understood

If you need to clear the new state location after an aborted migration, select the new workspace and push an empty state only if you are certain nobody has applied from it. In most cases it is safer to leave the copied state in place and resolve the issue explicitly.

## Important notes

1. This runbook is for the current development workspace pair:
   `integration-hub-development` -> `integration-hub-api-development`
2. Repeat the same pattern for `test`, `preproduction`, and `production` only when those workspaces/accounts actually exist.
3. Do not run the legacy `integration-hub/api-platform` apply after cutover, or you risk split-brain state management.
