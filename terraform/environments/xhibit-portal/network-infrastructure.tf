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

resource "aws_security_group" "ingestion-servers" {
  description = "Servers conected to the load balancer"
  name        = "ingestion-servers-${local.application_name}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group" "app-servers" {
  description = "Servers not conected to the load balancer"
  name        = "app-servers-${local.application_name}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "ingestion-https-from-waf" {
  depends_on               = [aws_security_group.waf_lb, aws_security_group.ingestion-servers]
  security_group_id        = aws_security_group.ingestion-servers.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.waf_lb.id
}

resource "aws_security_group_rule" "ingestion-http-from-waf" {
  depends_on               = [aws_security_group.waf_lb, aws_security_group.ingestion-servers]
  security_group_id        = aws_security_group.ingestion-servers.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.waf_lb.id
}

resource "aws_security_group_rule" "ingestion-https-to-waf" {
  depends_on               = [aws_security_group.waf_lb, aws_security_group.ingestion-servers]
  security_group_id        = aws_security_group.ingestion-servers.id
  type                     = "egress"
  description              = "allow all traffic from DB"
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.waf_lb.id
}

resource "aws_security_group_rule" "ingestion-http-to-waf" {
  depends_on               = [aws_security_group.waf_lb, aws_security_group.ingestion-servers]
  security_group_id        = aws_security_group.ingestion-servers.id
  type                     = "egress"
  description              = "allow all traffic from DB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.waf_lb.id
}

resource "aws_security_group_rule" "waf-https-from-ingestion" {
  depends_on               = [aws_security_group.waf_lb, aws_security_group.ingestion-servers]
  security_group_id        = aws_security_group.waf_lb.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.ingestion-servers.id
}

resource "aws_security_group_rule" "waf-http-from-ingestion" {
  depends_on               = [aws_security_group.waf_lb, aws_security_group.ingestion-servers]
  security_group_id        = aws_security_group.waf_lb.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.ingestion-servers.id
}

resource "aws_security_group_rule" "waf-https-to-ingestion" {
  depends_on               = [aws_security_group.waf_lb, aws_security_group.ingestion-servers]
  security_group_id        = aws_security_group.waf_lb.id
  type                     = "egress"
  description              = "allow all traffic from DB"
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.ingestion-servers.id
}

resource "aws_security_group_rule" "waf-http-to-ingestion" {
  depends_on               = [aws_security_group.waf_lb, aws_security_group.ingestion-servers]
  security_group_id        = aws_security_group.waf_lb.id
  type                     = "egress"
  description              = "allow all traffic from DB"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.ingestion-servers.id
}

resource "aws_security_group_rule" "app-all-from-ingestion" {
  depends_on               = [aws_security_group.app-servers, aws_security_group.ingestion-servers]
  security_group_id        = aws_security_group.app-servers.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion-servers.id
}

resource "aws_security_group_rule" "ingestion-all-from-app" {
  depends_on               = [aws_security_group.app-servers, aws_security_group.ingestion-servers]
  security_group_id        = aws_security_group.ingestion-servers.id
  type                     = "ingress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app-servers.id
}

resource "aws_security_group_rule" "app-all-to-ingestion" {
  depends_on               = [aws_security_group.app-servers, aws_security_group.ingestion-servers]
  security_group_id        = aws_security_group.app-servers.id
  type                     = "egress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.ingestion-servers.id
}

resource "aws_security_group_rule" "ingestion-all-to-app" {
  depends_on               = [aws_security_group.app-servers, aws_security_group.ingestion-servers]
  security_group_id        = aws_security_group.ingestion-servers.id
  type                     = "egress"
  description              = "allow all traffic from DB"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.app-servers.id
}
