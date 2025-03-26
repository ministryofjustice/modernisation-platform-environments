module "redshift_sg" {
  # checkov:skip=CKV_TF_1

  source  = "terraform-aws-modules/security-group/aws"
  version = "4.13.0"

  vpc_id      = var.vpc_id
  name        = "Redshift Serverless"
  description = "Control access to and from Redshift Servless"

  
  ingress_with_self = [{rule = "all-all"}]
  egress_with_self  = [{rule = "all-all"}]

  ingress_with_source_security_group_id = [{
    description              = "Redshift ingress from PostgreSQL"
    rule                     = "redshift-tcp"
    source_security_group_id = var.postgres_security_group_id
  }]

}
