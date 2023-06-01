##################################################
# Airflow
##################################################

# Based on option 2 from https://docs.aws.amazon.com/mwaa/latest/userguide/vpc-create.html#vpc-create-options
module "airflow_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.17.2"

  name        = "data-platform-mwaa"
  vpc_id      = data.aws_vpc.mp_platforms_development.id

  ingress_with_self = [
    {
      rule = "all-all"
    }
  ]
}