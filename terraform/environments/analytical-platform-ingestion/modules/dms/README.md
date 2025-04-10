<!-- BEGIN_TF_DOCS -->
# RDS Export Terraform Module

## Example

```hcl
data "aws_availability_zones" "available" {}

locals {
  name = "test-dms"
  tags = {
    business-unit    = "HMPPS"
    application      = "Data Engineering"
    environment-name = "sandbox"
    is-production    = "False"
    owner            = "DMET"
    team-name        = "DMET"
    namespace        = "dmet-test"
  }
}

module "dms" {
  source = "github.com/ministryofjustice/analytical-platform//terraform/aws/modules/data-engineering/dms?ref=66a7d870"

  environment = local.tags.environment-name
  vpc_id      = module.vpc.vpc_id
  db          = aws_db_instance.dms_test.identifier

  dms_replication_instance = {
    replication_instance_id    = aws_db_instance.dms_test.identifier
    subnet_ids                 = module.vpc.private_subnets
    subnet_group_name          = local.name
    allocated_storage          = 20
    availability_zone          = data.aws_availability_zones.available.names[0]
    engine_version             = "3.5.4"
    multi_az                   = false
    replication_instance_class = "dms.t2.micro"
    inbound_cidr               = module.vpc.vpc_cidr_block
  }

  dms_source = {
    engine_name                 = "oracle"
    secrets_manager_arn         = "arn:aws:secretsmanager:eu-west-1:123456789012:secret:dms-user-secret"
    sid                         = aws_db_instance.dms_test.db_name
    extra_connection_attributes = "addSupplementalLogging=N;useBfile=Y;useLogminerReader=N;"
    cdc_start_time              = "2025-01-29T11:00:00Z"
  }

  replication_task_id = {
    full_load = "${aws_db_instance.dms_test.identifier}-full-load"
    cdc       = "${aws_db_instance.dms_test.identifier}-cdc"
  }

  dms_mapping_rules     = file("${path.module}/mappings.json")
  landing_bucket        = aws_s3_bucket.landing.bucket
  landing_bucket_folder = "${local.tags.team-name}/${aws_db_instance.dms_test.identifier}"

  tags = local.tags
}
```

## Note

Update the mappings.json to specify the mappings for the DMS task.
This will be used to select the tables to be migrated.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db"></a> [db](#input\_db) | The database name | `string` | n/a | yes |
| <a name="input_dms_mapping_rules"></a> [dms\_mapping\_rules](#input\_dms\_mapping\_rules) | The path to the mapping rules file | `string` | n/a | yes |
| <a name="input_dms_replication_instance"></a> [dms\_replication\_instance](#input\_dms\_replication\_instance) | n/a | <pre>object({<br/>    replication_instance_id    = string<br/>    subnet_group_id            = optional(string)<br/>    subnet_group_name          = optional(string)<br/>    subnet_ids                 = optional(list(string))<br/>    allocated_storage          = number<br/>    availability_zone          = string<br/>    engine_version             = string<br/>    kms_key_arn                = optional(string)<br/>    multi_az                   = bool<br/>    replication_instance_class = string<br/>    inbound_cidr               = string<br/>  })</pre> | n/a | yes |
| <a name="input_dms_source"></a> [dms\_source](#input\_dms\_source) | extra\_connection\_attributes: Extra connection attributes to be used in the connection string</br><br/>    cdc\_start\_time: The start time for the CDC task, this will need to be set to a date after the Oracle database setup has been complete (this is to ensure the logs are available) | <pre>object({<br/>    engine_name                 = string,<br/>    secrets_manager_arn         = string,<br/>    sid                         = string,<br/>    extra_connection_attributes = optional(string)<br/>    cdc_start_time              = optional(string)<br/>  })</pre> | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment name | `string` | n/a | yes |
| <a name="input_landing_bucket"></a> [landing\_bucket](#input\_landing\_bucket) | The S3 bucket name where the output data will be stored | `string` | n/a | yes |
| <a name="input_landing_bucket_folder"></a> [landing\_bucket\_folder](#input\_landing\_bucket\_folder) | The S3 bucket folder where the output data will be stored | `string` | n/a | yes |
| <a name="input_replication_task_id"></a> [replication\_task\_id](#input\_replication\_task\_id) | n/a | <pre>object({<br/>    full_load = string<br/>    cdc       = string<br/>  })</pre> | n/a | yes |
| <a name="input_s3_target_config"></a> [s3\_target\_config](#input\_s3\_target\_config) | n/a | <pre>object({<br/>    add_column_name       = bool<br/>    max_batch_interval    = number<br/>    min_file_size         = number<br/>    timestamp_column_name = string<br/>  })</pre> | <pre>{<br/>  "add_column_name": true,<br/>  "max_batch_interval": 3600,<br/>  "min_file_size": 32000,<br/>  "timestamp_column_name": "EXTRACTION_TIMESTAMP"<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_terraform_rules"></a> [terraform\_rules](#output\_terraform\_rules) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_dms_endpoint.source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_endpoint) | resource |
| [aws_dms_replication_instance.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_replication_instance) | resource |
| [aws_dms_replication_subnet_group.replication_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_replication_subnet_group) | resource |
| [aws_dms_replication_task.cdc_replication_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_replication_task) | resource |
| [aws_dms_replication_task.full_load_replication_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_replication_task) | resource |
| [aws_dms_s3_endpoint.s3_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dms_s3_endpoint) | resource |
| [aws_iam_role.dms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.dms_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.dms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.dms_source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_security_group.replication_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_security_group_egress_rule.replication_instance_outbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.replication_instance_inbound](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
<!-- END_TF_DOCS -->
