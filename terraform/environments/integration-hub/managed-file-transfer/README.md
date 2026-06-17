# Managed File Transfer

This environment provides a proof-of-concept AWS Transfer Family endpoint for Integration Hub file uploads.

## Custom IdP POC

The Transfer server uses a Lambda custom identity provider backed by DynamoDB metadata and Secrets Manager credentials. The POC server exposes SFTP and FTPS on a single VPC-hosted endpoint with one Elastic IP address.

The initial POC identity provider is Secrets Manager because it supports password authentication for FTPS and public key authentication for SFTP with a small migration from the previous service-managed SFTP user model. This is not the preferred long-term password strategy. Before production use, evaluate Argon2 password hashes for local users or an enterprise identity provider such as Entra ID or Active Directory.

## Required Configuration

Set `TF_VAR_transfer_ftps_certificate_arn` to an ACM certificate ARN in `eu-west-2` before planning or applying. AWS Transfer uses this certificate for FTPS.

The POC user secret is named from `custom_idp_configuration.secret_prefix` plus the username. With the default configuration, the `dms1981` secret is `transfer/dms1981` and must contain JSON in this shape:

```json
{
  "Password": "replace-with-ftps-password",
  "PublicKeys": [
    "ssh-ed25519 replace-with-public-key"
  ]
}
```

The secret value is ignored by Terraform after creation and should be populated directly in AWS Secrets Manager.

## Network Ports

The Transfer security group allows:

- TCP 22 for SFTP
- TCP 21 for FTPS control
- TCP 8192-8200 for FTPS passive data channels

The development POC currently allows these from `0.0.0.0/0`. Narrow `custom_idp_configuration.ingress_cidr_blocks` before using this with known client networks.

## Operations

Before applying, confirm no client is pinned to either of the two Elastic IP addresses that Terraform will remove. Changing the Transfer identity provider and protocol set may update or replace the server, so coordinate a short outage for the POC endpoint.

After applying, test password authentication with the AWS Transfer console custom IdP tester using protocol `FTPS`, then test SFTP public key access and FTPS passive-mode uploads with a client such as FileZilla or `lftp`.

Monitor the Transfer log group and the custom IdP Lambda log group. Keep `custom_idp_configuration.log_level` at `INFO` unless troubleshooting in a non-production environment, because debug logs can expose sensitive authentication context.
