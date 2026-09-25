# Data Factory External IAM Role

A module to allow external AWS account access to S3 bucket and Glue database.

## Usage
```hcl
module "data_factory_external_iam" {
    source = "github.com/ministryofjustice/terraform-aws-moj-data-factory-modules//modules/.."

    role_name          = "avature_ingestion_role"
    trusted_account_id = "123456789012"

    environment = "dev"

    max_session_duration = 3600

    tags = {
        Project = "Avature"
        Owner   = "CorporateDataEngineering"
        }

    # Restrict S3 access to a single prefix.
    bucket_arn = module.data_factory_s3_bucket.bucket_arn
    s3_prefix  = "avature"

    s3_object_actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
        ]

    # Allow use of the bucket's KMS key.
    kms_key_arn = "placeholder"

    kms_actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:ReEncryptFrom",
        "kms:ReEncryptTo",
        "kms:DescribeKey"
        ]

    # Allow management of Glue tables within the specified database.
    glue_catalog_arn  = "placeholder"
    glue_database_arn = "placeholder"

    # "*" allows the role to create and manage any table in the database.
    glue_table_name = "*"

    glue_actions = [
        "glue:GetDatabase",
        "glue:GetTable",
        "glue:GetTables",
        "glue:CreateTable",
        "glue:UpdateTable",
        "glue:DeleteTable"
        ]
}
```
<!--BEGIN_TF_DOCS-->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_arn"></a> [bucket\_arn](#input\_bucket\_arn) | ARN of the S3 bucket containing the allocated prefix. | `string` | n/a | yes |
| <a name="input_glue_actions"></a> [glue\_actions](#input\_glue\_actions) | Glue table actions allowed within the allocated database. | `list(string)` | <pre>[<br/>  "glue:GetDatabase",<br/>  "glue:GetTable",<br/>  "glue:SearchTables",<br/>  "glue:DeleteTable",<br/>  "glue:CreateTable",<br/>  "glue:UpdateTable"<br/>]</pre> | no |
| <a name="input_glue_catalog_arn"></a> [glue\_catalog\_arn](#input\_glue\_catalog\_arn) | ARN of the Glue catalog. | `string` | n/a | yes |
| <a name="input_glue_database_arn"></a> [glue\_database\_arn](#input\_glue\_database\_arn) | ARN of the Glue database allocated to the external client. | `string` | n/a | yes |
| <a name="input_glue_table_arn"></a> [glue\_table\_arn](#input\_glue\_table\_arn) | Glue table ARN, either for a specific table or all tables in the database. | `string` | n/a | yes |
| <a name="input_kms_actions"></a> [kms\_actions](#input\_kms\_actions) | KMS cryptographic actions allowed through Amazon S3. | `list(string)` | <pre>[<br/>  "kms:Decrypt",<br/>  "kms:Encrypt",<br/>  "kms:GenerateDataKey",<br/>  "kms:ReEncryptFrom",<br/>  "kms:ReEncryptTo"<br/>]</pre> | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of the KMS key used to encrypt objects in the S3 bucket. | `string` | n/a | yes |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration for the IAM role, in seconds. | `number` | `3600` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Name of the IAM role. | `string` | n/a | yes |
| <a name="input_s3_object_actions"></a> [s3\_object\_actions](#input\_s3\_object\_actions) | S3 object actions allowed within the allocated prefix. | `list(string)` | <pre>[<br/>  "s3:GetObject",<br/>  "s3:PutObject",<br/>  "s3:DeleteObject"<br/>]</pre> | no |
| <a name="input_s3_prefix"></a> [s3\_prefix](#input\_s3\_prefix) | S3 key prefix allocated to the external client. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to created resources. | `map(string)` | `{}` | no |
| <a name="input_trusted_account_id"></a> [trusted\_account\_id](#input\_trusted\_account\_id) | AWS account ID allowed to assume the role. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_policy_arn"></a> [policy\_arn](#output\_policy\_arn) | ARN of the IAM policy. |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of the IAM role. |
| <a name="output_role_name"></a> [role\_name](#output\_role\_name) | Name of the IAM role. |
<!--END_TF_DOCS-->