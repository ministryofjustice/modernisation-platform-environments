/*
##################################################
# Airflow
##################################################

module "airflow_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.0.0"

  name   = "data-platform-airflow-${local.environment}"
  vpc_id = data.aws_vpc.data_platform_apps_and_tools.id

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]

  tags = local.tags
}
*/
