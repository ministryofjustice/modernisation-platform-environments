module "db_instance" {
  for_each = var.rds_instances

  source = "../../modules/rds_instance"

  providers = {
    aws.core-vpc = aws.core-vpc
  }

  instance = merge(each.value.instance, {
    vpc_security_group_ids = [
      for sg in each.value.instance.vpc_security_group_ids : lookup(aws_security_group.this, sg, null) != null ? aws_security_group.this[sg].id : sg
    ]
  })

  tags = merge(local.tags, each.value.tags)

  enabled_cloudwatch_logs_exports = local.enabled_cloudwatch_logs_exports
}