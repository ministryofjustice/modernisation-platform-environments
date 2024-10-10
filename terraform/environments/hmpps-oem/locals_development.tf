locals {

  baseline_presets_development = {
    options = {
      enable_ec2_delius_dba_secrets_access = true

      sns_topics = {
        pagerduty_integrations = {
          pagerduty = "hmpps-oem-development"
        }
      }
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    ec2_autoscaling_groups = {
      dev-base-ol85 = {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          force_delete        = true
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        config = {
          ami_name                  = "base_ol_8_5*"
          iam_resource_names_prefix = "ec2-instance"
          instance_profile_policies = [
            "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
            "EC2Default",
            "EC2S3BucketWriteAndDeleteAccessPolicy",
            "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
          ]
          subnet_name = "private"
        }
        instance = {
          disable_api_termination      = false
          instance_type                = "t3.medium"
          key_name                     = "ec2-user"
          vpc_security_group_ids       = ["data-oem"]
          metadata_options_http_tokens = "required"
          monitoring                   = false
        }
        user_data_cloud_init = {
          args = {
            branch       = "main"
            ansible_args = "--tags ec2provision"
          }
          scripts = [ # paths are relative to templates/ dir
            "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
            "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
            "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
          ]
        }
        tags = {
          backup           = "false"
          description      = "For testing our base OL8.5 base image"
          component        = "test"
          os-type          = "Linux"
          server-type      = "base-ol85"
          update-ssm-agent = "patchgroup1"
        }
      }
      dev-endpoint-ol85 = {
        autoscaling_group = {
          desired_capacity    = 0
          max_size            = 1
          force_delete        = true
          vpc_zone_identifier = module.environment.subnets["private"].ids
        }
        config = {
          ami_name                  = "base_ol_8_5*"
          iam_resource_names_prefix = "ec2-instance"
          instance_profile_policies = [
            "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
            "EC2Default",
            "EC2S3BucketWriteAndDeleteAccessPolicy",
            "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
          ]
          subnet_name = "private"
        }
        instance = {
          disable_api_termination      = false
          instance_type                = "t3.medium"
          key_name                     = "ec2-user"
          vpc_security_group_ids       = ["data-oem"]
          metadata_options_http_tokens = "required"
          monitoring                   = false
        }
        user_data_cloud_init = {
          args = {
            branch       = "TM/TM-411/run-endpoint-connection-checks-role"
            ansible_args = "--tags ec2provision"
          }
          scripts = [ # paths are relative to templates/ dir
            "../../../modules/baseline_presets/ec2-user-data/install-ssm-agent.sh",
            "../../../modules/baseline_presets/ec2-user-data/ansible-ec2provision.sh.tftpl",
            "../../../modules/baseline_presets/ec2-user-data/post-ec2provision.sh",
          ]
        }
        tags = {
          backup           = "false"
          description      = "For testing endpoint-monitoring role"
          component        = "test"
          os-type          = "Linux"
          server-type      = "hmpps-oem-endpoint-monitoring"
          update-ssm-agent = "patchgroup1"
        }
      }
    }

    ec2_instances = {
      dev-oem-a = merge(local.ec2_instances.oem, {
        config = merge(local.ec2_instances.oem.config, {
          ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2023-12-07T12-10-49.620Z"
          availability_zone = "eu-west-2a"
        })
        instance = merge(local.ec2_instances.oem.instance, {
          disable_api_termination = true
        })
        user_data_cloud_init = merge(local.ec2_instances.oem.user_data_cloud_init, {
          args = merge(local.ec2_instances.oem.user_data_cloud_init.args, {
            branch = "45027fb7482eb7fb601c9493513bb73658780dda" # 2023-08-11
          })
        })
        tags = merge(local.ec2_instances.oem.tags, {
          oracle-sids = "EMREP DEVRCVCAT"
        })
      })
    }

    secretsmanager_secrets = {
      "/oracle/oem"                = local.secretsmanager_secrets.oem
      "/oracle/database/EMREP"     = local.secretsmanager_secrets.oem
      "/oracle/database/DEVRCVCAT" = local.secretsmanager_secrets.oem
    }
  }
}
