# Database Server

Terraform module for creating database instances from the custom NOMIS Oracle 11g AMI; see [this confluence page](https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/3897262258/Oracle+11gR2+AMI+Build+for+NOMIS+Databases)

## Usage

Pay particular attention to the `name` variable. This is used to create private and public Route 53 records for the database instance, e.g. `db.<var.name>.xxxxxxxx.gov.uk`.

Many variables have the `nullable` property set to false, this allows the variable default to be used if a `null` value is passed. Handy if using the module in a `for_each` and not all values are set (see `termination_protection` in below example).

Example:

```terraform
module "database" {
  source = "./modules/database"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = local.accounts[local.environment].databases

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

## Upgrading the AMI

If you upgrade the AMI used by the instance, the instance will be destroyed, however as the ebs volumes are managed as separate resources it is possible to retain the ebs snapshots. Currently the ebs volumes associated with the database DATA and FLASH disk groups have a lifecycle argument to ignore changes to the snapshot id, thus upgrading the AMI will not destroy the data stored on these volumes. It should then be possible to do an in place upgrade of the AMI without losing the database data. This has been tested with the AMIs containing the `CNOMT1` database. For other AMIs additional steps will be required to add and open the retained database.

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->
