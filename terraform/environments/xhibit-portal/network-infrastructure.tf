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
  description              = "allow all traffic to bastion"
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
  # checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
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
  description              = "allow RDP traffic from bastion"
  type                     = "ingress"
  from_port                = 3389
  to_port                  = 3389
  protocol                 = "TCP"
  source_security_group_id = module.bastion_linux.bastion_security_group
  security_group_id        = aws_security_group.sms_server.id
}

resource "aws_security_group_rule" "sms-inbound-importmachine" {
  description              = "allow all traffic from importmachine"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.sms_server.id
  depends_on               = [aws_security_group.sms_server]
}

resource "aws_security_group_rule" "sms-inbound-app" {
  description              = "allow all traffic from app_servers"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
  security_group_id        = aws_security_group.sms_server.id
  depends_on               = [aws_security_group.sms_server]
}

resource "aws_security_group_rule" "sms-outbound-importmachine" {
  description              = "allow all traffic to importmachine"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.sms_server.id
  depends_on               = [aws_security_group.sms_server]
}

resource "aws_security_group_rule" "sms-outbound-all" {
  # checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  description       = "allow all traffic to any IP address"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sms_server.id
  depends_on        = [aws_security_group.sms_server]
}

resource "aws_security_group_rule" "waf_lb-inbound-importmachine" {
  description              = "allow all traffic from importmachine"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.waf_lb.id
  depends_on               = [aws_security_group.waf_lb]
}

resource "aws_security_group_rule" "waf_lb-outbound-importmachine" {
  description              = "allow all traffic to importmachine"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.waf_lb.id
  depends_on               = [aws_security_group.waf_lb]
}

resource "aws_security_group_rule" "egress-to-portal" {
  description              = "allow HTTP traffic to portal_server"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.portal_server.id
  security_group_id        = aws_security_group.waf_lb.id
  depends_on               = [aws_security_group.waf_lb]
}

resource "aws_security_group_rule" "waf_lb_allow_web_users" {
  description       = "allow HTTPS traffic to waf_lb"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.waf_lb.id
  depends_on        = [aws_security_group.waf_lb]
}

resource "aws_security_group_rule" "prtg_lb-inbound-importmachine" {
  description              = "allow HTTPS traffic from importmachine"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.prtg_lb.id
  depends_on               = [aws_security_group.prtg_lb]
}

resource "aws_security_group_rule" "prtg_lb-outbound-importmachine" {
  description              = "allow HTTPS traffic to importmachine"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.prtg_lb.id
  depends_on               = [aws_security_group.prtg_lb]
}

resource "aws_security_group_rule" "prtg_lb_allow_web_users" {
  description       = "allow HTTPS traffic from any IP address"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.prtg_lb.id
  depends_on        = [aws_security_group.prtg_lb]
}

