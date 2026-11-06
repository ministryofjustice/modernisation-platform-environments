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
The bucket policy restricts access to this role and the required MP platform
and deployment roles.

The Modernisation Platform `environment_management` secret is read
ephemerally for account-role lookup and is not stored in this component's state.

Create and protect the `pagerduty-production` GitHub environment separately in
the Integration Hub repository; this component does not manage GitHub settings.

Terraform creates the PagerDuty secret container without a secret version.
Populate its value out of band in Secrets Manager before running the PagerDuty
Terraform configuration. The bootstrap component does not manage or read the
token value; the protected PagerDuty workflow supplies it to the provider at
runtime through an ephemeral variable. Do not put it in this repository or
Terraform configuration. The PagerDuty repository must supply its backend
settings externally when initializing its S3 backend.
