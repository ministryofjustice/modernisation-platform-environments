resource "aws_security_group" "ebsapps_alb" {
  name        = "${local.component_name}-${local.env_label}-alb-sg"
  description = "Controls access to the EBS apps application load balancer"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags, {
    Name = "${local.component_name}-${local.env_label}-alb-sg"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_vpc" {
  security_group_id = aws_security_group.ebsapps_alb.id
  description       = "HTTPS from the shared VPC"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_mojo_devices" {
  security_group_id = aws_security_group.ebsapps_alb.id
  description       = "HTTPS from Mojo Devices"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = local.application_data.accounts[local.environment].mojo_devices
}

resource "aws_vpc_security_group_egress_rule" "alb_to_apps" {
  security_group_id            = aws_security_group.ebsapps_alb.id
  description                  = "Traffic to EBS apps on application port"
  ip_protocol                  = "tcp"
  from_port                    = local.application_data.accounts[local.environment].tg_apps_port
  to_port                      = local.application_data.accounts[local.environment].tg_apps_port
  referenced_security_group_id = aws_security_group.ebsapps.id
}
