#### This file can be used to store locals specific to the member account ####
locals {
  availability_zones      = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets         = ["10.206.4.0/24", "10.206.5.0/24", "10.206.6.0/24"]
  public_subnets          = ["10.206.7.0/24", "10.206.8.0/24", "10.206.9.0/24"]
  database_subnets        = ["10.206.1.0/24", "10.206.2.0/24", "10.206.3.0/24"]
  nonprod_workspaces_cidr = "10.200.0.0/20"
  prod_workspaces_cidr    = "10.200.16.0/20"

  outbound_security_group_ids = {
    idm              = aws_security_group.idm_instance.id,
    oam              = aws_security_group.oam_instance.id,
    oim              = aws_security_group.oim_instance.id,
    ohs              = aws_security_group.ohs_instance.id,
    internal_ohs_alb = aws_security_group.internal_lb.id
    internal_idm_alb = aws_security_group.internal_idm_sg.id
    igdb             = aws_security_group.igdb.id
    iadb             = aws_security_group.iadb.id
  }
  portal_ec2_security_group_ids = {
    idm = aws_security_group.idm_instance.id,
    oam = aws_security_group.oam_instance.id,
    oim = aws_security_group.oim_instance.id,
    ohs = aws_security_group.ohs_instance.id
  }

  lb_logs_bucket = local.application_data.accounts[local.environment].lb_logs_bucket
  lb_cert_arn    = "arn:aws:acm:eu-west-2:${local.environment_management.account_ids["laa-portal-tactical-development"]}:certificate/${local.application_data.accounts[local.environment].lb_cert_id}"

  # RDS - IAGB and IDGB
  igdb_username = "admin"
  iadb_username = "admin"

}
