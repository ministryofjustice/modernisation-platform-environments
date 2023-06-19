##################################################
# Airflow
##################################################

module "airflow_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.0.0"

  name   = "data-platform-mwaa"
  vpc_id = data.data_platform_apps_and_tools.shared.id

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]

  tags = local.tags
}
