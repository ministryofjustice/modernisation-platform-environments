locals {

  baseline_presets_preproduction = {
    options = {
    #   sns_topics = {
    #     pagerduty_integrations = {
    #       pagerduty = "oasys-preproduction"
    #     }
    #   }
    }
  }

  # please keep resources in alphabetical order
  baseline_preproduction = {

    # If your DNS records are in Fix 'n' Go, setup will be a 2 step process, see the acm_certificate module readme
    # if making changes, comment out the listeners that use the cert, edit the cert, recreate the listeners
    acm_certificates = {}

    cloudwatch_dashboards = {}

    ec2_autoscaling_groups = {}

    ec2_instances = {}

    iam_policies = {}

    # options for LBs https://docs.google.com/presentation/d/1RpXpfNY_hw7FjoMw0sdMAdQOF7kZqLUY6qVVtLNavWI/edit?usp=sharing
    lbs = {}

    route53_zones = {}

    secretsmanager_secrets = {}
  }
}
