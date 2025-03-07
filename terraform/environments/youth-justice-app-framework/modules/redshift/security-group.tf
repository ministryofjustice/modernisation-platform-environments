module "redshift_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id      = var.vpc_id
  name        = "Redshift Serverless"
  description = "Control access to and from Redshift Servless"

  
  ingress_with_self = [{rule = "all-all"}]
  egress_with_self  = [{rule = "all-all"}]

}

