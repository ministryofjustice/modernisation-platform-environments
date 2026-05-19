<!-- BEGIN_TF_DOCS -->
This Terraform configuration defines an IAM role for Airflow with permissions to access specified S3 buckets.
The role is assumed by a web identity provider, allowing Airflow to interact with AWS resources securely.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_data_buckets"></a> [data\_buckets](#input\_data\_buckets) | List of S3 buckets to grant access to | `list(string)` | n/a | yes |
| <a name="input_identity_provider_arn"></a> [identity\_provider\_arn](#input\_identity\_provider\_arn) | Identity provider used to trust AP Compute account | `string` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | n/a | `string` | `"airflow"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS --> 