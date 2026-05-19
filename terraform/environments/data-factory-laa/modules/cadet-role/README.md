<!-- BEGIN_TF_DOCS -->
This Terraform configuration defines an IAM role for CADeT (Create a Derived Table) with a trust policy that allows it to be assumed by a federated identity provider (Usually Airflow or GitHub Actions). The role is granted permissions to perform various actions on AWS Lake Formation and AWS Glue services.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_identity_provider_arn"></a> [identity\_provider\_arn](#input\_identity\_provider\_arn) | Identity provider used to trust AP Compute account | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS --> 