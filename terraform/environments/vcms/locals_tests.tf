locals {

  baseline_presets_test = {
    options = {
    #   sns_topics = {
    #     pagerduty_integrations = {
    #       pagerduty = "vcms-test"
    #     }
    #   }
    }
  }

  # please keep resources in alphabetical order
  baseline_test = {

    acm_certificates = {}

    cloudwatch_dashboards = {}

    ec2_autoscaling_groups = {}

    ec2_instances = {}

    iam_policies = {}

    lbs = {
    }

    route53_zones = {

    }

    secretsmanager_secrets = {}
  }
}

