#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------

# Use `s3-db-restore-dir` tag to trigger a restore from backup. See
# https://github.com/ministryofjustice/modernisation-platform-configuration-management/blob/main/ansible/roles/db-restore
#
# Use `fixngo-connection-target` to monitor connectivity to a target in FixNGo.  See
# https://github.com/ministryofjustice/modernisation-platform-configuration-management/tree/main/ansible/roles/oracle-db-monitoring

locals {
  database_cloudwatch_metric_alarms = {
    oracle-db-disconnected = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "5"
      datapoints_to_alarm = "5"
      metric_name         = "collectd_exec_value"
      namespace           = "CWAgent"
      period              = "60"
      statistic           = "Average"
      threshold           = "1"
      alarm_description   = "Oracle db connection to a particular SID is not working. See: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4294246698/Oracle+db+connection+alarm for remediation steps."
      dimensions = {
        instance = "db_connected"
      }
    }
    oracle-batch-failure = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "5"
      datapoints_to_alarm = "5"
      metric_name         = "collectd_exec_value"
      namespace           = "CWAgent"
      period              = "60"
      statistic           = "Average"
      threshold           = "1"
      treat_missing_data  = "notBreaching"
      alarm_description   = "Oracle db has recorded a failed batch status. See: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4295000327/Batch+Failure for remediation steps."
      dimensions = {
        instance = "nomis_batch_failure_status"
      }
    }
    oracle-long-running-batch = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "5"
      datapoints_to_alarm = "5"
      metric_name         = "collectd_exec_value"
      namespace           = "CWAgent"
      period              = "60"
      statistic           = "Average"
      threshold           = "1"
      treat_missing_data  = "notBreaching"
      alarm_description   = "Oracle db has recorded a long-running batch status. See: https://dsdmoj.atlassian.net/wiki/spaces/DSTT/pages/4325966186/Long+Running+Batch for remediation steps."
      dimensions = {
        instance = "nomis_long_running_batch"
      }
    }
    oracleasm-service = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "3"
      namespace           = "CWAgent"
      metric_name         = "collectd_exec_value"
      period              = "60"
      statistic           = "Average"
      threshold           = "1"
      alarm_description   = "oracleasm service has stopped"
      dimensions = {
        instance = "oracleasm"
      }
    }
    oracle-ohasd-service = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "3"
      namespace           = "CWAgent"
      metric_name         = "collectd_exec_value"
      period              = "60"
      statistic           = "Average"
      threshold           = "1"
      alarm_description   = "oracleasm service has stopped"
      dimensions = {
        instance = "oracle_ohasd"
      }
    }
    fixngo-connection = {
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = "3"
      namespace           = "CWAgent"
      metric_name         = "collectd_exec_value"
      period              = "60"
      statistic           = "Average"
      threshold           = "1"
      alarm_description   = "this EC2 instance no longer has a connection to the Oracle Enterprise Manager in FixNGo of the connection-target machine"
      dimensions = {
        instance = "fixngo_connected" # required dimension value for this metric
      }
    }
  }
  database_cloudwatch_metric_alarms_lists = {
    database = {
      parent_keys = [
        "ec2_default",
        "ec2_linux_default",
        "ec2_linux_with_collectd_default"
      ]
      alarms_list = [
        { key = "database", name = "oracle-db-disconnected" },
        { key = "database", name = "oracle-batch-failure" },
        { key = "database", name = "oracle-long-running-batch" },
        { key = "database", name = "oracleasm-service" },
        { key = "database", name = "oracle-ohasd-service" },
      ]
    }
    fixngo_connection = {
      parent_keys = []
      alarms_list = [
        { key = "database", name = "fixngo-connection" },
      ]
    }
  }

  database = {

    # server-type and nomis-environment auto set by module
    tags = {
      component            = "data"
      os-type              = "Linux"
      os-major-version     = 7
      os-version           = "RHEL 7.9"
      licence-requirements = "Oracle Database"
      ami                  = "nomis_rhel_7_9_oracledb_11_2"
      "Patch Group"        = "RHEL"
    }

    instance = {
      disable_api_termination      = false
      instance_type                = "r6i.xlarge"
      key_name                     = aws_key_pair.ec2-user.key_name
      metadata_options_http_tokens = "optional" # the Oracle installer cannot accommodate a token
      monitoring                   = true
      vpc_security_group_ids = [
        aws_security_group.data.id, # TODO: remove once weblogic servers refreshed
        module.baseline.security_groups["data-db"].id,
      ]
    }

    user_data_cloud_init = {
      args = {
        branch               = "main"
        ansible_repo         = "modernisation-platform-configuration-management"
        ansible_repo_basedir = "ansible"
        ansible_args         = "--tags ec2provision"
      }
      scripts = [
        "ansible-ec2provision.sh.tftpl",
      ]
    }

    ebs_volumes = {
      "/dev/sdb" = { label = "app" }   # /u01
      "/dev/sdc" = { label = "app" }   # /u02
      "/dev/sde" = { label = "data" }  # DATA01
      "/dev/sdf" = { label = "data" }  # DATA02
      "/dev/sdg" = { label = "data" }  # DATA03
      "/dev/sdh" = { label = "data" }  # DATA04
      "/dev/sdi" = { label = "data" }  # DATA05
      "/dev/sdj" = { label = "flash" } # FLASH01
      "/dev/sdk" = { label = "flash" } # FLASH02
      "/dev/sds" = { label = "swap" }
    }

    ebs_volume_config = {
      data = {
        iops       = 3000
        throughput = 125
      }
      flash = {
        iops       = 3000
        throughput = 125
      }
    }

    route53_records = {
      create_internal_record = true
      create_external_record = true
    }

    ssm_parameters = {
      ASMSYS = {
        random = {
          length  = 30
          special = false
        }
        description = "ASMSYS password"
      }
      ASMSNMP = {
        random = {
          length  = 30
          special = false
        }
        description = "ASMSNMP password"
      }
    }
  }
}

