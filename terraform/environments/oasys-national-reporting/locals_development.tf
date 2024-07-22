locals {

  baseline_presets_development = {
    options = {
    }
  }

  # please keep resources in alphabetical order
  baseline_development = {

    ec2_autoscaling_groups = {
      dev-web-asg = merge(local.ec2_autoscaling_groups.boe_web, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.boe_web.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.boe_web.config, {
        })
        instance = merge(local.ec2_autoscaling_groups.boe_web.instance, {
          instance_type = "t3.large"
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.boe_web.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.boe_web.user_data_cloud_init.args, {
            branch = "main"
          })
        })
      })

      dev-boe-asg = merge(local.ec2_autoscaling_groups.boe_app, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.boe_app.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.boe_app.config, {
        })
        instance = merge(local.ec2_autoscaling_groups.boe_app.instance, {
          instance_type = "t2.large"
        })
        user_data_cloud_init = merge(local.ec2_autoscaling_groups.boe_app.user_data_cloud_init, {
          args = merge(local.ec2_autoscaling_groups.boe_app.user_data_cloud_init.args, {
            branch = "main"
          })
        })
      })

      dev-bods-asg = merge(local.ec2_autoscaling_groups.bods, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bods.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.bods.config, {
          ami_owner = "self"
        })
        instance = merge(local.ec2_autoscaling_groups.bods.instance, {
          instance_type = "t3.large"
        })
      })
    }

    ec2_instances = {
    }

    route53_zones = {
      "development.reporting.oasys.service.justice.gov.uk" = {}
    }
  }
}

