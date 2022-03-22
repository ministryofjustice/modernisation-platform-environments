# get shared subnet-set private (az (a) subnet)
data "aws_subnet" "private_az_a" {
  # provider = aws.share-host
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}a"
  }
}

# get shared subnet-set private (az (b) subnet)
data "aws_subnet" "private_az_b" {
  # provider = aws.share-host
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}b"
  }
}

# get shared subnet-set public (az (a) subnet)
data "aws_subnet" "public_az_a" {
  # provider = aws.share-host
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-public-${local.region}a"
  }
}

# get shared subnet-set public (az (b) subnet)
data "aws_subnet" "public_az_b" {
  # provider = aws.share-host
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-public-${local.region}b"
  }
}

resource "aws_security_group" "ingestion_server" {
  description = "Servers conected to the ingestion load balancer"
  name        = "ingestion-servers-${local.application_name}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group" "portal_server" {
  description = "Servers conected to the portal load balancer"
  name        = "web-servers-${local.application_name}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group" "app_servers" {
  description = "Servers not conected to the load balancer"
  name        = "app-servers-${local.application_name}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "ingestion_server-inbound-bastion" {
  depends_on        = [aws_security_group.ingestion_server]
  security_group_id = aws_security_group.ingestion_server.id
  type              = "ingress"
  description       = "allow all from bastion"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${module.bastion_linux.bastion_private_ip}/32"]
}

resource "aws_security_group_rule" "ingestion_server-outbound-bastion" {
  depends_on        = [aws_security_group.ingestion_server]
  security_group_id = aws_security_group.ingestion_server.id
  type              = "egress"
  description       = "allow all to bastion"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${module.bastion_linux.bastion_private_ip}/32"]
}

resource "aws_security_group_rule" "portal_server-inbound-bastion" {
  depends_on        = [aws_security_group.portal_server]
  security_group_id = aws_security_group.portal_server.id
  type              = "ingress"
  description       = "allow all from bastion"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${module.bastion_linux.bastion_private_ip}/32"]
}

resource "aws_security_group_rule" "portal_server-outbound-bastion" {
  depends_on        = [aws_security_group.portal_server]
  security_group_id = aws_security_group.portal_server.id
  type              = "egress"
  description       = "allow all to bastion"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${module.bastion_linux.bastion_private_ip}/32"]
}

resource "aws_security_group_rule" "app_servers-inbound-bastion" {
  depends_on        = [aws_security_group.app_servers]
  security_group_id = aws_security_group.app_servers.id
  type              = "ingress"
  description       = "allow all from bastion"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${module.bastion_linux.bastion_private_ip}/32"]
}

resource "aws_security_group_rule" "app_servers-outbound-bastion" {
  depends_on        = [aws_security_group.app_servers]
  security_group_id = aws_security_group.app_servers.id
  type              = "egress"
  description       = "allow all to bastion"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["${module.bastion_linux.bastion_private_ip}/32"]
}

# resource "aws_security_group_rule" "portal-https-from-waf-lb" {
#   depends_on               = [aws_security_group.waf_lb, aws_security_group.portal_server]
#   security_group_id        = aws_security_group.portal_server.id
#   type                     = "ingress"
#   description              = "allow all traffic from DB"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.waf_lb.id
# }

resource "aws_security_group_rule" "portal-http-from-waf-lb" {
  depends_on               = [aws_security_group.waf_lb, aws_security_group.portal_server]
  security_group_id        = aws_security_group.portal_server.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.waf_lb.id
}

# resource "aws_security_group_rule" "portal-https-to-waf-lb" {
#   depends_on               = [aws_security_group.waf_lb, aws_security_group.portal_server]
#   security_group_id        = aws_security_group.portal_server.id
#   type                     = "egress"
#   description              = "allow all traffic from DB"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.waf_lb.id
# }

resource "aws_security_group_rule" "portal-http-to-waf-lb" {
  depends_on               = [aws_security_group.waf_lb, aws_security_group.portal_server]
  security_group_id        = aws_security_group.portal_server.id
  type                     = "egress"
  description              = "allow all traffic from DB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.waf_lb.id
}

# resource "aws_security_group_rule" "ingestion-lb-https-from-ingestion-server" {
#   depends_on               = [aws_security_group.ingestion_lb, aws_security_group.ingestion_server]
#   security_group_id        = aws_security_group.ingestion_lb.id
#   type                     = "ingress"
#   description              = "allow all traffic from DB"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.ingestion_server.id
# }

resource "aws_security_group_rule" "ingestion-lb-http-from-ingestion-server" {
  depends_on               = [aws_security_group.ingestion_lb, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_lb.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.ingestion_server.id
}

# resource "aws_security_group_rule" "ingestion-lb-https-to-ingestion-server" {
#   depends_on               = [aws_security_group.ingestion_lb, aws_security_group.ingestion_server]
#   security_group_id        = aws_security_group.ingestion_lb.id
#   type                     = "egress"
#   description              = "allow all traffic from DB"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.ingestion_server.id
# }

resource "aws_security_group_rule" "ingestion-lb-http-to-ingestion-server" {
  depends_on               = [aws_security_group.ingestion_lb, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_lb.id
  type                     = "egress"
  description              = "allow all traffic from DB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.ingestion_server.id
}

resource "aws_security_group_rule" "app-all-from-ingestion" {
  depends_on               = [aws_security_group.app_servers]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  self                     = true
}

resource "aws_security_group_rule" "app-all-from-ingestion" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_server.id
}

resource "aws_security_group_rule" "ingestion-all-from-app" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_server.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
}

resource "aws_security_group_rule" "app-all-to-ingestion" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "egress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_server.id
}

resource "aws_security_group_rule" "ingestion-all-to-app" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_server.id
  type                     = "egress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
}

resource "aws_security_group_rule" "app-all-from-portal" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.portal_server.id
}

resource "aws_security_group_rule" "portal-all-from-app" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
  security_group_id        = aws_security_group.portal_server.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
}

resource "aws_security_group_rule" "app-all-to-portal" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "egress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.portal_server.id
}

resource "aws_security_group_rule" "portal-all-to-app" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
  security_group_id        = aws_security_group.portal_server.id
  type                     = "egress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
}
