locals {
  business_unit       = var.networking[0].business-unit
  region              = "eu-west-2"
  availability_zone_1 = "eu-west-2a"
  availability_zone_2 = "eu-west-2b"

  environment_configs = {
    development   = local.development_config
    test          = local.test_config
    preproduction = local.preproduction_config
    production    = local.production_config
  }
  baseline_environment_config = local.environment_configs[local.environment]

  baseline_acm_certificates = {}

  baseline_cloudwatch_log_groups = merge(
    local.weblogic_cloudwatch_log_groups,
    local.database_cloudwatch_log_groups,
  )

  baseline_ec2_autoscaling_groups   = {}
  baseline_ec2_instances            = {}
  baseline_iam_policies             = {}
  baseline_iam_roles                = {}
  baseline_iam_service_linked_roles = {}
  baseline_key_pairs                = {}
  baseline_kms_grants               = {}
  baseline_lbs                      = {}
  baseline_route53_resolvers        = {}

  baseline_route53_zones = {
    "${local.environment}.nomis.az.justice.gov.uk"      = {}
    "${local.environment}.nomis.service.justice.gov.uk" = {}
  }

  baseline_s3_buckets = {
    s3-bucket = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }
    ec2-image-builder-nomis = {
      custom_kms_key = module.environment.kms_keys["general"].arn
      bucket_policy_v2 = [
        module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
        module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
      ]
      iam_policies = module.baseline_presets.s3_iam_policies
    }
    nomis-db-backup-bucket = {
      custom_kms_key = module.environment.kms_keys["general"].arn
      bucket_policy_v2 = [
        module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
        module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
      ]
      iam_policies = module.baseline_presets.s3_iam_policies
    }
    nomis-audit-archives = {
      custom_kms_key = module.environment.kms_keys["general"].arn
      bucket_policy_v2 = [
        module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
        module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
      ]
      iam_policies = module.baseline_presets.s3_iam_policies
    }
  }

  baseline_security_groups = {
    private-lb = {
      description = "Security group for internal load balancer"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        https = {
          description = "Allow https ingress"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          security_groups = [
            "private-jumpserver",
            module.bastion_linux.bastion_security_group
          ]
          cidr_blocks = local.security_group_cidrs.https
        }
        http7001 = {
          description = "Allow http7001 ingress"
          from_port   = 7001
          to_port     = 7001
          protocol    = "tcp"
          security_groups = [
            "private-jumpserver",
            module.bastion_linux.bastion_security_group
          ]
          cidr_blocks = local.security_group_cidrs.http7xxx
        }
        http7777 = {
          description = "Allow http7777 ingress"
          from_port   = 7777
          to_port     = 7777
          protocol    = "tcp"
          security_groups = [
            "private-jumpserver",
            module.bastion_linux.bastion_security_group
          ]
          cidr_blocks = local.security_group_cidrs.http7xxx
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
          security_groups = []
        }
      }
    }
    private-web = {
      description = "Security group for web servers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        ssh = {
          description = "Allow ssh ingress"
          from_port   = "22"
          to_port     = "22"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.ssh
          security_groups = [
            module.bastion_linux.bastion_security_group
          ]
        }
        http7001 = {
          description = "Allow http7001 ingress"
          from_port   = 7001
          to_port     = 7001
          protocol    = "tcp"
          security_groups = [
            "private-jumpserver",
            "private-lb",
            module.bastion_linux.bastion_security_group
          ]
          cidr_blocks = local.security_group_cidrs.http7xxx
        },
        http7777 = {
          description = "Allow http7777 ingress"
          from_port   = 7777
          to_port     = 7777
          protocol    = "tcp"
          security_groups = [
            "private-jumpserver",
            "private-lb",
            module.bastion_linux.bastion_security_group
          ]
          cidr_blocks = local.security_group_cidrs.http7xxx
        },
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
          security_groups = []
        }
      }
    }
    private-jumpserver = {
      description = "Security group for jumpservers"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        rdp = {
          description = "Allow rdp ingress"
          from_port   = "3389"
          to_port     = "3389"
          protocol    = "TCP"
          security_groups = [
            module.bastion_linux.bastion_security_group
          ]
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
          security_groups = []
        }
      }
    }
    data-db = {
      description = "Security group for databases"
      ingress = {
        all-from-self = {
          description = "Allow all ingress to self"
          from_port   = 0
          to_port     = 0
          protocol    = -1
          self        = true
        }
        ssh = {
          description = "Allow ssh ingress"
          from_port   = "22"
          to_port     = "22"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.ssh
          security_groups = [
            module.bastion_linux.bastion_security_group
          ]
        }
        oracle1521 = {
          description = "Allow oracle database 1521 ingress"
          from_port   = "1521"
          to_port     = "1521"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_db
          security_groups = [
            "private-jumpserver",
            "private-web",
            module.bastion_linux.bastion_security_group
          ]
        }
        oracle3872 = {
          description = "Allow oem agent ingress"
          from_port   = "3872"
          to_port     = "3872"
          protocol    = "TCP"
          cidr_blocks = local.security_group_cidrs.oracle_oem_agent
          security_groups = [
            "private-jumpserver",
            "private-web",
            module.bastion_linux.bastion_security_group
          ]
        }
      }
      egress = {
        all = {
          description     = "Allow all egress"
          from_port       = 0
          to_port         = 0
          protocol        = "-1"
          cidr_blocks     = ["0.0.0.0/0"]
          security_groups = []
        }
      }
    }
  }

  baseline_sns_topics = {}

  autoscaling_schedules_default = {
    "scale_up" = {
      recurrence = "0 7 * * Mon-Fri"
    }
    "scale_down" = {
      desired_capacity = 0
      recurrence       = "0 19 * * Mon-Fri"
    }
  }
}

