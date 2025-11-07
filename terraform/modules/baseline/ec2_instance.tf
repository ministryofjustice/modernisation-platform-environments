module "ec2_instance" {
  #checkov:skip=CKV_TF_1:Ensure Terraform module sources use a commit hash; skip as this is MoJ Repo

  for_each = var.ec2_instances

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v4.2.0"

  providers = {
    aws.core-vpc = aws.core-vpc
  }

  name = each.key

  business_unit      = var.environment.business_unit
  application_name   = var.environment.application_name
  environment        = var.environment.environment
  region             = var.environment.region
  account_ids_lookup = var.environment.account_ids

  ami_name  = each.value.config.ami_name
  ami_owner = each.value.config.ami_owner

  instance = merge(each.value.instance, {
    vpc_security_group_ids = [
      for sg in each.value.instance.vpc_security_group_ids : lookup(aws_security_group.this, sg, null) != null ? aws_security_group.this[sg].id : sg
    ]
  })

  availability_zone             = each.value.config.availability_zone
  default_policy_arn            = each.value.config.default_policy_arn
  subnet_id                     = var.environment.subnet[each.value.config.subnet_name][each.value.config.availability_zone].id
  ebs_volumes_copy_all_from_ami = each.value.config.ebs_volumes_copy_all_from_ami
  ebs_volume_root_name          = each.value.config.ebs_volume_root_name
  ebs_kms_key_id                = coalesce(each.value.config.ebs_kms_key_id, var.environment.kms_keys["ebs"].arn)
  ebs_volume_config             = each.value.ebs_volume_config
  ebs_volume_tags               = each.value.ebs_volume_tags
  ebs_volumes                   = each.value.ebs_volumes
  user_data_raw                 = each.value.config.user_data_raw
  user_data_cloud_init          = each.value.user_data_cloud_init
  ssm_parameters_prefix         = each.value.config.ssm_parameters_prefix
  secretsmanager_secrets_prefix = each.value.config.secretsmanager_secrets_prefix
  iam_resource_names_prefix     = each.value.config.iam_resource_names_prefix
  route53_records               = each.value.route53_records

  # add KMS Key Ids if they are referenced by name
  ssm_parameters = each.value.ssm_parameters == null ? null : {
    for key, value in each.value.ssm_parameters : key => merge(value,
      value.kms_key_id == null || value.type != "SecureString" ? {
        kms_key_id = null } : {
        kms_key_id = try(var.environment.kms_keys[value.kms_key_id].arn, value.kms_key_id)
      }
    )
  }
  secretsmanager_secrets = each.value.secretsmanager_secrets == null ? null : {
    for key, value in each.value.secretsmanager_secrets : key => merge(value,
      value.kms_key_id == null ? { kms_key_id = null } : { kms_key_id = try(var.environment.kms_keys[value.kms_key_id].arn, value.kms_key_id) }
    )
  }

  # either reference policies created by this module by using the name, e.g.
  # "BusinessUnitKmsCmkPolicy", or pass in policy ARNs from outside module
  # directly.
  instance_profile_policies = [
    for policy in each.value.config.instance_profile_policies :
    lookup(aws_iam_policy.this, policy, null) != null ? aws_iam_policy.this[policy].arn : policy
  ]

  cloudwatch_metric_alarms = {
    for key, value in each.value.cloudwatch_metric_alarms : key => merge(value, {
      alarm_actions = [
        for item in value.alarm_actions : try(aws_sns_topic.this[item].arn, item)
      ]
      ok_actions = [
        for item in value.ok_actions : try(aws_sns_topic.this[item].arn, item)
      ]
    })
  }

  tags = merge(local.tags, each.value.tags)
}
