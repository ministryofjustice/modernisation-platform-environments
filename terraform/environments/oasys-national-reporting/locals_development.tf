locals {

  baseline_presets_development = {
    options = {
      # disabling some features in development as the environment gets nuked
      cloudwatch_metric_oam_links_ssm_parameters = []
      cloudwatch_metric_oam_links                = []
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
        cloudwatch_metric_alarms = null
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
        cloudwatch_metric_alarms = null
      })

      dev-onr-bods-1 = merge(local.ec2_autoscaling_groups.bods, {
        autoscaling_group = merge(local.ec2_autoscaling_groups.bods.autoscaling_group, {
          desired_capacity = 0
        })
        config = merge(local.ec2_autoscaling_groups.bods.config, {
          instance_profile_policies = concat(local.ec2_autoscaling_groups.bods.config.instance_profile_policies, [
            "Ec2SecretPolicy",
          ])
          user_data_raw = base64encode(templatefile(
            "./templates/user-data-onr-bods-pwsh.yaml.tftpl", {
              branch = "TM/combine-bods-installers"
          }))
        })
        instance = merge(local.ec2_autoscaling_groups.bods.instance, {
          instance_type = "t3.large"
        })
        tags = merge(local.ec2_autoscaling_groups.bods.tags, {
          oasys-national-reporting-environment = "dev"
          domain-name                          = "azure.noms.root"
          server-type                          = "Bods"
        })
        cloudwatch_metric_alarms = null
      })
    }

    ec2_instances = {
    }

    iam_policies = {
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
              "arn:aws:secretsmanager:*:*:secret:/sap/bods/dev/*",
              "arn:aws:secretsmanager:*:*:secret:/sap/bip/dev/*",
              "arn:aws:secretsmanager:*:*:secret:/oracle/database/*",
            ]
          }
        ]
      }
    }

    route53_zones = {
      "development.reporting.oasys.service.justice.gov.uk" = {}
    }

    secretsmanager_secrets = {
      "/sap/bods/dev"            = local.secretsmanager_secrets.bods
      "/sap/bip/dev"             = local.secretsmanager_secrets.bip
      "/oracle/database/TESTSYS" = local.secretsmanager_secrets.db
      "/oracle/database/TESTAUD" = local.secretsmanager_secrets.db
    }
  }
}

