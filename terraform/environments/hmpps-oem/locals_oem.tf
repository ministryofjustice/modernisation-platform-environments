locals {

  # Once an account has baseline "enable_ec2_oracle_enterprise_managed_server"
  # enabled and run, or the equivalent terraform to create the 
  # EC2OracleEnterpriseManagementSecretsRole IAM role, add it to this list
  oem_managed_applications = flatten([
    "corporate-staff-rostering-${local.environment}",
    "nomis-${local.environment}",
    "nomis-combined-reporting-${local.environment}",
    "oasys-${local.environment}",
    contains(["development", "test"], local.environment) ? ["delius-core-${local.environment}"] : []
  ])

  oem_share_secret_principal_ids = [
    for key, value in module.environment.account_ids :
    "arn:aws:iam::${value}:role/EC2OracleEnterpriseManagementSecretsRole" if contains(local.oem_managed_applications, key)
  ]

  oem_secret_policy_write = {
    effect = "Allow"
    actions = [
      "secretsmanager:PutSecretValue",
    ]
    principals = {
      type        = "AWS"
      identifiers = ["hmpps-oem-${local.environment}"]
    }
    resources = ["*"]
  }
  oem_secret_policy_read = {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    principals = {
      type        = "AWS"
      identifiers = local.oem_share_secret_principal_ids
    }
    resources = ["*"]
  }
  oem_secretsmanager_secrets = {
    secrets = {
      passwords = {
        description = "passwords only accessible by OEM EC2"
        policy = [
          local.oem_secret_policy_write, # this isn't strictly needed but is added to clear a previous policy
        ]
      }
      shared-passwords = {
        description = "passwords shared with other accounts"
        policy = [
          local.oem_secret_policy_read,
          local.oem_secret_policy_write,
        ]
      }
    }
  }

  oem_ec2_default = {

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default

    config = merge(module.baseline_presets.ec2_instance.config.db, {
      ami_name  = "hmpps_ol_8_5_oracledb_19c_release_2023-08-07T16-14-04.275Z"
      ami_owner = "self"
    })

    instance = merge(module.baseline_presets.ec2_instance.instance.default_db, {
      vpc_security_group_ids = ["data-oem"]
      tags = {
        backup-plan = "daily-and-weekly"
      }
    })

    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    ebs_volumes = {
      "/dev/sdb" = { type = "gp3", label = "app", size = 100 } # /u01
      "/dev/sdc" = { type = "gp3", label = "app", size = 100 } # /u02
      "/dev/sde" = { type = "gp3", label = "data" }            # DATA01
      "/dev/sdf" = { type = "gp3", label = "data" }            # DATA02
      "/dev/sdg" = { type = "gp3", label = "data" }            # DATA03
      "/dev/sdh" = { type = "gp3", label = "data" }            # DATA04
      "/dev/sdi" = { type = "gp3", label = "data" }            # DATA05
      "/dev/sdj" = { type = "gp3", label = "flash" }           # FLASH01
      "/dev/sdk" = { type = "gp3", label = "flash" }           # FLASH02
      "/dev/sds" = { type = "gp3", label = "swap" }
    }

    ebs_volume_config = {
      data  = { total_size = 100 }
      flash = { total_size = 50 }
    }

    route53_records = {
      create_internal_record = true
      create_external_record = true
    }

    secretsmanager_secrets = module.baseline_presets.ec2_instance.secretsmanager_secrets.oracle_19c

    tags = {
      ami                  = "hmpps_ol_8_5_oracledb_19c" # not including as hardening role seems to cause an issue
      backup               = "false"                     # opt out of mod platform default backup plan
      component            = "data"
      instance-scheduling  = "skip-scheduling"
      server-type          = "hmpps-oem"
      os-type              = "Linux"
      os-major-version     = 8
      os-version           = "OL 8.5"
      licence-requirements = "Oracle Enterprise Management"
    }
  }
}
