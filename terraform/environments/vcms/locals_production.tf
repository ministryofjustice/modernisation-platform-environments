locals {

  baseline_presets_production = {
    options = {
    #   sns_topics = {
    #     pagerduty_integrations = {
    #       pagerduty = "oasys-production"
    #     }
    #   }
    }
  }

  baseline_production = {

    # If your DNS records are in Fix 'n' Go, setup will be a 2 step process, see the acm_certificate module readme
    # if making changes, comment out the listeners that use the cert, edit the cert, recreate the listeners
    acm_certificates = {
    }

    cloudwatch_dashboards = {
    }

    ec2_autoscaling_groups = {
    }

    ec2_instances = {}

    iam_policies = {}

    lbs = {}

    route53_zones = {
    }

    secretsmanager_secrets = {}


  }

}
