module "ip_addresses" {
  source = "../../modules/ip_addresses"
}

module "environment" {
  source = "../../modules/environment"

  providers = {
    aws.modernisation-platform = aws.modernisation-platform
    aws.core-network-services  = aws.core-network-services
    aws.core-vpc               = aws.core-vpc
  }

  environment_management = local.environment_management
  business_unit          = local.business_unit
  application_name       = local.application_name
  environment            = local.environment
  subnet_set             = local.subnet_set
}

module "baseline_presets" {
  source = "../../modules/baseline_presets"

  environment  = module.environment
  ip_addresses = module.ip_addresses

  options = {
    enable_application_environment_wildcard_cert = true
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    iam_policies_filter                          = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default                     = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies                              = ["EC2S3BucketWriteAndDeleteAccessPolicy"]

    # comment this in if you need to resolve FixNGo hostnames
    # route53_resolver_rules = {
    #   outbound-data-and-private-subnets = ["azure-fixngo-domain"]
    # }
  }
}
module "baseline" {
  source = "../../modules/baseline"

  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
    aws.us-east-1             = aws.us-east-1
  }

  environment = module.environment

  security_groups          = local.baseline_security_groups
  acm_certificates         = module.baseline_presets.acm_certificates
  cloudwatch_log_groups    = module.baseline_presets.cloudwatch_log_groups
  iam_policies             = module.baseline_presets.iam_policies
  iam_roles                = module.baseline_presets.iam_roles
  iam_service_linked_roles = module.baseline_presets.iam_service_linked_roles
  key_pairs                = module.baseline_presets.key_pairs
  kms_grants               = module.baseline_presets.kms_grants
  route53_resolvers        = module.baseline_presets.route53_resolvers

  ec2_instances          = lookup(local.environment_config, "baseline_ec2_instances", {})
  ec2_autoscaling_groups = lookup(local.environment_config, "baseline_ec2_autoscaling_groups", {})
  lbs                    = lookup(local.environment_config, "baseline_lbs", {})

  ssm_parameters = merge(
    local.baseline_ssm_parameters,
    lookup(local.baseline_environment_config, "baseline_ssm_parameters", {}),
  )

  s3_buckets = merge(
    module.baseline_presets.s3_buckets,
    local.baseline_s3_buckets,
    lookup(local.baseline_environment_config, "baseline_s3_buckets", {})
  )
}

#create random value for defualt values
resource "random_password" "random_value" {
  length = 12
}

#create secret store for ndh values
resource "aws_ssm_parameter" "ndh_secrets" {
  for_each = toset(local.ndh_secrets)
  name     = each.value
  type     = "SecureString"
  value    = random_password.random_value.result
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}
