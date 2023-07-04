# nomis-test environment settings
locals {

  # baseline config
  test_config = {


    baseline_acm_certificates = {
      nomis_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.${local.environment}.nomis.service.justice.gov.uk",
          "*.${local.environment}.nomis.az.justice.gov.uk",
          "*.hmpp-azdt.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms_lists_with_actions["dso_pagerduty"].acm_default
        tags = {
          description = "wildcard cert for nomis ${local.environment} domains"
        }
      }
    }

    baseline_ssm_parameters = {
      # add into code once for_each issue resolved
      #      "t1-nomis-db-1-b"         = local.database_ssm_parameters
      #      "t1-nomis-db-1-b/CNOMT1"  = local.database_instance_ssm_parameters
      #      "t1-nomis-db-1-b/NDHT1"   = local.database_instance_ssm_parameters
      #      "t1-nomis-db-1-b/TRDATT1" = local.database_instance_ssm_parameters
      #      "t2-nomis-db-1-b"         = local.database_ssm_parameters
      #      "t2-nomis-db-1-b/CNOMT2"  = local.database_instance_ssm_parameters
      #      "t2-nomis-db-1-b/NDHT2"   = local.database_instance_ssm_parameters
      #      "t2-nomis-db-1-b/TRDATT2" = local.database_instance_ssm_parameters
      #      "t3-nomis-db-1"           = local.database_ssm_parameters

      #      "t1-nomis-web-a" = local.weblogic_ssm_parameters
      #      "t1-nomis-web-b" = local.weblogic_ssm_parameters
      #      "t2-nomis-web-a" = local.weblogic_ssm_parameters
      #      "t2-nomis-web-b" = local.weblogic_ssm_parameters

      #      "t1-nomis-xtag-a" = local.xtag_ssm_parameters
    }

    baseline_ec2_autoscaling_groups = {
      # blue deployment
      t1-nomis-web-a = merge(local.weblogic_ec2_a, {
        tags = merge(local.weblogic_ec2_a.tags, {
          nomis-environment    = "t1"
          oracle-db-hostname-a = "t1nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t1nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T1CNOM"
        })
      })

      # green deployment
      t1-nomis-web-b = merge(local.weblogic_ec2_b, {
        tags = merge(local.weblogic_ec2_b.tags, {
          nomis-environment    = "t1"
          oracle-db-hostname-a = "t1nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t1nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T1CNOM"
        })
      })

      t1-nomis-xtag-a = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_rhel_7_9_*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type          = "t2.large"
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 1
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description          = "For testing XTAG image"
          ami                  = "base_rhel_7_9"
          os-type              = "Linux"
          component            = "test"
          server-type          = "nomis-xtag"
          nomis-environment    = "t1"
          oracle-db-hostname-a = "t1nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t1nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T1CNOM"
        }
      }
      t1-nomis-xtag-b = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_rhel_7_9_*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          instance_type          = "t2.large"
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description          = "For testing XTAG image"
          ami                  = "base_rhel_7_9"
          os-type              = "Linux"
          component            = "test"
          server-type          = "nomis-xtag"
          nomis-environment    = "t1"
          oracle-db-hostname-a = "t1nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t1nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T1CNOM"
        }
      }

      # blue deployment
      t2-nomis-web-a = merge(local.weblogic_ec2_a, {
        tags = merge(local.weblogic_ec2_a.tags, {
          nomis-environment    = "t2"
          oracle-db-hostname-a = "t2nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t2nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T2CNOM"
        })
      })

      # green deployment
      t2-nomis-web-b = merge(local.weblogic_ec2_b, {
        tags = merge(local.weblogic_ec2_b.tags, {
          nomis-environment    = "t2"
          oracle-db-hostname-a = "t2nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t2nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T2CNOM"
        })
      })

      # blue deployment
      t3-nomis-web-a = merge(local.weblogic_ec2_a, {
        tags = merge(local.weblogic_ec2_a.tags, {
          nomis-environment    = "t3"
          oracle-db-hostname-a = "t3nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t3nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T3CNOM"
        })
      })

      # green deployment
      t3-nomis-web-b = merge(local.weblogic_ec2_b, {
        tags = merge(local.weblogic_ec2_b.tags, {
          nomis-environment    = "t3"
          oracle-db-hostname-a = "t3nomis-a.test.nomis.service.justice.gov.uk"
          oracle-db-hostname-b = "t3nomis-b.test.nomis.service.justice.gov.uk"
          oracle-db-name       = "T3CNOM"
        })
      })

      test-oem = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_ol_8_5_*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-web"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        # autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing Oracle Enterprise Manager image"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "base_rhel85"
        }
      }

      test-jumpserver-2022 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "nomis_windows_server_2022_jumpserver_release_*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/new-jumpserver-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-jumpserver"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 1 # set to 0 while testing
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2022 Jumpserver for NOMIS"
          os-type     = "Windows"
          component   = "jumpserver"
          server-type = "nomis-jumpserver"
        }
      }
    }

    baseline_ec2_instances = {
      t1-nomis-db-1-a = merge(local.database_ec2_a, {
        tags = merge(local.database_ec2_a.tags, {
          nomis-environment   = "t1"
          description         = "T1 NOMIS database"
          oracle-sids         = "T1CNOM T1NDH T1TRDAT T1ORSYS"
          instance-scheduling = "skip-scheduling"
        })
        config = merge(local.database_ec2_a.config, {
          ami_name = "nomis_rhel_7_9_oracledb_11_2_release_2023-06-23T16-28-48.100Z"
        })
        user_data_cloud_init = merge(local.database_ec2_a.user_data_cloud_init, {
          args = merge(local.database_ec2_a.user_data_cloud_init.args, {
            branch = "d264cc523daa4ee5bf60d254120874bbc7b55525"
          })
        })
        ebs_volumes = merge(local.database_ec2_a.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.database_ec2_a.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 50 }
        })
      })

      t1-nomis-db-2-a = merge(local.database_ec2_a, {
        tags = merge(local.database_ec2_a.tags, {
          nomis-environment   = "t1"
          description         = "T1 NOMIS Audit and MIS database"
          oracle-sids         = "T1MIS T1CNMAUD"
          instance-scheduling = "skip-scheduling"
        })
        config = merge(local.database_ec2_a.config, {
          ami_name = "nomis_rhel_7_9_oracledb_11_2_release_2023-06-23T16-28-48.100Z"
        })
        user_data_cloud_init = merge(local.database_ec2_a.user_data_cloud_init, {
          args = merge(local.database_ec2_a.user_data_cloud_init.args, {
            branch = "d264cc523daa4ee5bf60d254120874bbc7b55525"
          })
        })
        ebs_volumes = merge(local.database_ec2_a.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.database_ec2_a.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 50 }
        })
      })

      t2-nomis-db-1-a = merge(local.database_ec2_a, {
        tags = merge(local.database_ec2_a.tags, {
          nomis-environment   = "t2"
          description         = "T2 NOMIS database"
          oracle-sids         = "T2CNOM T2NDH T2TRDAT"
          instance-scheduling = "skip-scheduling"
        })
        config = merge(local.database_ec2_a.config, {
          ami_name = "nomis_rhel_7_9_oracledb_11_2_release_2023-06-23T16-28-48.100Z"
        })
        user_data_cloud_init = merge(local.database_ec2_a.user_data_cloud_init, {
          args = merge(local.database_ec2_a.user_data_cloud_init.args, {
            branch = "d264cc523daa4ee5bf60d254120874bbc7b55525"
          })
        })
        ebs_volumes = merge(local.database_ec2_a.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 100 }
        })
        ebs_volume_config = merge(local.database_ec2_a.ebs_volume_config, {
          data  = { total_size = 500 }
          flash = { total_size = 50 }
        })
        cloudwatch_metric_alarms = {} # no alarms as -a is not currently the live environment
      })

      t3-nomis-db-1 = merge(local.database_ec2_a, {
        tags = merge(local.database_ec2_a.tags, {
          nomis-environment   = "t3"
          description         = "T3 NOMIS database to replace Azure T3PDL0070"
          oracle-sids         = "T3CNOM"
          instance-scheduling = "skip-scheduling"
        })
        ebs_volumes = merge(local.database_ec2_a.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.database_ec2_a.ebs_volume_config, {
          data  = { total_size = 2000 }
          flash = { total_size = 500 }
        })
        cloudwatch_metric_alarms = {} # disable for failover test
      })
      t3-nomis-db-1-b = merge(local.database_ec2_b, {
        tags = merge(local.database_ec2_b.tags, {
          nomis-environment   = "t3"
          description         = "T3 NOMIS database"
          oracle-sids         = "T3CNOM"
          instance-scheduling = "skip-scheduling"
        })
        config = merge(local.database_ec2_b.config, {
          ami_name = "AwsBackup_i-09bba03659a0990da_e4a139ba-8881-4adb-bbdc-5fcf18b7dcd2"
        })
        user_data_cloud_init = merge(local.database_ec2_a.user_data_cloud_init, {
          args = merge(local.database_ec2_a.user_data_cloud_init.args, {
            branch       = "d264cc523daa4ee5bf60d254120874bbc7b55525"
            ansible_args = "--tags ec2patch"
          })
        })
        ebs_volumes = merge(local.database_ec2_a.ebs_volumes, {
          "/dev/sdb" = { label = "app", size = 100 }
          "/dev/sdc" = { label = "app", size = 500 }
        })
        ebs_volume_config = merge(local.database_ec2_a.ebs_volume_config, {
          data  = { total_size = 2000 }
          flash = { total_size = 500 }
        })
        cloudwatch_metric_alarms = {} # disable for failover test
      })

    }

    baseline_lbs = {
      # AWS doesn't let us call it internal
      private = {
        internal_lb              = true
        enable_delete_protection = false
        force_destroy_bucket     = true
        idle_timeout             = 3600
        public_subnets           = module.environment.subnets["private"].ids
        security_groups          = ["private-lb"]

        listeners = {
          http = local.weblogic_lb_listeners.http

          http7777 = merge(local.weblogic_lb_listeners.http7777, {
            rules = {
              # T1 users in Azure accessed server directly on http 7777
              # so support this in Mod Platform as well to minimise
              # disruption.  This isn't needed for other environments.
              t1-nomis-web-a = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-a.test.nomis.az.justice.gov.uk",
                      "t1-nomis-web-a.test.nomis.service.justice.gov.uk",
                      "c-t1.test.nomis.az.justice.gov.uk",
                      "c-t1.test.nomis.service.justice.gov.uk",
                      "t1-cn.hmpp-azdt.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-nomis-web-b = {
                priority = 400
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-b.test.nomis.az.justice.gov.uk",
                      "t1-nomis-web-b.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })

          https = merge(local.weblogic_lb_listeners.https, {
            alarm_target_group_names = ["t1-nomis-web-a-http-7777"]
            rules = {
              t1-nomis-web-a-http-7777 = {
                priority = 300
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-a.test.nomis.az.justice.gov.uk",
                      "t1-nomis-web-a.test.nomis.service.justice.gov.uk",
                      "c-t1.test.nomis.az.justice.gov.uk",
                      "c-t1.test.nomis.service.justice.gov.uk",
                      "t1-cn.hmpp-azdt.justice.gov.uk",
                    ]
                  }
                }]
              }
              t1-nomis-web-b-http-7777 = {
                priority = 450
                actions = [{
                  type              = "forward"
                  target_group_name = "t1-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t1-nomis-web-b.test.nomis.az.justice.gov.uk",
                      "t1-nomis-web-b.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t2-nomis-web-a-http-7777 = {
                priority = 550
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t2-nomis-web-a.test.nomis.az.justice.gov.uk",
                      "t2-nomis-web-a.test.nomis.service.justice.gov.uk",
                      "c-t2.test.nomis.az.justice.gov.uk",
                      "c-t2.test.nomis.service.justice.gov.uk",
                      "t2-cn.hmpp-azdt.justice.gov.uk",
                    ]
                  }
                }]
              }
              t2-nomis-web-b-http-7777 = {
                priority = 600
                actions = [{
                  type              = "forward"
                  target_group_name = "t2-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t2-nomis-web-b.test.nomis.az.justice.gov.uk",
                      "t2-nomis-web-b.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
              t3-nomis-web-a-http-7777 = {
                priority = 700
                actions = [{
                  type              = "forward"
                  target_group_name = "t3-nomis-web-a-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t3-nomis-web-a.test.nomis.az.justice.gov.uk",
                      "t3-nomis-web-a.test.nomis.service.justice.gov.uk",
                      "c-t3.test.nomis.az.justice.gov.uk",
                      "c-t3.test.nomis.service.justice.gov.uk",
                      "t3-cn.hmpp-azdt.justice.gov.uk",
                    ]
                  }
                }]
              }
              t3-nomis-web-b-http-7777 = {
                priority = 800
                actions = [{
                  type              = "forward"
                  target_group_name = "t3-nomis-web-b-http-7777"
                }]
                conditions = [{
                  host_header = {
                    values = [
                      "t3-nomis-web-b.test.nomis.az.justice.gov.uk",
                      "t3-nomis-web-b.test.nomis.service.justice.gov.uk",
                    ]
                  }
                }]
              }
            }
          })
        }
      }
    }

    baseline_route53_zones = {
      "hmpps-test.modernisation-platform.service.justice.gov.uk" = {
        records = [
        ]
      }
      "test.nomis.az.justice.gov.uk" = {
        lb_alias_records = [
          # T1
          { name = "t1-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t1-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t1", type = "A", lbs_map_key = "private" },
          # T2
          { name = "t2-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t2-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t2", type = "A", lbs_map_key = "private" },
          # T3
          { name = "t3-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t3-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t3", type = "A", lbs_map_key = "private" },
        ]
      }
      "test.nomis.service.justice.gov.uk" = {
        records = [
          # OEM (IP hardcoded while we are testing under an ASG)
          { name = "oem", type = "A", ttl = "300", records = ["10.26.12.202"] },

          # T1 [1-a: T1CNOM, T1NDH, T1TRDAT, T1ORSYS] [2-a: T1MIS, T1CNMAUD]
          { name = "t1nomis", type = "CNAME", ttl = "300", records = ["t1nomis-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1nomis-a", type = "CNAME", ttl = "3600", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1nomis-b", type = "CNAME", ttl = "3600", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1ndh", type = "CNAME", ttl = "300", records = ["t1ndh-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1ndh-a", type = "CNAME", ttl = "3600", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1ndh-b", type = "CNAME", ttl = "3600", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1or", type = "CNAME", ttl = "300", records = ["t1or-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1or-a", type = "CNAME", ttl = "3600", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1or-b", type = "CNAME", ttl = "3600", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1trdat", type = "CNAME", ttl = "300", records = ["t1trdat-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1trdat-a", type = "CNAME", ttl = "3600", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1trdat-b", type = "CNAME", ttl = "3600", records = ["t1-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1audit", type = "CNAME", ttl = "300", records = ["t1audit-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1audit-a", type = "CNAME", ttl = "3600", records = ["t1-nomis-db-2-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1audit-b", type = "CNAME", ttl = "3600", records = ["t1-nomis-db-2-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1mis", type = "CNAME", ttl = "300", records = ["t1mis-a.test.nomis.service.justice.gov.uk"] },
          { name = "t1mis-a", type = "CNAME", ttl = "3600", records = ["t1-nomis-db-2-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t1mis-b", type = "CNAME", ttl = "3600", records = ["t1-nomis-db-2-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          # T2 [1-a: T2CNOM, T2NDH, T2TRDAT]
          { name = "t2nomis", type = "CNAME", ttl = "300", records = ["t2nomis-a.test.nomis.service.justice.gov.uk"] },
          { name = "t2nomis-a", type = "CNAME", ttl = "3600", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2nomis-b", type = "CNAME", ttl = "3600", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2ndh", type = "CNAME", ttl = "300", records = ["t2ndh-a.test.nomis.service.justice.gov.uk"] },
          { name = "t2ndh-a", type = "CNAME", ttl = "3600", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2ndh-b", type = "CNAME", ttl = "3600", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2or", type = "CNAME", ttl = "300", records = ["t2or-a.test.nomis.service.justice.gov.uk"] },
          { name = "t2or-a", type = "CNAME", ttl = "3600", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2or-b", type = "CNAME", ttl = "3600", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2trdat", type = "CNAME", ttl = "300", records = ["t2trdat-a.test.nomis.service.justice.gov.uk"] },
          { name = "t2trdat-a", type = "CNAME", ttl = "3600", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t2trdat-b", type = "CNAME", ttl = "3600", records = ["t2-nomis-db-1-a.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          # T3: [1-b: T3CNOM]
          { name = "t3nomis", type = "CNAME", ttl = "300", records = ["t3nomis-b.test.nomis.service.justice.gov.uk"] },
          { name = "t3nomis-a", type = "CNAME", ttl = "300", records = ["t3-nomis-db-1.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
          { name = "t3nomis-b", type = "CNAME", ttl = "300", records = ["t3-nomis-db-1.nomis.hmpps-test.modernisation-platform.service.justice.gov.uk"] },
        ]
        lb_alias_records = [
          # T1
          { name = "t1-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t1-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t1", type = "A", lbs_map_key = "private" },
          # T2
          { name = "t2-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t2-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t2", type = "A", lbs_map_key = "private" },
          # T3
          { name = "t3-nomis-web-a", type = "A", lbs_map_key = "private" },
          { name = "t3-nomis-web-b", type = "A", lbs_map_key = "private" },
          { name = "c-t3", type = "A", lbs_map_key = "private" },
        ]
      }
    }

    baseline_s3_buckets = {
      # use this bucket for storing artefacts for use across all accounts
      ec2-image-builder-nomis = {
        custom_kms_key = module.environment.kms_keys["general"].arn
        bucket_policy_v2 = [
          module.baseline_presets.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          module.baseline_presets.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
        ]
        iam_policies = module.baseline_presets.s3_iam_policies
      }
    }
  }
}
