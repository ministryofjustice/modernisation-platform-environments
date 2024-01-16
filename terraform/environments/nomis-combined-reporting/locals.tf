locals {
  business_unit = var.networking[0].business-unit
  region        = "eu-west-2"
  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  baseline_preset_options = {
    enable_application_environment_wildcard_cert = false
    enable_backup_plan_daily_and_weekly          = true
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    enable_ec2_oracle_enterprise_managed_server  = true
    enable_ec2_user_keypair                      = true
    iam_policies_filter                          = ["ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    iam_policies_ec2_default                     = ["EC2S3BucketWriteAndDeleteAccessPolicy", "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"]
    s3_iam_policies                              = ["EC2S3BucketWriteAndDeleteAccessPolicy"]

    # comment this in if you need to resolve FixNGo hostnames
    # route53_resolver_rules = {
    #   outbound-data-and-private-subnets = ["azure-fixngo-domain"]
    # }
  }
  baseline_acm_certificates       = {}
  baseline_cloudwatch_log_groups  = {}
  baseline_ec2_autoscaling_groups = {}
  baseline_ec2_instances          = {}
  baseline_iam_policies = {
    SasTokenRotatorPolicy = {
      description = "Allows updating of secrets in SSM"
      statements = [
        {
          sid    = "RotateSecrets"
          effect = "Allow"
          actions = [
            "ssm:PutParameter",
          ]
          resources = [
            "arn:aws:ssm:*:*:parameter/azure/*",
          ]
        },
        {
          sid    = "EncryptSecrets"
          effect = "Allow"
          actions = [
            "kms:Encrypt",
          ]
          resources = [
            data.aws_kms_key.general_shared.arn,
          ]
        },
      ]
    }
  }
  baseline_iam_roles = {
    SasTokenRotatorRole = {
      assume_role_policy = [{
        effect  = "Allow"
        actions = ["sts:AssumeRoleWithWebIdentity"]
        principals = {
          type        = "Federated"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
        }
        conditions = [
          {
            test     = "StringEquals"
            values   = ["sts.amazonaws.com"]
            variable = "token.actions.githubusercontent.com:aud"
          },
          {
            test     = "StringLike"
            values   = ["repo:ministryofjustice/dso-modernisation-platform-automation:ref:refs/heads/main"]
            variable = "token.actions.githubusercontent.com:sub"
          },
        ]
      }]
      policy_attachments = [
        "SasTokenRotatorPolicy",
      ]
    }
  }
  baseline_iam_service_linked_roles = {}
  baseline_key_pairs                = {}
  baseline_kms_grants               = {}
  baseline_lbs                      = {}
  baseline_rds_instances            = {}
  baseline_route53_resolvers        = {}
  baseline_route53_zones            = { "${local.environment}.reporting.nomis.service.justice.gov.uk" = {} }
  baseline_ssm_parameters           = {}
  baseline_s3_buckets = {
    s3-bucket = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }
  }
  environment_config = local.environment_configs[local.environment]

  baseline_secretsmanager_secrets = {}
}
