variable "acm_certificates" {
  description = "map of acm certificates to create where the map key is the tags.Name.  See acm_certificate module for more variable details"
  type = map(object({
    domain_name             = string
    subject_alternate_names = optional(list(string), [])
    validation = optional(map(object({
      account   = optional(string, "self")
      zone_name = string
    })), {})
    external_validation_records_created = optional(bool, false)
    cloudwatch_metric_alarms = optional(map(object({
      comparison_operator = string
      evaluation_periods  = number
      metric_name         = string
      namespace           = string
      period              = number
      statistic           = string
      threshold           = number
      alarm_actions       = list(string)
      actions_enabled     = optional(bool, false)
      alarm_description   = optional(string)
      datapoints_to_alarm = optional(number)
      treat_missing_data  = optional(string, "missing")
      dimensions          = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "backups" {
  description = "map of backup_vaults with associated backup plans to create, where the plan name is the backup_vault name and plan key combined.  Use  'everything' as the map key to use the modernisation platform managed vault"
  type = map(object({
    plans = map(object({
      rule = object({
        schedule                 = optional(string)
        enable_continuous_backup = optional(bool)
        start_window             = optional(number)
        completion_window        = optional(number)
        cold_storage_after       = optional(number)
        delete_after             = number
      })
      advanced_backup_setting = optional(object({
        backup_options = object({
          WindowsVSS = string
        })
        resource_type = string
      }))
      selection = object({
        resources     = optional(list(string))
        not_resources = optional(list(string))
        selection_tags = list(object({
          type  = string
          key   = string
          value = string
        }))
      })
      tags = optional(map(string), {})
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "bastion_linux" {
  description = "set this if you want a bastion linux created"
  type = object({
    public_key_data         = map(string)
    allow_ssh_commands      = optional(bool, true)
    bucket_name             = optional(string, "bastion")
    bucket_versioning       = optional(bool, true)
    bucket_force_destroy    = optional(bool, true)
    log_auto_clean          = optional(string, "Enabled")
    log_standard_ia_days    = optional(number, 30)
    log_glacier_days        = optional(number, 60)
    log_expiry_days         = optional(number, 180)
    extra_user_data_content = optional(string, "")
    tags                    = optional(map(string), {})
  })
  default = null
}

variable "cloudwatch_log_groups" {
  description = "set of cloudwatch log groups to create where the key is the name of the group"
  type = map(object({
    retention_in_days = optional(number)
    skip_destroy      = optional(bool)
    kms_key_id        = optional(string)
    tags              = optional(map(string), {})
  }))
  default = {}
}

variable "cloudwatch_log_metric_filters" {
  description = "map of cloudwatch log metric filters where the filter name is the map key"
  type = map(object({
    pattern        = string
    log_group_name = string
    metric_transformation = object({
      name          = string
      namespace     = string
      value         = string
      default_value = optional(string)
      dimensions    = optional(map(string))
      unit          = optional(string)
    })
  }))
  default = {}
}

variable "cloudwatch_metric_alarms" {
  description = "map of cloudwatch metric alarms to create, where key is the name of the alarm.  Use split_by_dimension to create one alarm per given dimension value, e.g. one alarm per database"
  type = map(object({
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    alarm_actions       = list(string)
    actions_enabled     = optional(bool, false)
    alarm_description   = optional(string)
    datapoints_to_alarm = optional(number)
    treat_missing_data  = optional(string, "missing")
    dimensions          = optional(map(string), {})
    split_by_dimension = optional(object({
      dimension_name   = string
      dimension_values = list(string)
    }))
  }))
  default = {}
}

variable "ec2_autoscaling_groups" {
  description = "map of ec2 autoscaling groups to create where the map key is the tags.Name.  See ec2_autoscaling_group module for more variable details"
  type = map(object({
    config = object({
      ami_name                      = string
      ami_owner                     = optional(string, "core-shared-services-production")
      ebs_volumes_copy_all_from_ami = optional(bool, true)
      ebs_kms_key_id                = optional(string) # business unit wide "ebs" key used by default
      user_data_raw                 = optional(string)
      iam_resource_names_prefix     = optional(string, "ec2")
      instance_profile_policies     = list(string)
      ssm_parameters_prefix         = optional(string, "")
      subnet_name                   = optional(string)
      availability_zone             = optional(string)
    })
    instance = object({
      disable_api_termination      = bool
      instance_type                = string
      key_name                     = string
      monitoring                   = optional(bool, true)
      metadata_options_http_tokens = optional(string, "required")
      metadata_endpoint_enabled    = optional(string, "enabled")
      vpc_security_group_ids       = list(string)
      private_dns_name_options = optional(object({
        enable_resource_name_dns_aaaa_record = optional(bool)
        enable_resource_name_dns_a_record    = optional(bool)
        hostname_type                        = string
      }))
      tags = optional(map(string), {})
    })
    user_data_cloud_init = optional(object({
      args    = optional(map(string))
      scripts = optional(list(string))
      write_files = optional(map(object({
        path        = string
        owner       = string
        permissions = string
      })), {})
    }))
    ebs_volume_config = optional(map(object({
      iops       = optional(number)
      throughput = optional(number)
      total_size = optional(number)
      type       = optional(string)
      kms_key_id = optional(string)
    })), {})
    ebs_volume_tags = optional(map(string), {})
    ebs_volumes = optional(map(object({
      label       = optional(string)
      snapshot_id = optional(string)
      iops        = optional(number)
      throughput  = optional(number)
      size        = optional(number)
      type        = optional(string)
      kms_key_id  = optional(string)
    })), {})
    autoscaling_group = object({
      desired_capacity          = number
      max_size                  = number
      min_size                  = optional(number, 0)
      health_check_grace_period = optional(number)
      health_check_type         = optional(string)
      force_delete              = optional(bool)
      termination_policies      = optional(list(string))
      target_group_arns         = optional(list(string))
      wait_for_capacity_timeout = optional(number)
      initial_lifecycle_hooks = optional(map(object({
        default_result       = string
        heartbeat_timeout    = number
        lifecycle_transition = string
      })))
      instance_refresh = optional(object({
        strategy               = string
        min_healthy_percentage = number
        instance_warmup        = number
      }))
      warm_pool = optional(object({
        pool_state                  = optional(string)
        min_size                    = optional(number)
        max_group_prepared_capacity = optional(number)
        reuse_on_scale_in           = bool
      }))
    })
    autoscaling_schedules = optional(map(object({
      min_size         = optional(number)
      max_size         = optional(number)
      desired_capacity = optional(number)
      recurrence       = string
    })), {})
    ssm_parameters = optional(map(object({
      random = object({
        length  = number
        special = bool
      })
      description = string
    })))
    lb_target_groups = optional(map(object({
      port                 = optional(number)
      protocol             = optional(string)
      target_type          = string
      deregistration_delay = optional(number)
      health_check = optional(object({
        enabled             = optional(bool)
        interval            = optional(number)
        healthy_threshold   = optional(number)
        matcher             = optional(string)
        path                = optional(string)
        port                = optional(number)
        timeout             = optional(number)
        unhealthy_threshold = optional(number)
      }))
      stickiness = optional(object({
        enabled         = optional(bool)
        type            = string
        cookie_duration = optional(number)
        cookie_name     = optional(string)
      }))
      attachments = optional(list(object({
        target_id         = string
        port              = optional(number)
        availability_zone = optional(string)
      })), [])
    })), {})
    cloudwatch_metric_alarms = optional(map(object({
      comparison_operator = string
      evaluation_periods  = number
      metric_name         = string
      namespace           = string
      period              = number
      statistic           = string
      threshold           = number
      alarm_actions       = list(string)
      actions_enabled     = optional(bool, false)
      alarm_description   = optional(string)
      datapoints_to_alarm = optional(number)
      treat_missing_data  = optional(string, "missing")
      dimensions          = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "ec2_instances" {
  description = "map of ec2 instances to create where the map key is the tags.Name.  See ec2_instance module for more variable details"
  type = map(object({
    config = object({
      ami_name                      = string
      ami_owner                     = optional(string, "core-shared-services-production")
      ebs_volumes_copy_all_from_ami = optional(bool, true)
      ebs_kms_key_id                = optional(string) # business unit wide "ebs" key used by default
      user_data_raw                 = optional(string)
      iam_resource_names_prefix     = optional(string, "ec2")
      instance_profile_policies     = list(string)
      ssm_parameters_prefix         = optional(string, "")
      subnet_name                   = string
      availability_zone             = string
    })
    instance = object({
      disable_api_termination      = bool
      instance_type                = string
      key_name                     = string
      monitoring                   = optional(bool, true)
      metadata_options_http_tokens = optional(string, "required")
      metadata_endpoint_enabled    = optional(string, "enabled")
      vpc_security_group_ids       = list(string)
      private_dns_name_options = optional(object({
        enable_resource_name_dns_aaaa_record = optional(bool)
        enable_resource_name_dns_a_record    = optional(bool)
        hostname_type                        = string
      }))
      tags = optional(map(string), {})
    })
    user_data_cloud_init = optional(object({
      args    = optional(map(string))
      scripts = optional(list(string))
      write_files = optional(map(object({
        path        = string
        owner       = string
        permissions = string
      })), {})
    }))
    ebs_volume_config = optional(map(object({
      iops       = optional(number)
      throughput = optional(number)
      total_size = optional(number)
      type       = optional(string)
      kms_key_id = optional(string)
    })), {})
    ebs_volume_tags = optional(map(string), {})
    ebs_volumes = optional(map(object({
      label       = optional(string)
      snapshot_id = optional(string)
      iops        = optional(number)
      throughput  = optional(number)
      size        = optional(number)
      type        = optional(string)
      kms_key_id  = optional(string)
    })), {})
    ssm_parameters = optional(map(object({
      random = object({
        length  = number
        special = bool
      })
      description = string
    })))
    route53_records = optional(object({
      create_internal_record = bool
      create_external_record = bool
      }), {
      create_internal_record = true
      create_external_record = false
    })
    cloudwatch_metric_alarms = optional(map(object({
      comparison_operator = string
      evaluation_periods  = number
      metric_name         = string
      namespace           = string
      period              = number
      statistic           = string
      threshold           = number
      alarm_actions       = list(string)
      actions_enabled     = optional(bool, false)
      alarm_description   = optional(string)
      datapoints_to_alarm = optional(number)
      treat_missing_data  = optional(string, "missing")
      dimensions          = optional(map(string), {})
    })), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "rds_instances" {
  description = "map of rds instances to create where the map key is the tags.Name.  See rds_instance module for more variable details"
  type = map(object({
    config = object({
      iam_resource_names_prefix = optional(string, "rds_db")
      instance_profile_policies = list(string)
      ssm_parameters_prefix     = optional(string, "")
    })
    instance = object({
      allocated_storage                   = number
      allow_major_version_upgrade         = optional(bool, false)
      apply_immediately                   = optional(bool, false)
      auto_minor_version_upgrade          = optional(bool, false)
      backup_retention_period             = optional(number, 1)
      backup_window                       = optional(string)
      character_set_name                  = optional(string)
      copy_tags_to_snapshot               = optional(bool, false)
      create                              = optional(bool, true)
      db_name                             = optional(string)
      db_subnet_group_name                = optional(string)
      deletion_protection                 = optional(bool, true)
      enabled_cloudwatch_logs_exports     = optional(list(string))
      engine                              = string
      engine_version                      = optional(string)
      final_snapshot_identifier           = optional(bool, false)
      iam_database_authentication_enabled = optional(bool, false)
      identifier                          = string
      instance_class                      = string
      iops                                = optional(number, 0)
      kms_key_id                          = string
      license_model                       = optional(string)
      maintenance_window                  = optional(string)
      max_allocated_storage               = optional(number)
      monitoring_interval                 = optional(number, 0)
      monitoring_role_arn                 = optional(string)
      multi_az                            = optional(bool, false)
      option_group_name                   = optional(string)
      parameter_group_name                = optional(string)
      password                            = string
      port                                = optional(string)
      publicly_accessible                 = optional(bool, false)
      replicate_source_db                 = optional(string)
      skip_final_snapshot                 = optional(bool, false)
      snapshot_identifier                 = optional(string)
      storage_encrypted                   = optional(bool, false)
      storage_type                        = optional(string, "gp2")
      username                            = string
      vpc_security_group_ids              = optional(list(string))
    })
    option_group = object({
      create                   = bool
      name_prefix              = optional(string)
      option_group_description = optional(string)
      engine_name              = string
      major_engine_version     = string
      options = optional(list(object({
        option_name                    = string
        port                           = optional(number)
        version                        = optional(string)
        db_security_group_memberships  = optional(list(string))
        vpc_security_group_memberships = optional(list(string))
        option_settings = optional(list(object({
          name  = optional(string)
          value = optional(string)
        })))
      })))
      tags = optional(list(string))
    })
    parameter_group = object({
      name_prefix = optional(string)
      description = optional(string)
      family      = string
      parameters = optional(list(object({
        name         = string
        value        = string
        apply_method = optional(string, "immediate")
      })))
      tags = optional(list(string))
    })
    subnet_group = object({
      name_prefix = optional(string)
      description = optional(string)
      subnet_ids  = list(string)
      tags        = optional(list(string))
    })
    ssm_kms_key_id = optional(string)
    ssm_parameters = optional(map(object({
      random = object({
        length  = number
        special = bool
      })
      description = string
    })))
    route53_record = optional(bool, true)
    tags           = optional(map(string), {})
  }))
  default = {}
}

variable "environment" {
  description = "Standard environmental data resources from the environment module"
}

variable "iam_policies" {
  description = "map of iam policies to create, where the key is the name of the policy"
  type = map(object({
    path        = optional(string, "/")
    description = optional(string)
    statements = list(object({
      effect    = string
      actions   = list(string)
      resources = list(string)
      principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    }))
  }))
  default = {}
}

variable "iam_roles" {
  description = "map of iam roles to create, where the key is the name of the role"
  type = map(object({
    assume_role_policy_principals_type        = string
    assume_role_policy_principals_identifiers = list(string)
    policy_attachments                        = optional(list(string), [])
    tags                                      = optional(map(string), {})
  }))
  default = {}
}

variable "iam_service_linked_roles" {
  description = "map of service linked roles to create, where key is the name of the service"
  type = map(object({
    custom_suffix = optional(string)
    description   = optional(string)
    tags          = optional(map(string), {})
  }))
  default = {}
}

variable "key_pairs" {
  description = "map of aws_key_pairs to create, where the key is the key name.  Provide a filename containing the key or the key itself"
  type = map(object({
    public_key          = optional(string)
    public_key_filename = optional(string)
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "lbs" {
  description = "map of load balancers and associated resources using loadbalancer and lb_listener modules"
  type = map(object({
    enable_delete_protection = optional(bool, false)
    force_destroy_bucket     = optional(bool, false)
    idle_timeout             = string
    internal_lb              = optional(bool, false)
    access_logs              = optional(bool, true)
    load_balancer_type       = optional(string, "application")
    security_groups          = list(string)
    public_subnets           = list(string)
    existing_target_groups = optional(map(object({
      arn = string
    })), {})
    tags = optional(map(string), {})
    lb_target_groups = optional(map(object({
      port                 = optional(number)
      deregistration_delay = optional(number)
      health_check = optional(object({
        enabled             = optional(bool)
        interval            = optional(number)
        healthy_threshold   = optional(number)
        matcher             = optional(string)
        path                = optional(string)
        port                = optional(number)
        timeout             = optional(number)
        unhealthy_threshold = optional(number)
      }))
      stickiness = optional(object({
        enabled         = optional(bool)
        type            = string
        cookie_duration = optional(number)
        cookie_name     = optional(string)
      }))
      attachments = optional(list(object({
        target_id         = string
        port              = optional(number)
        availability_zone = optional(string)
      })), [])
    })), {})
    listeners = optional(map(object({
      alarm_target_group_names  = optional(list(string), [])
      port                      = number
      protocol                  = string
      ssl_policy                = optional(string)
      certificate_names_or_arns = optional(list(string), [])
      default_action = object({
        type              = string
        target_group_name = optional(string)
        target_group_arn  = optional(string)
        fixed_response = optional(object({
          content_type = string
          message_body = optional(string)
          status_code  = optional(string)
        }))
        forward = optional(object({
          target_group = list(object({
            name       = optional(string)
            arn        = optional(string)
            stickiness = optional(number)
          }))
          stickiness = optional(object({
            duration = optional(number)
            enabled  = bool
          }))
        }))
        redirect = optional(object({
          status_code = string
          port        = optional(number)
          protocol    = optional(string)
        }))
      })
      rules = optional(map(object({
        priority = optional(number)
        actions = list(object({
          type              = string
          target_group_name = optional(string, null)
          target_group_arn  = optional(string, null) # use this if target group defined elsewhere
          fixed_response = optional(object({
            content_type = string
            message_body = optional(string)
            status_code  = optional(string)
          }))
          forward = optional(object({
            target_group = list(object({
              name       = optional(string)
              arn        = optional(string) # use this if target group defined elsewhere
              stickiness = optional(number)
            }))
            stickiness = optional(object({
              duration = optional(number)
              enabled  = bool
            }))
          }))
          redirect = optional(object({
            status_code = string
            port        = optional(number)
            protocol    = optional(string)
          }))
        }))
        conditions = list(object({
          host_header = optional(object({
            values = list(string)
          }))
          path_pattern = optional(object({
            values = list(string)
          }))
        }))
      })), {})
      cloudwatch_metric_alarms = optional(map(object({
        comparison_operator = string
        evaluation_periods  = number
        metric_name         = string
        namespace           = string
        period              = number
        statistic           = string
        threshold           = number
        alarm_actions       = list(string)
        actions_enabled     = optional(bool, false)
        alarm_description   = optional(string)
        datapoints_to_alarm = optional(number)
        treat_missing_data  = optional(string, "missing")
        dimensions          = optional(map(string), {})
      })), {})
      tags = optional(map(string), {})
    })), {})
  }))
  default = {}
}

variable "kms_grants" {
  description = "map of kms grants to create where key is the name of the grant"
  type = map(object({
    key_id            = string
    grantee_principal = string
    operations        = list(string)
  }))
  default = {}
}

variable "route53_resolvers" {
  description = "map of resolver endpoints and associated rules to configure, where map keys are the names of the resources.  The application name is automatically added as a prefix to the resource names"
  type = map(object({
    direction    = optional(string, "OUTBOUND")
    subnet_names = optional(list(string), ["data", "private"]) # NOTE: there's a quota of 6 cidrs / resolver
    rules = optional(map(object({
      domain_name = string
      rule_type   = optional(string, "FORWARD")
      target_ips  = list(string)
    })), {})
  }))
  default = {}
}

variable "route53_zones" {
  description = "map of route53 zones and associated records, where the map key is the name of the zone and the value object contains the records.  Zone is created if it doesn't already exist"
  type = map(object({
    records = optional(list(object({
      name    = string
      type    = string
      ttl     = number
      records = list(string)
    })), [])
    ns_records = optional(list(object({
      name      = string
      ttl       = number
      zone_name = string
    })), [])
    lb_alias_records = optional(list(object({
      name                   = string
      type                   = string
      lbs_map_key            = string
      evaluate_target_health = optional(bool, false)
    })), [])
    s3_alias_records = optional(list(object({
      name                   = string
      type                   = string
      s3_bucket_map_key      = string
      evaluate_target_health = optional(bool, false)
    })), [])
  }))
  default = {}
}

variable "s3_buckets" {
  description = "map of s3 buckets to create where the map key is the bucket prefix.  See s3_bucket module for more variable details.  Use iam_policies to automatically create a iam policies for the bucket where the key is the name of the policy"
  type = map(object({
    acl                 = optional(string, "private")
    versioning_enabled  = optional(bool, true)
    replication_enabled = optional(bool, false)
    replication_region  = optional(string)
    bucket_policy       = optional(list(string), ["{}"])
    bucket_policy_v2 = optional(list(object({
      effect  = string
      actions = list(string)
      principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    custom_kms_key             = optional(string)
    custom_replication_kms_key = optional(string)
    lifecycle_rule = optional(any, [{
      id      = "main"
      enabled = "Enabled"
      prefix  = ""
      tags = {
        rule      = "log"
        autoclean = "true"
      }
      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]
      expiration = {
        days = 730
      }
      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]
      noncurrent_version_expiration = {
        days = 730
      }
    }])
    log_bucket           = optional(string, "")
    log_prefix           = optional(string, "")
    replication_role_arn = optional(string, "")
    force_destroy        = optional(bool, false)
    sse_algorithm        = optional(string, "aws:kms")
    iam_policies = optional(map(list(object({
      effect  = string
      actions = list(string)
      principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    }))), {})
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "secretsmanager_secrets" {
  # Example usage:
  # my_database_secrets = {
  #   prefix = "/database"
  #   postfix = "/"
  #   parameters = {
  #     asm_password = { random = { length = 16 } }
  #     sys_password = { description = "placeholder for password" }
  #   }
  # }
  # secret_manager_secrets = {
  #   my_db1_1 = local.my_database_secrets
  #   my_db2_2 = local.my_database_secrets
  # }
  # Will create SSM params as follows
  # /database/my_db1_1/asm_password
  # /database/my_db1_1/sys_password
  # /database/my_db2_2/asm_password
  # /database/my_db2_2/sys_password
  #
  description = "Create a placeholder SecretManager secret, or a secret with a given value (randomly generated, from file, or value set directly).  Use this instead of SSM Parameters secure strings if you need to share the secret across accounts.  The top-level key is used as a prefix for the secret name, e.g. /database/db1.  Then define a map of secrets to create underneath that prefix.  Secret name is {prefix}{top-level-map-key}{postfix}{secrets-map-key}"
  type = map(object({
    prefix     = optional(string, "")
    postfix    = optional(string, "/")
    kms_key_id = optional(string, "general")
    policy = optional(list(object({
      effect  = string
      actions = list(string)
      principals = optional(object({
        type        = string
        identifiers = list(string)
      }))
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })))
    recovery_window_in_days = optional(number, 0)
    secrets = map(object({
      description = optional(string)
      type        = optional(string, "SecureString")
      file        = optional(string)
      kms_key_id  = optional(string)
      random = optional(object({
        length  = number
        special = optional(bool)
      }))
      value = optional(string)
    }))
  }))
  default = {}
}

variable "security_groups" {
  description = "map of security groups and associated rules to create where key is the name of the group"
  type = map(object({
    description = string
    ingress = map(object({
      description     = optional(string)
      from_port       = number
      to_port         = number
      protocol        = string
      security_groups = optional(list(string))
      cidr_blocks     = optional(list(string))
      self            = optional(bool)
      prefix_list_ids = optional(list(string))
    }))
    egress = map(object({
      description     = optional(string)
      from_port       = number
      to_port         = number
      protocol        = string
      security_groups = optional(list(string))
      cidr_blocks     = optional(list(string))
      self            = optional(bool)
      prefix_list_ids = optional(list(string))
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "sns_topics" {
  description = "map of sns topics and associated subscriptions where map key is the name of the topic"
  type = map(object({
    display_name      = optional(string)
    kms_master_key_id = optional(string)  # id or business unit key name, e.g. 'general'
    subscriptions = optional(map(object({ # map key isn't used
      protocol      = string
      endpoint      = string
      filter_policy = optional(string)
    })), {})
  }))
  default = {}
}

variable "ssm_parameters" {
  # Example usage:
  # my_ec2_params = {
  #   prefix = "/ec2"
  #   postfix = "/"
  #   parameters = {
  #     username = { value = "myusername" }
  #     password = { description = "placeholder for password" }
  #   }
  # }
  # ssm_parameters = {
  #   my_ec2_1 = local.my_ec2_params
  #   my_ec2_2 = local.my_ec2_params
  # }
  # Will create SSM params as follows
  # /ec2/my_ec2_1/username
  # /ec2/my_ec2_1/password
  # /ec2/my_ec2_2/username
  # /ec2/my_ec2_2/password
  #
  description = "Create a placeholder SSM parameter, or a SSM parameter with a given value (randomly generated, from file, or value set directly).  The top-level key is used as a prefix for the SSM parameters, e.g. /ec2/myec2name.  Then define a map of parameters to create underneath that prefix.  SSM parameter name is {prefix}{top-level-map-key}{postfix}{parameters-map-key}"
  type = map(object({
    prefix     = optional(string, "")
    postfix    = optional(string, "/")
    kms_key_id = optional(string)
    parameters = map(object({
      description = optional(string)
      type        = optional(string, "SecureString")
      kms_key_id  = optional(string)
      file        = optional(string)
      random = optional(object({
        length  = number
        special = optional(bool)
      }))
      value = optional(string)
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Any additional tags to apply to all resources, in addition to those provided by environment module"
  type        = map(string)
  default     = {}
}

variable "resource_explorer" {
  description = "Enables AWS Resource Explorer"
  type        = bool
  default     = false
}
