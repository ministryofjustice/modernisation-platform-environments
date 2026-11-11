# Integration Hub IAC bootstrap

This component provisions the AWS resources used by the PagerDuty Terraform
configuration in the `ministryofjustice/integration-hub` repository. Resources
are created only in the `integration-hub-production` workspace.

The component's own Terraform state remains in the shared Modernisation
Platform state bucket under the `integration-hub/iac` prefix. The dedicated
PagerDuty state bucket created here is separate and is intended only for the
PagerDuty Terraform state and S3 lock file.

The GitHub Actions role trusts the existing account-level GitHub OIDC provider
and only the `pagerduty-production` environment in the Integration Hub
repository. It can access this state path, use its KMS key through S3, and read
the single PagerDuty API-token secret.
The bucket policy denies principals outside the PagerDuty and approved MP
role allowlist, and denies non-TLS requests.

The generated Modernisation Platform configuration reads the
`environment_management` secret version for account-role lookup. Because it is
a standard data source, its value is stored in this component's Terraform
state. This is separate from the PagerDuty API token, which this component
does not read or store.

Create and protect the `pagerduty-production` GitHub environment separately in
the Integration Hub repository; this component does not manage GitHub settings.

Terraform creates the PagerDuty secret container, encrypted with its dedicated
KMS key, without a secret version. Populate its value out of band in Secrets
Manager before running the PagerDuty Terraform configuration. Automatic token
rotation is not configured. The bootstrap component does not manage or read the
token value; the protected PagerDuty workflow supplies it to the provider at
runtime through an ephemeral variable. Do not put it in this repository or
Terraform configuration. The PagerDuty repository must supply its backend
settings externally when initializing its S3 backend.
