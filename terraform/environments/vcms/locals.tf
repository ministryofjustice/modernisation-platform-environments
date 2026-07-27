# define configuration common to all environments here
# define environment specific configuration in locals_development.tf, locals_test.tf etc.

locals {
  baseline_presets_environments_specific = {
    development   = local.baseline_presets_development
    test          = local.baseline_presets_test
    preproduction = local.baseline_presets_preproduction
    production    = local.baseline_presets_production
  }
  baseline_presets_environment_specific = local.baseline_presets_environments_specific[local.environment]

  baseline_environments_specific = {
    development   = local.baseline_development
    test          = local.baseline_test
    preproduction = local.baseline_preproduction
    production    = local.baseline_production
  }
  baseline_environment_specific = local.baseline_environments_specific[local.environment]

  baseline_presets_all_environments = {
    options = {
      cloudwatch_dashboard_default_widget_groups = [
        "lb",
        # "ec2",
        # "ec2_linux",
        # "ec2_autoscaling_group_linux",
        # "ec2_instance_linux",
        # "ec2_instance_oracle_db_with_backup",
        # "ec2_instance_textfile_monitoring",
        # "ssm_command",
      ]
      # cloudwatch_metric_alarms_default_actions    = ["pagerduty"]
      # cloudwatch_metric_oam_links_ssm_parameters  = ["hmpps-oem-${local.environment}"]
      # cloudwatch_metric_oam_links                 = ["hmpps-oem-${local.environment}"]
      # db_backup_more_permissions                  = true
      # enable_backup_plan_daily_and_weekly         = true
      # enable_business_unit_kms_cmks               = true
      enable_ec2_cloud_watch_agent                = true
      # enable_ec2_oracle_enterprise_managed_server = true
      # enable_ec2_security_groups                  = true
      enable_ec2_self_provision                   = true
      # enable_ec2_session_manager_cloudwatch_logs  = true
      # enable_ec2_ssm_agent_update                 = true
      # enable_ec2_user_keypair                     = true
      # enable_image_builder                        = true
      # enable_s3_bucket                            = true
      # enable_s3_db_backup_bucket                  = true
      # enable_s3_shared_bucket                     = true
      # enable_ssm_command_monitoring               = true
      # enable_vmimport                             = true
      # s3_bucket_name                              = "${local.application_name}-${local.environment}"
      # s3_iam_policies                             = ["EC2S3BucketWriteAndDeleteAccessPolicy"]
    }
  }

  baseline_all_environments = {
    options = {
      # enable_resource_explorer = true
    }

    iam_policies = {
    }

    security_groups = local.security_groups
  }

  account_info = {
    business_unit    = var.networking[0].business-unit
    region           = "eu-west-2"
    vpc_id           = data.aws_vpc.shared.id
    application_name = local.application_name
    mp_environment   = local.environment
    id               = data.aws_caller_identity.current.account_id
  }
  account_config = {
    shared_vpc_cidr    = data.aws_vpc.shared.cidr_block
    private_subnet_ids = data.aws_subnets.shared-private.ids
    public_subnet_ids  = data.aws_subnets.shared-public.ids
    #    ordered_private_subnet_ids    = local.ordered_subnet_ids
    #ordered_subnets               = [local.ordered_subnet_ids]
    data_subnet_ids               = data.aws_subnets.shared-data.ids
    data_subnet_a_id              = data.aws_subnet.data_subnets_a.id
    route53_inner_zone            = data.aws_route53_zone.inner
    route53_network_services_zone = data.aws_route53_zone.network-services
    route53_external_zone         = data.aws_route53_zone.external
    shared_vpc_id                 = data.aws_vpc.shared.id
    kms_keys = {
      ebs_shared     = data.aws_kms_key.ebs_shared.arn
      general_shared = data.aws_kms_key.general_shared.arn
      rds_shared     = data.aws_kms_key.rds_shared.arn
    }
    dns_suffix          = "${local.application_name}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
    internal_dns_suffix = "${local.application_name}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.internal"
  }

  app_config = lookup(local.application_data["accounts"], terraform.workspace) # only use current env

  bastion_config = {}
  app_port       = 80
  # would be good to separate these for the private and public load balancer
  internal_security_group_cidrs = distinct(flatten([
    module.ip_addresses.moj_cidrs.trusted_moj_digital_staff_public,
    module.ip_addresses.moj_cidrs.trusted_moj_enduser_internal,
    module.ip_addresses.moj_cidrs.trusted_mojo_public,
    module.ip_addresses.moj_cidr.ark_dc_external_internet,
    module.ip_addresses.moj_cidr.vodafone_dia_networks,
    module.ip_addresses.moj_cidr.palo_alto_prisma_access_corporate,
    module.ip_addresses.moj_cidr.mojo_azure_landing_zone_egress,
    [
      # Route53 Healthcheck Access Cidrs
      # London Region not support yet, so metrics are not yet publised, can be enabled at later stage for Route53 endpoint monitor
      "15.177.0.0/18",     # GLOBAL Region
      "54.251.31.128/26",  # ap-southeast-1 Region
      "54.255.254.192/26", # ap-southeast-1 Region
      "176.34.159.192/26", # eu-west-1 Region
      "54.228.16.0/26",    # eu-west-1 Region
      "107.23.255.0/26",   # us-east-1 Region
      "54.243.31.192/26"   # us-east-1 Region
    ],
    [
      # Civica secure development environment
      "4.234.27.250/32",
      "213.143.143.69/32",
      "213.143.146.149/32"
    ]
  ]))
  ipv6_cidr_blocks = []

  domain_types = { for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    record = dvo.resource_record_value
    type   = dvo.resource_record_type
    }
  }

  domain                  = local.is-production ? "vcms.probation.service.justice.gov.uk" : "modernisation-platform.service.justice.gov.uk"
  domain_name_main        = [for k, v in local.domain_types : v.name if k == local.domain]
  domain_record_main      = [for k, v in local.domain_types : v.record if k == local.domain]
  domain_type_main        = [for k, v in local.domain_types : v.type if k == local.domain]
  domain_name_sub         = [for k, v in local.domain_types : v.name if k == local.app_url]
  domain_record_sub       = [for k, v in local.domain_types : v.record if k == local.app_url]
  domain_type_sub         = [for k, v in local.domain_types : v.type if k == local.app_url]
  validation_record_fqdns = local.is-development ? [local.domain_name_main[0], local.domain_name_sub[0], local.app_config.legacy_validation_record] : [local.domain_name_main[0], local.domain_name_sub[0]]

  app_url                       = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.${local.domain}" # e.g. vcms.hmpps-development.modernisation-platform.service.justice.gov.uk
  acm_subject_alternative_names = [local.app_url, local.app_config.legacy_url]

}