resource "aws_security_group_rule" "ingestion_server-inbound-bastion" {
  description              = "allow all traffic from bastion"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
  security_group_id        = aws_security_group.ingestion_server.id
  depends_on               = [aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "ingestion_server-outbound-bastion" {
  description              = "allow all traffic to bastion"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
  security_group_id        = aws_security_group.ingestion_server.id
  depends_on               = [aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "ingestion_server-inbound-importmachine" {
  description              = "allow all traffic from importmachine"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.ingestion_server.id
  depends_on               = [aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "ingestion_server-outbound-importmachine" {
  description              = "allow all traffic to importmachine"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.ingestion_server.id
  depends_on               = [aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "portal_server-inbound-bastion" {
  description              = "allow all traffic from bastion"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
  security_group_id        = aws_security_group.portal_server.id
  depends_on               = [aws_security_group.portal_server]
}

resource "aws_security_group_rule" "portal_server-outbound-bastion" {
  description              = "allow all traffic to bastion"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
  security_group_id        = aws_security_group.portal_server.id
  depends_on               = [aws_security_group.portal_server]
}

resource "aws_security_group_rule" "portal-inbound-importmachine" {
  description              = "allow all traffic from importmachine"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.portal_server.id
  depends_on               = [aws_security_group.portal_server]
}

resource "aws_security_group_rule" "portal-outbound-importmachine" {
  description              = "allow all traffic to importmachine"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.portal_server.id
  depends_on               = [aws_security_group.portal_server]
}

resource "aws_security_group_rule" "portal-http-from-waf-lb" {
  description              = "allow HTTP traffic from waf_lb"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.waf_lb.id
  security_group_id        = aws_security_group.portal_server.id
  depends_on               = [aws_security_group.waf_lb, aws_security_group.portal_server]
}

resource "aws_security_group_rule" "portal-http-to-waf-lb" {
  description              = "allow HTTP traffic to waf_lb"
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.waf_lb.id
  security_group_id        = aws_security_group.portal_server.id
  depends_on               = [aws_security_group.waf_lb, aws_security_group.portal_server]
}

resource "aws_security_group_rule" "app_servers-inbound-importmachine" {
  description              = "allow all traffic from importmachine"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers]
}

resource "aws_security_group_rule" "app_servers-outbound-importmachine" {
  description              = "allow all traffic to importmachine"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers]
}

resource "aws_security_group_rule" "app_servers-inbound-bastion" {
  description              = "allow all traffic from bastion"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers]
}

resource "aws_security_group_rule" "app_servers-outbound-bastion" {
  description              = "allow all traffic to bastion"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers]
}

resource "aws_security_group_rule" "app-all-from-self" {
  description       = "allow all traffic from local server"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.app_servers.id
  depends_on        = [aws_security_group.app_servers]
}

resource "aws_security_group_rule" "app-all-to-self" {
  description       = "allow all traffic to local server"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.app_servers.id
  depends_on        = [aws_security_group.app_servers]
}

resource "aws_security_group_rule" "app-all-from-ingestion" {
  description              = "allow all traffic from ingestion_server"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_server.id
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "app-all-to-ingestion" {
  description              = "allow all traffic from ingestion_server"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_server.id
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "ingestion-lb-inbound-importmachine" {
  description              = "allow all traffic from importmachine"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.ingestion_lb.id
  depends_on               = [aws_security_group.ingestion_lb]
}

resource "aws_security_group_rule" "ingestion-lb-outbound-importmachine" {
  description              = "allow all traffic to importmachine"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.ingestion_lb.id
  depends_on               = [aws_security_group.ingestion_lb]
}

resource "aws_security_group_rule" "ingestion-lb-http-from-ingestion-server" {
  description              = "allow all traffic from ingestion_server"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_server.id
  security_group_id        = aws_security_group.ingestion_lb.id
  depends_on               = [aws_security_group.ingestion_lb, aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "ingestion-lb-http-to-ingestion-server" {
  description              = "allow all traffic to ingestion_server"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_server.id
  security_group_id        = aws_security_group.ingestion_lb.id
  depends_on               = [aws_security_group.ingestion_lb, aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "ingestion-server-http-from-ingestion-lb" {
  description              = "allow all traffic from ingestion LB"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_lb.id
  security_group_id        = aws_security_group.ingestion_server.id
  depends_on               = [aws_security_group.ingestion_lb, aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "ingestion-server-http-to-ingestion-lb" {
  description              = "allow all traffic to ingestion LB"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion_lb.id
  security_group_id        = aws_security_group.ingestion_server.id
  depends_on               = [aws_security_group.ingestion_lb, aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "ingestion-all-from-app" {
  description              = "allow all traffic from app_servers"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
  security_group_id        = aws_security_group.ingestion_server.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "ingestion-all-to-app" {
  description              = "allow all traffic to app_servers"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
  security_group_id        = aws_security_group.ingestion_server.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "exchange-all-to-app" {
  description              = "allow all traffic from exchange_server"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.exchange_server.id
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
}

resource "aws_security_group_rule" "exchange-all-from-app" {
  description              = "allow all traffic to exchange_server"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.exchange_server.id
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
}

resource "aws_security_group_rule" "sms-all-to-app" {
  description              = "allow all traffic from SMS server"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.sms_server.id
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
}

resource "aws_security_group_rule" "sms-all-from-app" {
  description              = "allow all traffic to SMS server"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.sms_server.id
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
}

resource "aws_security_group_rule" "app-all-from-portal" {
  description              = "allow all traffic from portal server"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.portal_server.id
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
}

resource "aws_security_group_rule" "app-all-to-portal" {
  description              = "allow all traffic to portal server"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.portal_server.id
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
}

resource "aws_security_group_rule" "portal-all-from-app" {
  description              = "allow all traffic from app_servers"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
  security_group_id        = aws_security_group.portal_server.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
}

resource "aws_security_group_rule" "portal-all-to-app" {
  description              = "allow all traffic to app_servers"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
  security_group_id        = aws_security_group.portal_server.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.portal_server]
}

resource "aws_security_group_rule" "iisrelay-inbound-importmachine" {
  description              = "allow all traffic from importmachine"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.importmachine.id
  security_group_id        = aws_security_group.iisrelay_server.id
  depends_on               = [aws_security_group.iisrelay_server]
}

resource "aws_security_group_rule" "iisrelay-outbound-all" {
  # checkov:skip=CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
  description       = "allow all traffic to any IP address"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.iisrelay_server.id
  depends_on        = [aws_security_group.iisrelay_server]
}

resource "aws_security_group_rule" "iisrelay-inbound-app" {
  description              = "allow all traffic from app_servers"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app_servers.id
  security_group_id        = aws_security_group.iisrelay_server.id
  depends_on               = [aws_security_group.iisrelay_server]
}

resource "aws_security_group_rule" "iisrelay-inbound-bastion" {
  description              = "allow all traffic from bastion"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = module.bastion_linux.bastion_security_group
  security_group_id        = aws_security_group.iisrelay_server.id
  depends_on               = [aws_security_group.iisrelay_server]
}

resource "aws_security_group_rule" "iisrelay-inbound-exchange" {
  description              = "allow all traffic from exchange_server"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.exchange_server.id
  security_group_id        = aws_security_group.iisrelay_server.id
  depends_on               = [aws_security_group.iisrelay_server]
}

resource "aws_security_group_rule" "iisrelay-to-app-all" {
  description              = "allow all traffic from iisrelay_server"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.iisrelay_server.id
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
}

resource "aws_security_group_rule" "app-all-to-iisrelay" {
  description              = "allow all traffic to iisrelay_server"
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.iisrelay_server.id
  security_group_id        = aws_security_group.app_servers.id
  depends_on               = [aws_security_group.app_servers, aws_security_group.ingestion_server]
}
