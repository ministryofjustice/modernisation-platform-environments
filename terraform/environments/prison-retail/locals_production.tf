locals {

  baseline_presets_production = {
    options = {
      # TODO: configure prison-retail PagerDuty
      # sns_topics = {
      #   pagerduty_integrations = {
      #     pagerduty = "prison-retail"          
      #   }
      # }
    }
  }

  # please keep resources in alphabetical order
  baseline_production = {
    ec2_instances = {
      # pd-pr-retail-a = { # 15 char limit on name as domain joined
      #   # TODO: enable alarms when commissioned
      #   # cloudwatch_metric_alarms = merge(
      #   #   module.baseline_presets.cloudwatch_metric_alarms.ec2,
      #   #   module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_windows,
      #   #    module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_or_cwagent_stopped_windows,
      #   # )
      #   config = {
      #     #ami_name                      = # TODO - use Windows Server 2019 instead "Windows_Server-2025-English-Full-SQL_2025_Standard-2025.12.10"
      #     ami_owner                     = "801119661308"
      #     availability_zone             = "eu-west-2a"
      #     ebs_volumes_copy_all_from_ami = false
      #     iam_resource_names_prefix     = "ec2-instance"
      #     instance_profile_policies = [
      #       "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
      #       "EC2Default",
      #       "ImageBuilderS3BucketWriteAndDeleteAccessPolicy"
      #     ]
      #     subnet_name = "private-secondary" # running out of IPs, using secondary subnets
      #     user_data_raw = base64encode(templatefile(
      #       "../../modules/baseline_presets/ec2-user-data/user-data-pwsh.yaml.tftpl", {
      #         branch = "main"
      #       }
      #     ))
      #   }
      #   ebs_volumes = {
      #     "/dev/sda1" = { type = "gp3", size = 100 }
      #   }
      #   instance = {
      #     disable_api_termination      = false
      #     instance_type                = "m5.large" # any reason not to use later gen, e.g. m6i or r6i?
      #     metadata_options_http_tokens = "required"
      #     tags = {
      #       backup-plan = "daily-and-weekly"
      #     }
      #     vpc_security_group_ids = [
      #       "ad-join",
      #       "ec2-windows"
      #     ]
      #   }
      #   route53_records = {
      #     create_external_record = false
      #     create_internal_record = false
      #   }
      #   tags = {
      #     backup      = "false" # disable mod platform backup since we use our own policies
      #     domain-name = "azure.hmpp.root"
      #     os-type     = "Windows"
      #     server-type = "PrisonerRetail"
      #   }
      # }
    }
  }
}
