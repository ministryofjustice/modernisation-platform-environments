# Database Server

Terraform module for creating database instances from the custom NOMIS Oracle 11g AMI; see [this confluence page](https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/3897262258/Oracle+11gR2+AMI+Build+for+NOMIS+Databases)  

## Usage 

Pay particular attention to the `name` variable. This is used to create private and public Route 53 records for the database instance, e.g. `db.<var.name>.xxxxxxxx.gov.uk`.

Many variables have the `nullable` property set to false, this allows the variable default to be used if a `null` value is passed.  Handy if using the module in a `for_each` and not all values are set (see `termination_protection` in below example).

Example:
```terraform
module "database" {
  source = "./modules/database"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = local.application_data.accounts[local.environment].databases

  name = each.key

  ami_name           = each.value.ami_name
  asm_data_capacity  = each.value.asm_data_capacity
  asm_flash_capacity = each.value.asm_flash_capacity

  asm_data_iops          = try(each.value.asm_data_iops, null)
  asm_data_throughput    = try(each.value.asm_data_throughput, null)
  asm_flash_iops         = try(each.value.asm_flash_iops, null)
  asm_flash_throughput   = try(each.value.asm_data_throughput, null)
  oracle_app_disk_size   = try(each.value.oracle_app_disk_size, null)
  extra_ingress_rules    = try(each.value.extra_ingress_rules, null)
  termination_protection = try(each.value.termination_protection, null)

  common_security_group_id = aws_security_group.database_common.id
  instance_profile_name    = aws_iam_instance_profile.ec2_database_profile.name
  key_name                 = aws_key_pair.ec2-user.key_name

  application_name = local.application_name
  business_unit    = local.vpc_name
  environment      = local.environment
  tags             = local.tags
  subnet_set       = local.subnet_set
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |
| <a name="provider_aws.core-vpc"></a> [aws.core-vpc](#provider\_aws.core-vpc) | ~> 4.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ebs_volume.asm_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.asm_flash](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.oracle_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_ebs_volume.swap](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_iam_role_policy.asm_parameter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_instance.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_route53_record.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.extra_rules](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.asm_snmp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.asm_sys](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_volume_attachment.asm_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.asm_flash](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.oracle_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [aws_volume_attachment.swap](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [random_password.asm_snmp](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.asm_sys](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [time_offset.asm_parameter](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/offset) | resource |
| [aws_ami.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ec2_instance_type.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_instance_type) | data source |
| [aws_iam_instance_profile.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_instance_profile) | data source |
| [aws_iam_policy_document.asm_parameter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_route53_zone.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_route53_zone.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_subnet.data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.shared_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [template_file.user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_name"></a> [ami\_name](#input\_ami\_name) | Name of AMI to be used to launch the database ec2 instance | `string` | n/a | yes |
| <a name="input_ami_owner"></a> [ami\_owner](#input\_ami\_owner) | Owner of AMI to be used to launch the database ec2 instance | `string` | `"self"` | no |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | The name of the application.  This will be name of the environment in Modernisation Platform | `string` | `"nomis"` | no |
| <a name="input_asm_data_capacity"></a> [asm\_data\_capacity](#input\_asm\_data\_capacity) | Total capacity of the DATA disk group in GiB | `number` | `5` | no |
| <a name="input_asm_data_iops"></a> [asm\_data\_iops](#input\_asm\_data\_iops) | Iops of the DATA disks | `number` | `3000` | no |
| <a name="input_asm_data_throughput"></a> [asm\_data\_throughput](#input\_asm\_data\_throughput) | Throughput of the DATA disks in MiB/s | `number` | `125` | no |
| <a name="input_asm_flash_capacity"></a> [asm\_flash\_capacity](#input\_asm\_flash\_capacity) | Total capacity of the FLASH disk group in GiB | `number` | `2` | no |
| <a name="input_asm_flash_iops"></a> [asm\_flash\_iops](#input\_asm\_flash\_iops) | Iops of the FLASH disks | `number` | `3000` | no |
| <a name="input_asm_flash_throughput"></a> [asm\_flash\_throughput](#input\_asm\_flash\_throughput) | Throughput of the FLASH disks in MB/s | `number` | `125` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | The availability zone in which to deploy the infrastructure | `string` | `"eu-west-2a"` | no |
| <a name="input_business_unit"></a> [business\_unit](#input\_business\_unit) | This corresponds to the VPC in which the application resides | `string` | `"hmpps"` | no |
| <a name="input_common_security_group_id"></a> [common\_security\_group\_id](#input\_common\_security\_group\_id) | Common security group used by all database instances | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Application environment - i.e. the terraform workspace | `string` | n/a | yes |
| <a name="input_extra_ingress_rules"></a> [extra\_ingress\_rules](#input\_extra\_ingress\_rules) | A list of extra ingress rules to be added to the database security group | <pre>list(object({<br>    description = string<br>    from_port   = string<br>    to_port     = string<br>    protocol    = string<br>    cidr_blocks = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_instance_profile_name"></a> [instance\_profile\_name](#input\_instance\_profile\_name) | IAM instance profile to be attached to the instance | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | ec2 instance type to use for the database | `string` | `"r6i.xlarge"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Name of ssh key resource for ec2-user | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Provide a unique name for the instance | `string` | n/a | yes |
| <a name="input_oracle_app_disk_size"></a> [oracle\_app\_disk\_size](#input\_oracle\_app\_disk\_size) | Capcity of each Oracle application disk, /u01 and /u02.  If not specified, the default values from the AMI block device mappings will be used. | `map(any)` | `{}` | no |
| <a name="input_subnet_set"></a> [subnet\_set](#input\_subnet\_set) | Fixed variable to specify subnet-set for RAM shared subnets | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Default tags to be applied to resources | `map(any)` | n/a | yes |
| <a name="input_termination_protection"></a> [termination\_protection](#input\_termination\_protection) | Set to true to prevent accidental deletion of instances | `bool` | `false` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->