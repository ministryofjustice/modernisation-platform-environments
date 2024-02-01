# Terraform configuration data for environments in delius-core development account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  account_config_dev = {
    shared_vpc_cidr               = data.aws_vpc.shared.cidr_block
    private_subnet_ids            = data.aws_subnets.shared-private.ids
    public_subnet_ids             = data.aws_subnets.shared-public.ids
    ordered_private_subnet_ids    = local.ordered_subnet_ids
    data_subnet_ids               = data.aws_subnets.shared-data.ids
    data_subnet_a_id              = data.aws_subnet.data_subnets_a.id
    route53_inner_zone_info       = data.aws_route53_zone.inner
    route53_network_services_zone = data.aws_route53_zone.network-services
    route53_external_zone         = data.aws_route53_zone.external
    shared_vpc_id                 = data.aws_vpc.shared.id
    kms_keys = {
      ebs_shared     = data.aws_kms_key.ebs_shared.arn
      general_shared = data.aws_kms_key.general_shared.arn
      rds_shared     = data.aws_kms_key.rds_shared.arn
    }
  }

  environment_config_dev = {
    migration_environment_private_cidr = ["10.162.32.0/22", "10.162.36.0/22", "10.162.40.0/22"]
    migration_environment_db_cidr      = ["10.162.44.0/24", "10.162.45.0/24", "10.162.46.0/25"]
    legacy_engineering_vpc_cidr        = "10.161.98.0/25"
    ec2_user_ssh_key                   = file("${path.module}/files/.ssh/${terraform.workspace}/ec2-user.pub")
    homepage_path                      = "/"
  }

  ldap_config_dev = {
    name                        = "ldap"
    encrypted                   = true
    migration_source_account_id = local.application_data.accounts[local.environment].migration_source_account_id
    migration_lambda_role       = "ldap-data-migration-lambda-role"
    efs_throughput_mode         = "bursting"
    efs_provisioned_throughput  = null
    efs_backup_schedule         = "cron(0 19 * * ? *)",
    efs_backup_retention_period = "30"
    port                        = 389
  }

  db_config_dev = [{
    name           = "primarydb"
    ami_name_regex = "^delius_core_ol_8_5_oracle_db_19c_"
    user_data_raw = base64encode(
      templatefile(
        "${path.module}/templates/userdata.sh.tftpl",
        {
          branch               = local.db_config.user_data_param.branch
          ansible_repo         = local.db_config.user_data_param.ansible_repo
          ansible_repo_basedir = local.db_config.user_data_param.ansible_repo_basedir
          ansible_args         = local.db_config.user_data_param.ansible_args
        }
      )
    )

    instance = {
      instance_type           = "r6i.xlarge"
      monitoring              = false
      vpc_security_group_ids  = []
      disable_api_termination = true
    }

    ebs_volumes = {
      kms_key_id = data.aws_kms_key.ebs_shared.arn
      tags       = local.tags
      iops       = 3000
      throughput = 125
      root_volume = {
        volume_type = "gp3"
        volume_size = 30
      }
      ebs_non_root_volumes = {
        "/dev/sdb" = {
          # /u01 oracle app disk
          volume_type = "gp3"
          volume_size = 200
          no_device   = false
        }
        "/dev/sdc" = {
          # /u02 oracle app disk
          volume_type = "gp3"
          volume_size = 100
          no_device   = false
        }
        "/dev/sds" = {
          # swap disk
          volume_type = "gp3"
          volume_size = 4
          no_device   = false
        }
        "/dev/sde" = {
          # oracle asm disk DATA01
          volume_type = "gp3"
          volume_size = 500
          no_device   = false
        }
        "/dev/sdf" = {
          # oracle asm disk DATA02
          no_device = true
        }
        "/dev/sdg" = {
          # oracle asm disk DATA03
          no_device = true
        }
        "/dev/sdh" = {
          # oracle asm disk DATA04
          no_device = true
        }
        "/dev/sdi" = {
          # oracle asm disk DATA05
          no_device = true
        }
        "/dev/sdj" = {
          # oracle asm disk FLASH01
          volume_type = "gp3"
          volume_size = 500
          no_device   = false
        }
        "/dev/sdk" = {
          # oracle asm disk FLASH02
          no_device = true
        }
      }
    }
    route53_records = {
      create_internal_record = true
      create_external_record = false
    }
    },
    {
      name           = "standbydb1"
      ami_name_regex = "^delius_core_ol_8_5_oracle_db_19c_"
      user_data_raw = base64encode(
        templatefile(
          "${path.module}/templates/userdata.sh.tftpl",
          {
            branch               = local.db_config.user_data_param.branch
            ansible_repo         = local.db_config.user_data_param.ansible_repo
            ansible_repo_basedir = local.db_config.user_data_param.ansible_repo_basedir
            ansible_args         = local.db_config.user_data_param.ansible_args
          }
        )
      )

      instance = {
        instance_type           = "r6i.xlarge"
        monitoring              = false
        vpc_security_group_ids  = []
        disable_api_termination = true
      }

      ebs_volumes = {
        kms_key_id = data.aws_kms_key.ebs_shared.arn
        tags       = local.tags
        iops       = 3000
        throughput = 125
        root_volume = {
          volume_type = "gp3"
          volume_size = 30
          no_device   = false
        }
        ebs_non_root_volumes = {
          "/dev/sdb" = {
            # /u01 oracle app disk
            volume_type = "gp3"
            volume_size = 200
            no_device   = false
          }
          "/dev/sdc" = {
            # /u02 oracle app disk
            volume_type = "gp3"
            volume_size = 100
            no_device   = false
          }
          "/dev/sds" = {
            # swap disk
            volume_type = "gp3"
            volume_size = 4
            no_device   = false
          }
          "/dev/sde" = {
            # oracle asm disk DATA01
            volume_type = "gp3"
            volume_size = 500
            no_device   = false
          }
          "/dev/sdf" = {
            # oracle asm disk DATA02
            no_device = true
          }
          "/dev/sdg" = {
            # oracle asm disk DATA03
            no_device = true
          }
          "/dev/sdh" = {
            # oracle asm disk DATA04
            no_device = true
          }
          "/dev/sdi" = {
            # oracle asm disk DATA05
            no_device = true
          }
          "/dev/sdj" = {
            # oracle asm disk FLASH01
            volume_type = "gp3"
            volume_size = 500
            no_device   = false
          }
          "/dev/sdk" = {
            # oracle asm disk FLASH02
            no_device = true
          }
        }
      }
      route53_records = {
        create_internal_record = true
        create_external_record = false
      }
    }
  ]

  weblogic_config_dev = {
    name                          = "weblogic"
    frontend_service_name         = "weblogic"
    frontend_fully_qualified_name = "${local.application_name}-dev-${local.frontend_service_name}"
    frontend_image_tag            = "5.7.6"
    frontend_container_port       = 8080
    frontend_url_suffix           = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
    db_service_name               = "testing-db"
    db_fully_qualified_name       = "${local.application_name}-${local.db_service_name}"
    db_image_tag                  = "5.7.4"
    db_port                       = 1521
    db_name                       = "MODNDA"
  }

  bastion_config_dev = {
    business_unit           = local.vpc_name
    subnet_set              = local.subnet_set
    environment             = local.environment
    extra_user_data_content = "yum install -y openldap-clients"
  }

  delius_db_container_config_dev = {
    image_tag            = "5.7.4"
    image_name           = "delius-core-testing-db"
    fully_qualified_name = "testing-db"
    port                 = 1521
    name                 = "MODNDA"
  }
}
