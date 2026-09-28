# rotate_ssh_key Lambda

## What it does

Rotates the OAS EC2 instance's SSH key pair on a schedule, without requiring the instance
to be recreated. Delivered for [STB-4584](../../../../../../xxx-tickets/STB-4584/ssh-key-rotation-and-bastion-removal.md)
Part 2.

The `key_name`/`aws_key_pair` binding on `aws_instance` only matters at first boot - AWS
exposes the associated public key via instance metadata once, and it's userdata that reads
it into `authorized_keys` a single time. Nothing re-reads that metadata afterward, so
rotation bypasses `key_name` entirely and re-triggers the same mechanism periodically
instead:

1. An EventBridge schedule invokes this Lambda every 90 days.
2. The Lambda sends an `AWS-RunShellScript` command to the instance via `ssm:SendCommand`.
3. **On the instance itself**, running as root under its own IAM role:
   - Generates a new ED25519 keypair with `ssh-keygen` in a temp directory.
   - Overwrites `ec2-user`'s `~/.ssh/authorized_keys` with the new public key (atomic
     replace, not a grace-period append - see "Design decisions" below).
   - Writes `{private_key, public_key}` into the Secrets Manager secret
     (`oas-<environment>/ec2-ssh-private-key`) via `secretsmanager:PutSecretValue`, the
     same secret the team's `scp`/`sftp` workflow already reads from (see the STB-4570
     [runbook](../../../../../../xxx-tickets/STB-4570/ssm-connectivity-runbook.md)).
   - Cleans up the temp directory.
4. The Lambda polls `ssm:GetCommandInvocation` until the command finishes and raises if it
   didn't succeed, so a failed rotation surfaces as a Lambda error rather than failing
   silently.

The Lambda itself never handles key material - it only triggers the script and checks the
result. Key generation and the Secrets Manager write both happen on the instance, under the
instance's own IAM role: the instance is trusted to vouch for its own new key material,
rather than have the Lambda transit private key bytes through its own execution environment
or logs.

Terraform is defined in [`../../new_lambda_rotate_ssh_key.tf`](../../new_lambda_rotate_ssh_key.tf).
Deploys one function per environment: `oas-rotate-ssh-key-<environment>` (currently
`preproduction` and `development` only, matching every other resource in this module).

## Design decisions (resolving STB-4584's open questions)

- **Cadence: every 90 days.** Standard baseline for static credential rotation.
- **Scope: `ec2-user` only.** `root` and `oracle` are not rotated - direct root/oracle SSH
  login isn't part of the documented STB-4570 workflow, so their `authorized_keys` are left
  as whatever the original userdata run set. If that changes, extend `ROTATE_SCRIPT` in
  `lambda_function.py` to cover them the same way `new-userdata.sh` originally did.
- **Atomic replace, no grace period.** The new key overwrites `authorized_keys` outright.
  An in-flight transfer at the exact moment of rotation could be interrupted; given the
  90-day cadence this is judged an acceptable trade-off against the added complexity of
  tracking a previous-key grace window and pruning it on the next run.

## Terraform drift note

The private key is seeded once by Terraform (`tls_private_key.ec2_ssh_key` →
`aws_secretsmanager_secret_version.ec2_ssh_private_key_version` in `new-ec2.tf`), which has
`lifecycle.ignore_changes = [secret_string]` - the same pattern used for the RDS master
password in `new-rds.tf`. Without it, the next `terraform apply` after a Lambda rotation
would see the secret's value as drift and silently overwrite it back to the
Terraform-generated key.

## Verifying a rotation

Check the Lambda's own execution logs:

```bash
aws logs tail /aws/lambda/oas-rotate-ssh-key-preproduction \
  --profile mp-oas-pre-prod \
  --no-cli-pager \
  --since 1h
```

Check the new secret value was written:

```bash
aws secretsmanager get-secret-value \
  --profile mp-oas-pre-prod \
  --secret-id oas-preproduction/ec2-ssh-private-key \
  --no-cli-pager \
  --query SecretString
```

For `development`, swap the profile and use `oas-development/ec2-ssh-private-key` /
`oas-rotate-ssh-key-development`.

## Manually triggering a rotation

```bash
aws lambda invoke \
  --profile mp-oas-pre-prod \
  --function-name oas-rotate-ssh-key-preproduction \
  --cli-read-timeout 120 \
  --no-cli-pager \
  response.json

cat response.json
```
