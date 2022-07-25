<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_backup_plan.backup-plan](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_plan) | resource |
| [aws_backup_selection.backup-selection](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_selection) | resource |
| [aws_backup_vault.backup-vault](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/backup_vault) | resource |
| [aws_iam_role.aws-backup-service-role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.backup-service-aws-backup-role-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.backup-service-pass-role-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.restore-service-aws-backup-role-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_kms_key.aws_backup_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.current_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.aws-backup-service-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy.aws-restore-service-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.aws-backup-service-assume-role-policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.example-pass-role-policy-doc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | The name of the application.  This will be name of the environment in Modernisation Platform | `string` | `"nomis"` | no |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | This corresponds to the VPC in which the application resides | `string` | `"hmpps"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Application environment - i.e. the terraform workspace | `string` | n/a | yes |
| <a name="input_key"></a> [key](#input\_key) | n/a | `string` | `"backup"` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | n/a | `any` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Default tags to be applied to resources | `map(any)` | n/a | yes |
| <a name="input_value"></a> [value](#input\_value) | n/a | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->