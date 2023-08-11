# Terraform configuration data for environments in delius-core development account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  account_config_dev = {
    shared_vpc_cidr               = data.aws_vpc.shared.cidr_block
    private_subnet_ids            = data.aws_subnets.shared-private.ids
    data_subnet_ids               = data.aws_subnets.shared-data.ids
    data_subnet_a_id              = data.aws_subnet.data_subnets_a.id
    route53_inner_zone_info       = data.aws_route53_zone.inner
    route53_network_services_zone = data.aws_route53_zone.network-services
    route53_external_zone         = data.aws_route53_zone.external
    general_shared_kms_key_arn    = data.aws_kms_key.general_shared.arn
    shared_vpc_id                 = data.aws_vpc.shared.id
  }

  environment_config_dev = {
    migration_environment_vpc_cidr = "10.161.20.0/22"
    ec2_user_ssh_key               = file("${path.module}/files/.ssh/${terraform.workspace}-dev/ec2-user.pub")
  }

  ldap_config_dev = {
    name                        = try(local.ldap_config_lower_environments.name, "ldap")
    migration_source_account_id = local.ldap_config_lower_environments.migration_source_account_id
    migration_lambda_role       = local.ldap_config_lower_environments.migration_lambda_role
    efs_throughput_mode         = local.ldap_config_lower_environments.efs_throughput_mode
    efs_provisioned_throughput  = local.ldap_config_lower_environments.efs_provisioned_throughput
    efs_backup_schedule         = "cron(0 19 * * ? *)",
    efs_backup_retention_period = "30"
  }

  db_config_dev = {
    name           = try(local.db_config_lower_environments.name, "db")
    ami_name_regex = local.db_config_lower_environments.ami_name_regex
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
    instance = merge(local.db_config_lower_environments.instance, {
      instance_type = "r6i.xlarge"
      monitoring    = false
    })

    ebs_volumes_copy_all_from_ami = false
    ebs_volumes = {
      "/dev/sda1" = { # root volume
        label = "root",
        size  = 30,
        type  = "gp3"
      }
    }
    # ebs_volumes = merge(local.db_config.ebs_volumes, {
    #   "/dev/sda1" = { # root volume
    #     label = "root",
    #     size  = 30,
    #     type  = "gp3"
    #   },
    #   "/dev/sdb" = { # /u01 oracle app disk
    #     label = "u01",
    #     size  = 200,
    #     type  = "gp3"
    #   },
    #   "/dev/sdc" = { # /u02 oracle app disk
    #     label = "u02",
    #     size  = 100,
    #     type  = "gp3"
    #   },
    #   "/dev/sds" = { # swap disk
    #     label = "swap",
    #     size  = 4,
    #     type  = "gp3"
    #   },
    #   "/dev/sde" = { # oracle asm disk DATA01
    #     label = "asm_data01",
    #     size  = 500,
    #     type  = "gp3"
    #   },
    #   "/dev/sdf" = { # oracle asm disk DATA02 -- need to set to no_device to ensure terraform doesn't create
    #     label = "asm_data02",
    #     size  = 1,
    #     type  = "gp3"
    #   },
    #   "/dev/sdg" = { # oracle asm disk DATA03 -- need to set to no_device to ensure terraform doesn't create
    #     label = "asm_data03",
    #     size  = 1,
    #     type  = "gp3"
    #   },
    #   "/dev/sdh" = { # oracle asm disk DATA04 -- need to set to no_device to ensure terraform doesn't create
    #     label = "asm_data04",
    #     size  = 1,
    #     type  = "gp3"
    #   },
    #   "/dev/sdi" = { # oracle asm disk DATA05 -- need to set to no_device to ensure terraform doesn't create
    #     label = "asm_data05",
    #     size  = 1,
    #     type  = "gp3"
    #   },
    #   "/dev/sdj" = { # oracle asm disk FLASH01
    #     label = "asm_flash01",
    #     size  = 500,
    #     type  = "gp3"
    #   },
    #   "/dev/sdk" = { # oracle asm disk FLASH02 -- need to set to no_device to ensure terraform doesn't create
    #     label = "asm_flash02",
    #     size  = 1,
    #     type  = "gp3"
    #   },
    # })
    ebs_volume_config = {}
    #ebs_volume_config = merge(local.db_config.ebs_volume_config, {
    #  data  = 
    #  {
    #    total_size = 500 
    #  }
    #  flash = { 
    #    total_size = 50 
    #  }
    #})
    route53_records = {
      create_internal_record = true
      create_external_record = false
    }
  }

  weblogic_config_dev = {
    name                          = try(local.weblogic_config_lower_environments.name, "weblogic")
    frontend_service_name         = try(local.weblogic_config_lower_environments.frontend_service_name, "weblogic")
    frontend_fully_qualified_name = try(local.weblogic_config_lower_environments.frontend_fully_qualified_name, "${local.application_name}-${local.frontend_service_name}")
    frontend_image_tag            = try(local.weblogic_config_lower_environments.frontend_image_tag, "5.7.6")
    frontend_container_port       = try(local.weblogic_config_lower_environments.frontend_container_port, 8080)
    frontend_url_suffix           = try(local.weblogic_config_lower_environments.frontend_url_suffix, "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk")
    db_service_name               = "testing-db"
    db_fully_qualified_name       = "${local.application_name}-${local.db_service_name}"
    db_image_tag                  = "5.7.4"
    db_port                       = 1521
    db_name                       = "MODNDA"
  }

  delius_db_container_config = {
    image_tag            = "5.7.4"
    image_name           = "delius-core-testing-db"
    fully_qualified_name = "${local.application_name}-${local.db_service_name}"
    db_port              = 1521
    db_name              = "MODNDA"
  }
}
