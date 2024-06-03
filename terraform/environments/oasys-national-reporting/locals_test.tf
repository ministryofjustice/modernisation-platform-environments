locals {

  # baseline config
  test_config = {

    baseline_secretsmanager_secrets = {
      "/ec2/onr-bods/t2"         = local.bods_secretsmanager_secrets
      "/ec2/onr-boe/t2"          = local.boe_secretsmanager_secrets
      "/ec2/onr-web/t2"          = local.web_secretsmanager_secrets
      "/oracle/database/T2BOSYS" = local.database_secretsmanager_secrets
      "/oracle/database/T2BOAUD" = local.database_secretsmanager_secrets

    }

    baseline_iam_policies = {
      Ec2SecretPolicy = {
        description = "Permissions required for secret value access by instances"
        statements = [
          {
            effect = "Allow"
            actions = [
              "secretsmanager:GetSecretValue",
              "secretsmanager:PutSecretValue",
            ]
            resources = [
              "arn:aws:secretsmanager:*:*:secret:/ec2/onr-boe/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/onr-bods/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/onr-web/t2/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*",
            ]
          }
        ]
      }
    }

    baseline_ec2_instances = {
      t2-onr-bods-1-a = merge(local.defaults_bods_ec2, {
        config = merge(local.defaults_bods_ec2.config, {
          availability_zone             = "${local.region}a"
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = module.baseline_presets.ec2_instance.user_data_raw["user-data-pwsh"]
        })
        instance = merge(local.defaults_bods_ec2.instance, {
          instance_type = "m4.xlarge"
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        # volumes are a direct copy of BODS in NCR
        ebs_volumes = merge(local.defaults_bods_ec2.ebs_volumes, {
          "/dev/sda1" = { type = "gp3", size = 100 }
          "/dev/sdb"  = { type = "gp3", size = 100 }
          "/dev/sdc"  = { type = "gp3", size = 100 }
          "/dev/sds"  = { type = "gp3", size = 100 }
        })
      })
      t2-onr-boe-1-a = merge(local.defaults_boe_ec2, {
        config = merge(local.defaults_boe_ec2.config, {
          instance_profile_policies = setunion(local.defaults_boe_ec2.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_boe_ec2.instance, {
          instance_type = "m4.xlarge"
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        tags = merge(local.defaults_boe_ec2.tags, {
          oasys-national-reporting-environment = "t2"
        })
      })
      # t2-onr-web-1-a = merge(local.defaults_web_ec2, {
      #   config = merge(local.defaults_web_ec2.config, {
      #     instance_profile_policies = setunion(local.defaults_web_ec2.config.instance_profile_policies, [
      #       "Ec2SecretPolicy",
      #     ])
      #     availability_zone = "${local.region}a"
      #   })
      #   instance = merge(local.defaults_web_ec2.instance, {
      #     instance_type = "m4.large"
      #   })
      #   user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      #   tags = merge(local.defaults_web_ec2.tags, {
      #     oasys-national-reporting-environment = "t2"
      #   })
      # })
    }
    baseline_ec2_autoscaling_groups = {
      t2-test-web-asg = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          instance_profile_policies = setunion(local.defaults_web_ec2.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "m4.large"
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "onr/DSOS-2731/onr-web-silent-install"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = merge(local.defaults_web_ec2.tags, {
          oasys-national-reporting-environment = "t2"
        })
      })
      # IMPORTANT: this is just for testing at the moment
      t2-rhel6-web-asg = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          instance_profile_policies = setunion(local.defaults_web_ec2.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
          availability_zone = "${local.region}a"
          ami_owner         = "374269020027"
          ami_name          = "base_rhel_6_10_*"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type                = "m4.large"
          metadata_options_http_tokens = "optional" # required as Rhel 6 cloud-init does not support IMDSv2
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "onr/DSOS-2731/onr-web-silent-install"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = merge(local.defaults_web_ec2.tags, {
          ami                                  = "base_rhel_6_10"
          oasys-national-reporting-environment = "t2"
        })
      })
      # TODO: this is just for testing, remove when not needed
      t2-test-boe-asg = merge(local.defaults_boe_ec2, {
        config = merge(local.defaults_boe_ec2.config, {
          instance_profile_policies = setunion(local.defaults_boe_ec2.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_boe_ec2.instance, {
          instance_type = "m4.xlarge"
        })
        user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = merge(local.defaults_boe_ec2.tags, {
          oasys-national-reporting-environment = "t2"
        })
      })
      test-bods-asg = merge(local.defaults_bods_ec2, {
        config = merge(local.defaults_bods_ec2.config, {
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_bods_ec2.instance, {
          instance_type = "m4.xlarge"
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      })
      test-onr-client-a = merge(local.jumpserver_ec2, {
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
      })
    }
    baseline_route53_zones = {
      "test.reporting.oasys.service.justice.gov.uk" = {}
    }
  }
}
