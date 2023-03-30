module "db_instance" {
  for_each = var.rds_instances

  source = "../../modules/rds_instance"

  providers = {
    aws.core-vpc = aws.core-vpc
  }

  application_name = var.environment.application_name
  environment      = var.environment.environment

  identifier = each.value.instance.identifier

  instance = merge(each.value.instance, {
    vpc_security_group_ids = [
      for sg in each.value.instance.vpc_security_group_ids : lookup(aws_security_group.this, sg, null) != null ? aws_security_group.this[sg].id : sg
    ]
  })
  option_group    = each.value.option_group
  parameter_group = each.value.parameter_group
  subnet_group    = each.value.subnet_group

  ssm_parameters_prefix = each.value.config.ssm_parameters_prefix
  ssm_parameters        = each.value.ssm_parameters
  route53_record        = each.value.route53_record

  instance_profile_policies = [
    for policy in each.value.config.instance_profile_policies :
    lookup(aws_iam_policy.this, policy, null) != null ? aws_iam_policy.this[policy].arn : policy
  ]

  tags = merge(local.tags, each.value.tags)
}