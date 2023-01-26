#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------
# OLD NAMING - DEPRECATE
#------------------------------------------------------------------------------

module "database" {
  source = "./modules/database"

  providers = {
    aws.core-vpc = aws.core-vpc # core-vpc-(environment) holds the networking for all accounts
  }

  for_each = {}

  name = each.key

  ami_name           = each.value.ami_name
  asm_data_capacity  = each.value.asm_data_capacity
  asm_flash_capacity = each.value.asm_flash_capacity
  description        = each.value.description

  ami_owner              = try(each.value.ami_owner, local.environment_management.account_ids["nomis-test"])
  asm_data_iops          = try(each.value.asm_data_iops, null)
  asm_data_throughput    = try(each.value.asm_data_throughput, null)
  asm_flash_iops         = try(each.value.asm_flash_iops, null)
  asm_flash_throughput   = try(each.value.asm_data_throughput, null)
  oracle_app_disk_size   = try(each.value.oracle_app_disk_size, null)
  extra_ingress_rules    = try(each.value.extra_ingress_rules, null)
  termination_protection = try(each.value.termination_protection, null)
  instance_type          = try(each.value.instance_type, null)
  oracle_sids            = try(each.value.oracle_sids, null)
  restored_from_snapshot = try(each.value.restored_from_snapshot, false)

  common_security_group_id  = aws_security_group.data.id
  instance_profile_policies = concat(local.ec2_common_managed_policies, [aws_iam_policy.s3_db_backup_bucket_access.arn])
  key_name                  = aws_key_pair.ec2-user.key_name

  application_name = local.application_name
  business_unit    = local.business_unit
  environment      = local.environment
  subnet_set       = local.subnet_set
  tags             = merge(local.tags, try(each.value.tags, {}))
}

#------------------------------------------------------------------------------
# EC2 Instances following naming convention
#------------------------------------------------------------------------------
# NEW NAMING

# SET TAGS
locals {

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
      vpc_security_group_ids       = [aws_security_group.data.id]
    }

    user_data_cloud_init = {
      args = {
        restored_from_snapshot = false
      }
      scripts = [
        "ansible-ec2provision.sh.tftpl",
        "oracle_init.sh.tftpl",
        "ansible-ec2provisiondata.sh.tftpl"
      ]
      write_files = {}
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
  source = "../../modules/ec2_instance"

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
  availability_zone  = local.availability_zone
  subnet_set         = local.subnet_set
  subnet_name        = "data"
  tags               = merge(local.tags, local.database.tags, try(each.value.tags, {}))
  account_ids_lookup = local.environment_management.account_ids

  ansible_repo         = "modernisation-platform-configuration-management"
  ansible_repo_basedir = "ansible"
  branch               = try(each.value.branch, "main")
}

# Delete in next PR
resource "aws_security_group" "database_common" {
  #checkov:skip=CKV2_AWS_5:skip "Ensure that Security Groups are attached to another resource" - attached in nomis-stack module
  description = "Common security group for database instances"
  name        = "database-common"
  vpc_id      = module.environment.vpc.id
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
