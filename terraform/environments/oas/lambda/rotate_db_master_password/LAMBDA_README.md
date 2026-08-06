# rotate_db_master_password Lambda

## What it does

Rotates the master password of the OAS RDS Oracle instance, on demand.

This is a **manually-invoked** Lambda — there is no EventBridge schedule and it is not
wired up to Secrets Manager's automatic rotation lifecycle. Nobody and nothing calls it
except a human running the invoke command below.

When run, it:

1. Reads the current secret (`oas/app/db-master-password`) from Secrets Manager to get
   the `username`.
2. Generates a new random password with `secretsmanager:GetRandomPassword`.
3. Sets that password directly on the RDS instance via `rds:ModifyDBInstance`
   (`ApplyImmediately=true`). This does not require the current password — it resets it
   at the RDS control-plane level.
4. Writes the new `{username, password}` JSON back into the same Secrets Manager secret
   with `PutSecretValue`, so the secret and the live DB password stay in sync.

Terraform is defined in [`../../new_lambda_rotate_db_password.tf`](../../new_lambda_rotate_db_password.tf).
It deploys one function per environment: `oas-rotate-db-master-password-<environment>`
(currently `preproduction` and `development` only — see note in that file about
`production` not yet being on this Terraform config).

## Prerequisites

- An AWS SSO profile for the target account configured in `~/.aws/config`.
- An active SSO session:

  ```bash
  aws sso login --profile mp-oas-pre-prod
  ```

  (Profile name depends on your local `~/.aws/config` — check there if `mp-oas-pre-prod`
  doesn't exist for you.)

## Invoking the rotation

```bash
aws lambda invoke \
  --profile mp-oas-pre-prod \
  --function-name oas-rotate-db-master-password-preproduction \
  --cli-read-timeout 90 \
  --no-cli-pager \
  response.json

cat response.json
```

A successful run returns:

```json
{"statusCode": 200, "body": "Master password rotated for oas-preproduction"}
```

For `development`, swap the profile and use
`oas-rotate-db-master-password-development` as the function name.

## Verifying the rotation

Check the new secret value was written:

```bash
aws secretsmanager get-secret-value \
  --profile mp-oas-pre-prod \
  --secret-id oas/app/db-master-password \
  --no-cli-pager \
  --query SecretString
```

Check the Lambda's own execution logs if something looks wrong:

```bash
aws logs tail /aws/lambda/oas-rotate-db-master-password-preproduction \
  --profile mp-oas-pre-prod \
  --no-cli-pager \
  --since 10m
```

## Notes

- RDS applies the password change quickly, but the instance briefly shows status
  `resetting-master-credentials` — anything actively connected at that exact moment
  may need to reconnect.
- Because this isn't Secrets Manager's built-in rotation, there's no `AWSPENDING`/
  `AWSCURRENT` staging — the secret is simply overwritten with the new value.
- Terraform ignores drift on the RDS `password` and the secret's `secret_string`
  (see `lifecycle.ignore_changes` in `new-rds.tf`), so running this Lambda will not
  cause `terraform plan` to try to revert the password on the next deploy.
