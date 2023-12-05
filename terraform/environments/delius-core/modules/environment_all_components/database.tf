module "oracle_db" {
  source         = "../components/oracle_db"
  account_config = var.account_config
  db_ami = {
    name_regex = "^delius_core_ol_8_5_oracle_db_19c_"
    owners     = [var.platform_vars.environment_management.account_ids["core-shared-services-production"]]
  }
  db_name = "primary"
  ebs_volumes = {
    kms_key_id = var.account_config.kms_keys.ebs_shared
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
  env_name           = var.env_name
  environment_config = var.environment_config
  subnet_id          = var.account_config.private_subnet_ids[0]
  tags               = var.tags
  user_data = base64encode(
    templatefile(
      "${path.module}/templates/userdata.sh.tftpl",
      {
        branch               = "main"
        ansible_repo         = "modernisation-platform-configuration-management"
        ansible_repo_basedir = "ansible"
        ansible_args         = "oracle_19c_install"
      }
    )
  )

  ec2_key_pair_name = aws_key_pair.environment_ec2_user_key_pair.key_name

  providers = {
    aws.bucket-replication    = aws
    aws.core-vpc              = aws.core-vpc
    aws.core-network-services = aws.core-network-services
  }
}