locals {

  # baseline config
  test_config = {

    baseline_secretsmanager_secrets = {
      "/ec2/onr-web/test"        = local.web_secretsmanager_secrets
      "/ec2/onr-boe/t2"          = local.boe_secretsmanager_secrets
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
              "arn:aws:secretsmanager:*:*:secret:/ec2/onr-web/test/*",
              "arn:aws:secretsmanager:*:*:secret:/ec2/onr-boe/t2/*",
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
      #   test-db = merge(local.defaults_onr_db_ec2 ,{
      #     config = merge(local.defaults_onr_db_ec2.config, {
      #       ami_name          = "hmpps_ol_8_5_oracledb_19c_release_2024-*"
      #       availability_zone = "${local.region}a"
      #     })
      #     instance = merge(local.defaults_onr_db_ec2.instance, {
      #       instance_type                = "r6i.xlarge"
      #       metadata_options_http_tokens = "optional"
      #     })
      #     user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible
      #     secretsmanager_secrets = module.baseline_presets.ec2_instance.secretsmanager_secrets.oracle_19c
      #     tags = merge(local.defaults_onr_db_ec2.tags, {
      #       ami         = "base_ol_8_5"
      #       server-type = "onr-db-test"
      #       oracle-sids = "T3ONRAUD T3ONRBDS T3ONRSYS"
      #       description = "ONR db for BOE Enterprise XI INSTALLATION TESTING ONLY"
      #     })
      #   })
    }
    baseline_ec2_autoscaling_groups = {
      test-web-asg = merge(local.defaults_web_ec2, {
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
            branch = "onr/dsos-2730/ansible-base"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      })
      # test-boe-asg = merge(local.defaults_boe_ec2, {
      #   config = merge(local.defaults_boe_ec2.config, {
      #     instance_profile_policies = setunion(local.defaults_boe_ec2.config.instance_profile_policies, [
      #       "Ec2SecretPolicy",
      #     ])
      #     availability_zone = "${local.region}a"
      #   })
      #   instance = merge(local.defaults_boe_ec2.instance, {
      #     instance_type = "m4.xlarge"
      #   })
      #   user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
      #     args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
      #       branch = "onr/DSOS-2682/onr-boe-install"
      #     })
      #   })
      #   autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
      #     desired_capacity = 0
      #   })
      #   autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      #   tags = merge(local.defaults_boe_ec2.tags, {
      #     oasys-national-reporting-environment = "t2"
      #   })
      # })
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