module "db_ec2_instance" {
  #checkov:skip=CKV_AWS_79:Oracle cannot accommodate a token
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ec2-instance?ref=v1.0.1"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = local.environment_config.databases

  name = each.key

  ami_name                      = each.value.ami_name
  ami_owner                     = try(each.value.ami_owner, "core-shared-services-production")
  instance                      = merge(local.database.instance, lookup(each.value, "instance", {}))
  user_data_cloud_init          = merge(local.database.user_data_cloud_init, lookup(each.value, "user_data_cloud_init", {}))
  ebs_volumes_copy_all_from_ami = try(each.value.ebs_volumes_copy_all_from_ami, true)
  ebs_kms_key_id                = module.environment.kms_keys["ebs"].arn
  ebs_volume_config             = merge(local.database.ebs_volume_config, lookup(each.value, "ebs_volume_config", {}))
  ebs_volumes                   = { for k, v in local.database.ebs_volumes : k => merge(v, try(each.value.ebs_volumes[k], {})) }
  ssm_parameters_prefix         = "database/"
  ssm_parameters                = merge(local.database.ssm_parameters, lookup(each.value, "ssm_parameters", {}))
  route53_records               = merge(local.database.route53_records, lookup(each.value, "route53_records", {}))

  iam_resource_names_prefix = "ec2-database"
  instance_profile_policies = concat(local.ec2_common_managed_policies, [aws_iam_policy.s3_db_backup_bucket_access.arn])

  business_unit      = local.business_unit
  application_name   = local.application_name
  environment        = local.environment
  region             = local.region
  availability_zone  = local.availability_zone_1
  subnet_id          = module.environment.subnet["data"][local.availability_zone_1].id
  tags               = merge(local.tags, local.database.tags, try(each.value.tags, {}))
  account_ids_lookup = local.environment_management.account_ids

  cloudwatch_metric_alarms = merge(module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso"].database,
    lookup(each.value, "cloudwatch_metric_alarms", {})
  )
}

#------------------------------------------------------------------------------
# Policy for PUT, GET, LIST access to database backups
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "s3_db_backup_bucket_access" {
  #tfsec:ignore:aws-iam-no-policy-wildcards:need to be able to write database backups to specific bucket
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [module.nomis-db-backup-bucket.bucket.arn,
    "${module.nomis-db-backup-bucket.bucket.arn}/*"]
  }
}

resource "aws_iam_policy" "s3_db_backup_bucket_access" {
  name        = "s3-db-backup-bucket-access"
  path        = "/"
  description = "Policy for access to database backup bucket"
  policy      = data.aws_iam_policy_document.s3_db_backup_bucket_access.json
  tags = merge(
    local.tags,
    {
      Name = "s3-db-backup-bucket-access"
    },
  )
}

#------------------------------------------------------------------------------
# Upload audit archive dumps to s3
#------------------------------------------------------------------------------

resource "aws_ssm_document" "audit_s3_upload" {
  name            = "UploadAuditArchivesToS3"
  document_type   = "Command"
  document_format = "YAML"
  content         = templatefile("${path.module}/ssm-documents/templates/s3auditupload.yaml.tftmpl", { bucket = module.nomis-audit-archives.bucket.id, branch = "main" })
  target_type     = "/AWS::EC2::Instance"

  tags = merge(
    local.tags,
    {
      Name = "Upload Audit Archives to S3"
    },
  )
}
