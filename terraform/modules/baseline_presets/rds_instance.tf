locals {

  rds_instance = {

    profile_policies = {

      # remember to add the appropriate S3 policy to this
      default = flatten([
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
        local.iam_policies_rds_default,
      ])
    }

    config = {

      # example configuration
      default = {
        ssm_parameters_prefix     = "rds_instance/"
        iam_resource_names_prefix = "rds-instance"
        instance_profile_policies = flatten([
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
          local.iam_policies_rds_default,
          "EC2S3BucketWriteAndDeleteAccessPolicy",
        ])
      }
    }

    instance = {

      # assumes there is a 'private' security group created
      default = {
        identifier                      = "rds-instance"
        create                          = true
        allocated_storage               = number
        storage_type                    = "gp2"
        engine                          = string
        instance_class                  = string
        username                        = string
        password                        = string
        skip_final_snapshot             = false
        final_snapshot_identifier       = false
        multi_az                        = false
        iops                            = 0
        publicly_accessible             = false
        monitoring_interval             = 0
        copy_tags_to_snapshot           = false
        backup_retention_period         = 1
        enabled_cloudwatch_logs_exports = ["alert", "audit", "listener", "trace"]
        vpc_security_group_ids          = ["private"]
      }
    }

    option_group = {

      default = {
        engine_name          = "sqlserver-ee"
        major_engine_version = "11.00"
        options = list(object({
          option_name                    = string
          port                           = optional(number)
          version                        = optional(string)
          db_security_group_memberships  = optional(list(string))
          vpc_security_group_memberships = optional(list(string))
          settings = list(object({
            name  = string
            value = string
          }))
        }))
      }
    }
    parameter_group = {
      default = {
        name_prefix          = string
        description          = string
        family               = string
        major_engine_version = string
        parameters = list(object({
          name         = string
          value        = string
          apply_method = "immediate"
        }))
      }
    }
    subnet_group = {
      default = {
        name_prefix = string
        description = string
        subnet_ids  = list(string)
      }
    }
    route53_records = {
      create_dns_entry = true
    }
  }
}