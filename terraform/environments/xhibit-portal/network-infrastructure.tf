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

resource "aws_security_group" "waf_lb" {
  description = "Security group for app load balancer, simply to implement ACL rules for the WAF"
  name        = "waf-loadbalancer-${var.networking[0].application}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group" "prtg_lb" {
  description = "Security group for prtg LoadBalancer, simply to implement ACL rules for the prtg-lb"
  name        = "prtg-loadbalancer-${var.networking[0].application}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group" "sms_server" {
  description = "Domain traffic only"
  name        = "sms-server-${local.application_name}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group" "exchange_server" {
  description = "Domain traffic only"
  name        = "exchange-server-${local.application_name}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group" "build_server" {
  description = "Bastion traffic"
  name        = "build-server-${local.application_name}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group" "iisrelay_server" {
  description = "Domain traffic"
  name        = "iisrelay-server-${local.application_name}"
  vpc_id      = local.vpc_id
}

# AWS Security Group Rules

resource "aws_security_group_rule" "build-inbound-bastion" {
  description              = "allow all traffic from bastion"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
  security_group_id        = aws_security_group.build_server.id
  depends_on               = [aws_security_group.build_server]
}

resource "aws_security_group_rule" "build-outbound-bastion" {
  description              = "allow all traffic to build_server"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
  security_group_id        = aws_security_group.build_server.id
  depends_on               = [aws_security_group.build_server]
}

resource "aws_security_group_rule" "exchange-inbound-importmachine" {
  description              = "allow all traffic from importmachine"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.exchange_server.id
  depends_on               = [aws_security_group.exchange_server]
}

resource "aws_security_group_rule" "exchange-outbound-all" {
  description       = "allow all traffic to any IP address"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.exchange_server.id
  depends_on        = [aws_security_group.exchange_server]
}

resource "aws_security_group_rule" "exchange-inbound-app" {
  description              = "allow all traffic from app_servers"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
  security_group_id        = aws_security_group.exchange_server.id
  depends_on               = [aws_security_group.exchange_server]
}

resource "aws_security_group_rule" "exchange-inbound-bastion" {
  description              = "allow all traffic from bastion"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
  security_group_id        = aws_security_group.exchange_server.id
  depends_on               = [aws_security_group.exchange_server]
}

resource "aws_security_group_rule" "sms-inbound-bastion" {
  from_port                = 3389
  protocol                 = "TCP"
  security_group_id        = aws_security_group.sms_server.id
  to_port                  = 3389
  type                     = "ingress"
  source_security_group_id = module.bastion_linux.bastion_security_group
}

resource "aws_security_group_rule" "sms-inbound-importmachine" {
  depends_on        = [aws_security_group.sms_server]
  security_group_id = aws_security_group.sms_server.id
  type              = "ingress"
  # description update gg 21 Oct
  description              = "allow all from importmachine"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "sms-inbound-app" {
  depends_on               = [aws_security_group.sms_server]
  security_group_id        = aws_security_group.sms_server.id
  type                     = "ingress"
  description              = "allow all from app"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
}

resource "aws_security_group_rule" "sms-outbound-importmachine" {
  depends_on               = [aws_security_group.sms_server]
  security_group_id        = aws_security_group.sms_server.id
  type                     = "egress"
  description              = "allow all to bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}



resource "aws_security_group_rule" "sms-outbound-all-ipv4" {
  depends_on        = [aws_security_group.sms_server]
  security_group_id = aws_security_group.sms_server.id
  type              = "egress"
  description       = "allow all ipv4"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sms-outbound-all-ipv6" {
  depends_on        = [aws_security_group.sms_server]
  security_group_id = aws_security_group.sms_server.id
  type              = "egress"
  description       = "allow all ipv6"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "waf_lb-inbound-importmachine" {
  depends_on               = [aws_security_group.waf_lb]
  security_group_id        = aws_security_group.waf_lb.id
  type                     = "ingress"
  description              = "allow all from bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "waf_lb-outbound-importmachine" {
  depends_on               = [aws_security_group.waf_lb]
  security_group_id        = aws_security_group.waf_lb.id
  type                     = "egress"
  description              = "allow all to bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "prtg_lb-inbound-importmachine" {
  depends_on               = [aws_security_group.prtg_lb]
  security_group_id        = aws_security_group.prtg_lb.id
  type                     = "ingress"
  description              = "allow HTTPS from prtg-lb to importmachine"
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "prtg_lb-outbound-importmachine" {
  depends_on               = [aws_security_group.prtg_lb]
  security_group_id        = aws_security_group.prtg_lb.id
  type                     = "egress"
  description              = "allow HTTPS to prtg-lb from importmachine"
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "egress-to-portal" {
  depends_on               = [aws_security_group.waf_lb]
  security_group_id        = aws_security_group.waf_lb.id
  type                     = "egress"
  description              = "allow web traffic to get to portal"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.portal_server.id
}

resource "aws_security_group_rule" "waf_lb_allow_web_users" {
  depends_on        = [aws_security_group.waf_lb]
  security_group_id = aws_security_group.waf_lb.id
  type              = "ingress"
  description       = "allow web traffic to get to ingestion server"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "prtg_lb_allow_web_users" {
  depends_on        = [aws_security_group.prtg_lb]
  security_group_id = aws_security_group.prtg_lb.id
  type              = "ingress"
  description       = "allow web traffic to get to prtg Load Balancer over SSL "
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}


resource "aws_security_group_rule" "ingestion_server-inbound-bastion" {
  depends_on               = [aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_server.id
  type                     = "ingress"
  description              = "allow all from bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
}

resource "aws_security_group_rule" "ingestion_server-outbound-bastion" {
  depends_on               = [aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_server.id
  type                     = "egress"
  description              = "allow all to bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
}

resource "aws_security_group_rule" "ingestion_server-inbound-importmachine" {
  depends_on               = [aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_server.id
  type                     = "ingress"
  description              = "allow all from bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "ingestion_server-outbound-importmachine" {
  depends_on               = [aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_server.id
  type                     = "egress"
  description              = "allow all to bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "portal_server-inbound-bastion" {
  depends_on               = [aws_security_group.portal_server]
  security_group_id        = aws_security_group.portal_server.id
  type                     = "ingress"
  description              = "allow all from bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
}

resource "aws_security_group_rule" "portal_server-outbound-bastion" {
  depends_on               = [aws_security_group.portal_server]
  security_group_id        = aws_security_group.portal_server.id
  type                     = "egress"
  description              = "allow all to bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
}

resource "aws_security_group_rule" "app_servers-inbound-importmachine" {
  depends_on               = [aws_security_group.app_servers]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "ingress"
  description              = "allow all from bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "app_servers-outbound-importmachine" {
  depends_on               = [aws_security_group.app_servers]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "egress"
  description              = "allow all to bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "app_servers-inbound-bastion" {
  depends_on               = [aws_security_group.app_servers]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "ingress"
  description              = "allow all from bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
}

resource "aws_security_group_rule" "app_servers-outbound-bastion" {
  depends_on               = [aws_security_group.app_servers]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "egress"
  description              = "allow all to bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
}

resource "aws_security_group_rule" "portal-inbound-importmachine" {
  depends_on               = [aws_security_group.portal_server]
  security_group_id        = aws_security_group.portal_server.id
  type                     = "ingress"
  description              = "allow all from bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "portal-outbound-importmachine" {
  depends_on               = [aws_security_group.portal_server]
  security_group_id        = aws_security_group.portal_server.id
  type                     = "egress"
  description              = "allow all to bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "portal-http-from-waf-lb" {
  depends_on               = [aws_security_group.waf_lb, aws_security_group.portal_server]
  security_group_id        = aws_security_group.portal_server.id
  type                     = "ingress"
  description              = "allow HTTP traffic from WAF LB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.waf_lb.id
}

resource "aws_security_group_rule" "portal-http-to-waf-lb" {
  depends_on               = [aws_security_group.waf_lb, aws_security_group.portal_server]
  security_group_id        = aws_security_group.portal_server.id
  type                     = "egress"
  description              = "allow HTTP traffic to WAF LB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.waf_lb.id
}
resource "aws_security_group_rule" "ingestion-lb-inbound-importmachine" {
  depends_on               = [aws_security_group.ingestion_lb]
  security_group_id        = aws_security_group.ingestion_lb.id
  type                     = "ingress"
  description              = "allow all from bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "ingestion-lb-outbound-importmachine" {
  depends_on               = [aws_security_group.ingestion_lb]
  security_group_id        = aws_security_group.ingestion_lb.id
  type                     = "egress"
  description              = "allow all to bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "ingestion-lb-http-from-ingestion-server" {
  depends_on               = [aws_security_group.ingestion_lb, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_lb.id
  type                     = "ingress"
  description              = "allow all traffic from ingestion server"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_server.id
}

resource "aws_security_group_rule" "ingestion-lb-http-to-ingestion-server" {
  depends_on               = [aws_security_group.ingestion_lb, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_lb.id
  type                     = "egress"
  description              = "allow all traffic to ingestion server"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_server.id
}

resource "aws_security_group_rule" "ingestion-server-http-from-ingestion-lb" {
  depends_on               = [aws_security_group.ingestion_lb, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_server.id
  type                     = "ingress"
  description              = "allow all traffic from ingestion LB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_lb.id
}

resource "aws_security_group_rule" "ingestion-server-http-to-ingestion-lb" {
  depends_on               = [aws_security_group.ingestion_lb, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_server.id
  type                     = "egress"
  description              = "allow all traffic to ingestion LB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_lb.id
}

resource "aws_security_group_rule" "app-all-from-self" {
  depends_on        = [aws_security_group.app_servers]
  security_group_id = aws_security_group.app_servers.id
  type              = "ingress"
  description       = "allow all traffic from local server"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
}

resource "aws_security_group_rule" "app-all-to-self" {
  depends_on        = [aws_security_group.app_servers]
  security_group_id = aws_security_group.app_servers.id
  type              = "egress"
  description       = "allow all traffic to local server"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
}

resource "aws_security_group_rule" "app-all-from-ingestion" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "ingress"
  description              = "allow all traffic from ingestion server"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_server.id
}

resource "aws_security_group_rule" "ingestion-all-from-app" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_server.id
  type                     = "ingress"
  description              = "allow all traffic from app"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
}

resource "aws_security_group_rule" "app-all-to-ingestion" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "egress"
  description              = "allow all traffic from ingestion server"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_server.id
}

resource "aws_security_group_rule" "ingestion-all-to-app" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.ingestion_server.id
  type                     = "egress"
  description              = "allow all traffic to ingestion server"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
}

resource "aws_security_group_rule" "exchange-all-from-app" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "egress"
  description              = "allow all traffic to Exchange server"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.exchange_server.id
}

resource "aws_security_group_rule" "exchange-all-to-app" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "ingress"
  description              = "allow all traffic from Exchange server"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.exchange_server.id
}

resource "aws_security_group_rule" "sms-all-from-app" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "egress"
  description              = "allow all traffic to SMS server"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.sms_server.id
}

resource "aws_security_group_rule" "sms-all-to-app" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "ingress"
  description              = "allow all traffic from SMS server"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.sms_server.id
}

resource "aws_security_group_rule" "app-all-from-portal" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "ingress"
  description              = "allow all traffic from portal server"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.portal_server.id
}

resource "aws_security_group_rule" "portal-all-from-app" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
  security_group_id        = aws_security_group.portal_server.id
  type                     = "ingress"
  description              = "allow all traffic from app"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
}

resource "aws_security_group_rule" "app-all-to-portal" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "egress"
  description              = "allow all traffic to portal server"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.portal_server.id
}

resource "aws_security_group_rule" "portal-all-to-app" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
  security_group_id        = aws_security_group.portal_server.id
  type                     = "egress"
  description              = "allow all traffic to app"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
}

resource "aws_security_group_rule" "iisrelay-inbound-importmachine" {
  depends_on               = [aws_security_group.iisrelay_server]
  security_group_id        = aws_security_group.iisrelay_server.id
  type                     = "ingress"
  description              = "allow all from importmachine"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
}

resource "aws_security_group_rule" "iisrelay-outbound-all" {
  depends_on        = [aws_security_group.iisrelay_server]
  security_group_id = aws_security_group.iisrelay_server.id
  type              = "egress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "iisrelay-inbound-app" {
  depends_on               = [aws_security_group.iisrelay_server]
  security_group_id        = aws_security_group.iisrelay_server.id
  type                     = "ingress"
  description              = "allow all"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
}

resource "aws_security_group_rule" "iisrelay-inbound-bastion" {
  depends_on               = [aws_security_group.iisrelay_server]
  security_group_id        = aws_security_group.iisrelay_server.id
  type                     = "ingress"
  description              = "allow all from bastion"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
}

resource "aws_security_group_rule" "iisrelay-inbound-exchange" {
  depends_on               = [aws_security_group.iisrelay_server]
  security_group_id        = aws_security_group.iisrelay_server.id
  type                     = "ingress"
  description              = "allow from exchange"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.exchange_server.id
}

resource "aws_security_group_rule" "app-all-to-iisrelay" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "egress"
  description              = "allow all app traffic from iisrelay"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.iisrelay_server.id
}

resource "aws_security_group_rule" "iisrelay-to-app-all" {
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
  security_group_id        = aws_security_group.app_servers.id
  type                     = "ingress"
  description              = "allow all iisrelay to appservers"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.iisrelay_server.id
}
