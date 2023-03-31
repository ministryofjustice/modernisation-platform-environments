variable "acm_certificates" {
  description = "map of acm certificates to create where the map key is the tags.Name.  See acm_certificate module for more variable details"
  type = map(object({
    domain_name             = string
    subject_alternate_names = optional(list(string), [])
    validation = optional(map(object({
      account   = optional(string, "self")
      zone_name = string
    })),{})
    tags = map(string)
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

      # below are unused but are defined so same object can be used with ec2_instance
      subnet_name       = optional(string)
      availability_zone = optional(string)
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
      enabled_cloudwatch_logs_exports     = optional(list(string))
      engine                              = string
      engine_version                      = optional(string)
      final_snapshot_identifier           = optional(bool, false)
      iam_database_authentication_enabled = optional(bool, false)
      identifier                          = string
      instance_class                      = string
      iops                                = optional(number, 0)
      kms_key_id                          = optional(string)
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
    security_groups          = list(string)
    public_subnets           = list(string)
    existing_target_groups   = optional(map(any), {})
    tags                     = optional(map(string), {})
    listeners = optional(map(object({
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
      route53_records = optional(map(object({
        zone_name              = string
        evaluate_target_health = optional(bool, false)
      })), {})
      replace = optional(object({
        target_group_name_match       = optional(string, "$(name)")
        target_group_name_replace     = optional(string, "")
        condition_host_header_match   = optional(string, "$(name)")
        condition_host_header_replace = optional(string, "")
        route53_record_name_match     = optional(string, "$(name)")
        route53_record_name_replace   = optional(string, "")
      }), {})
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

variable "tags" {
  description = "Any additional tags to apply to all resources, in addition to those provided by environment module"
  type        = map(string)
  default     = {}
}
