locals {

  # baseline config
  test_config = {

    baseline_secretsmanager_secrets = {
      "/oracle/database/T3ONRAU"  = local.database_secretsmanager_secrets
      "/oracle/database/T3ONRBDS" = local.database_secretsmanager_secrets
      "/oracle/database/T3ONRSYS" = local.database_secretsmanager_secrets
    }

    # baseline_ec2_instances = {
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
    # }
    baseline_ec2_autoscaling_groups = {
      test-web-asg = merge(local.defaults_web_ec2, {
        config = merge(local.defaults_web_ec2.config, {
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_web_ec2.instance, {
          instance_type = "t3.large"
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
      test-boe-asg = merge(local.defaults_boe_ec2, {
        config = merge(local.defaults_boe_ec2.config, {
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_boe_ec2.instance, {
          instance_type = "t2.large"
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "onr/DSOS-2682/onr-boe-install"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      })
      test-bods-asg = merge(local.defaults_bods_ec2, {
        config = merge(local.defaults_bods_ec2.config, {
          availability_zone = "${local.region}a"
        })
        instance = merge(local.defaults_bods_ec2.instance, {
          instance_type = "t3.large"
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
      })
    }
  }
}
