resource "aws_security_group" "PPUD-WEB-Portal" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "PPUD-WEB-Portal"
  description = "PPUD-WEB-Portal for Dev, UAT & PROD"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "PPUD-WEB-Portal-ingress" {
  description              = "Rule to allow port 443 traffic inbound"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.PPUD-ALB.id
  security_group_id        = aws_security_group.PPUD-WEB-Portal.id
}

resource "aws_security_group_rule" "PPUD-WEB-Portal-ingress-1" {
  description       = "Rule to allow port 80 traffic inbound"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-WEB-Portal.id
}

resource "aws_security_group_rule" "PPUD-WEB-Portal-ingress-2" {
  description       = "Rule to allow port 3389 traffic inbound"
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-WEB-Portal.id
}

resource "aws_security_group_rule" "PPUD-WEB-Portal-egress" {
  description       = "Rule to allow all traffic outbound"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-WEB-Portal.id
}

resource "aws_security_group_rule" "PPUD-WEB-Portal-egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-WEB-Portal.id
}

resource "aws_security_group_rule" "PPUD-WEB-Portal-egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-WEB-Portal.id
}

resource "aws_security_group" "WAM-Portal" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "WAM-Portal"
  description = "WAM-Portal for Dev, UAT & PROD"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "WAM-Portal-ingress" {
  description       = "Rule to allow port 80 traffic inbound"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-Portal.id
}

resource "aws_security_group_rule" "WAM-Portal-ingress-1" {
  description       = "Rule to allow port 3389 traffic inbound"
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-Portal.id
}

resource "aws_security_group_rule" "WAM-Portal-egress" {
  description       = "Rule to allow all traffic outbound"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-Portal.id
}

resource "aws_security_group_rule" "WAM-Portal-egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WAM-Portal.id
}

resource "aws_security_group_rule" "WAM-Portal-egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WAM-Portal.id
}

resource "aws_security_group" "WAM-Data-Access-Server" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "WAM-Data-Access-Server"
  description = "WAM-Data-Access-Server for Dev, UAT & PROD"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "WAM-Data-Access-Server-ingress" {
  description       = "Rule to allow port 80 traffic inbound"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-Data-Access-Server.id
}

resource "aws_security_group_rule" "WAM-Data-Access-Server-ingress-1" {
  description       = "Rule to allow port 3389 traffic inbound"
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-Data-Access-Server.id
}


resource "aws_security_group_rule" "WAM-Data-Access-Server-egress" {
  description       = "Rule to allow all traffic outbound"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-Data-Access-Server.id
}

resource "aws_security_group_rule" "WAM-Data-Access-Server-Egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WAM-Data-Access-Server.id
}

resource "aws_security_group_rule" "WAM-Data-Access-Server-Egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WAM-Data-Access-Server.id
}

resource "aws_security_group" "SCR-Team-Foundation-Server" {
  count       = local.is-development == true ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw109"
  description = "SCR-Team-Foundation-Server"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress" {
  description       = "Rule to allow port 8080 traffic inbound"
  count             = local.is-development == true ? 1 : 0
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.SCR-Team-Foundation-Server[0].id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress-1" {
  description       = "Rule to allow port 80 traffic inbound"
  count             = local.is-development == true ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.SCR-Team-Foundation-Server[0].id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress-2" {
  description       = "Rule to allow port 3389 traffic inbound"
  count             = local.is-development == true ? 1 : 0
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.SCR-Team-Foundation-Server[0].id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Egress" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.SCR-Team-Foundation-Server[0].id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.SCR-Team-Foundation-Server[0].id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.SCR-Team-Foundation-Server[0].id
}

resource "aws_security_group" "Dev-Box-VW106" {
  count       = local.is-development == true ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw106"
  description = "Dev-Box-VW106"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }

  ingress = []
}

resource "aws_security_group_rule" "Dev-Box-VW106-Egress" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Dev-Box-VW106[0].id
}

resource "aws_security_group_rule" "Dev-Box-VW106-Egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Dev-Box-VW106[0].id
}

resource "aws_security_group_rule" "Dev-Box-VW106-Egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Dev-Box-VW106[0].id
}

resource "aws_security_group" "Dev-Box-VW107" {
  count       = local.is-development == true ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw107"
  description = "Dev-Box-VW107"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }


  ingress = []
}

resource "aws_security_group_rule" "Dev-Box-VW107-Egress" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Dev-Box-VW107[0].id
}

resource "aws_security_group_rule" "Dev-Box-VW107-Egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Dev-Box-VW107[0].id
}

resource "aws_security_group_rule" "Dev-Box-VW107-Egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Dev-Box-VW107[0].id
}

resource "aws_security_group" "Dev-Box-VW108" {
  count       = local.is-development == true ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw108"
  description = "Dev-Box-VW108"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }

  ingress = []
}

resource "aws_security_group_rule" "Dev-Box-VW108-Egress" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Dev-Box-VW108[0].id
}

resource "aws_security_group_rule" "Dev-Box-VW108-Egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Dev-Box-VW108[0].id
}

resource "aws_security_group_rule" "Dev-Box-VW108-Egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Dev-Box-VW108[0].id
}

resource "aws_security_group" "Primary-DOC-Server" {
  count       = local.is-preproduction == false ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "Primary-DOC-Server"
  description = "Primary-DOC-Server for DEV & PROD"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "Primary-DOC-Server-Ingress" {
  description       = "Rule to allow port 80 traffic inbound"
  count             = local.is-preproduction == false ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Primary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Primary-DOC-Server-Ingress-1" {
  description       = "Rule to allow port 445 traffic inbound"
  count             = local.is-preproduction == false ? 1 : 0
  type              = "ingress"
  from_port         = 445
  to_port           = 445
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Primary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Primary-DOC-Server-Ingress-2" {
  description       = "Rule to allow port 3389 traffic inbound"
  count             = local.is-preproduction == false ? 1 : 0
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Primary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Primary-DOC-Server-Egress" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-preproduction == false ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Primary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Primary-DOC-Server-Egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  count             = local.is-preproduction == false ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Primary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Primary-DOC-Server-Egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  count             = local.is-preproduction == false ? 1 : 0
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Primary-DOC-Server[0].id
}


resource "aws_security_group" "Secondary-DOC-Server" {
  count       = local.is-preproduction == false ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "Secondary-DOC-Server"
  description = "Secondary-DOC-Server for DEV & PROD"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "Secondary-DOC-Server-Ingress" {
  description       = "Rule to allow port 80 traffic inbound"
  count             = local.is-preproduction == false ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Secondary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Secondary-DOC-Server-Ingress-1" {
  description       = "Rule to allow port 445 traffic inbound"
  count             = local.is-preproduction == false ? 1 : 0
  type              = "ingress"
  from_port         = 445
  to_port           = 445
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Secondary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Secondary-DOC-Server-Ingress-2" {
  description       = "Rule to allow port 3389 traffic inbound"
  count             = local.is-preproduction == false ? 1 : 0
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Secondary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Secondary-DOC-Server-Egress" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-preproduction == false ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Secondary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Secondary-DOC-Server-Egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  count             = local.is-preproduction == false ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Secondary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Secondary-DOC-Server-Egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  count             = local.is-preproduction == false ? 1 : 0
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Secondary-DOC-Server[0].id
}

resource "aws_security_group" "PPUD-Database-Server" {
  count       = local.is-development == true ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw100"
  description = "PPUD-Database-Server"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "PPUD-Database-Server-Ingress" {
  description       = "Rule to allow port 1433 traffic inbound"
  count             = local.is-development == true ? 1 : 0
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-Database-Server[0].id
}

resource "aws_security_group_rule" "PPUD-Database-Server-Ingress-1" {
  description       = "Rule to allow port 3389 traffic inbound"
  count             = local.is-development == true ? 1 : 0
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-Database-Server[0].id
}

resource "aws_security_group_rule" "PPUD-Database-Server-Egress" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-Database-Server[0].id
}

resource "aws_security_group_rule" "PPUD-Database-Server-Egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-Database-Server[0].id
}

resource "aws_security_group_rule" "PPUD-Database-Server-Egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-Database-Server[0].id
}

resource "aws_security_group" "PPUD-ALB" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "PPUD-ALB"
  description = "PPUD-ALB"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "PPUD-ALB-Ingress" {
  description       = "Rule to allow port 443 traffic inbound"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-ALB.id
}

resource "aws_security_group_rule" "PPUD-ALB-Egress" {
  description       = "Rule to allow port 443 traffic outbound"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-ALB.id
}

resource "aws_security_group_rule" "PPUD-ALB-Egress-1" {
  description       = "Rule to allow port 80 traffic outbound"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-ALB.id
}

resource "aws_security_group" "WAM-ALB" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "WAM-ALB"
  description = "WAM-ALB"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "WAM-ALB-Ingress" {
  description       = "Rule to allow port 443 traffic inbound"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WAM-ALB.id
}

resource "aws_security_group_rule" "WAM-ALB-Egress" {
  description       = "Rule to allow port 80 traffic outbound"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-ALB.id
}
resource "aws_security_group_rule" "WAM-ALB-Egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-ALB.id
}

resource "aws_security_group" "Bridge-Server" {
  count       = local.is-development == false ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "UAT-Bridge-Server"
  description = "Bridge-Server for UAT & PROD"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "UAT-Bridge-Server-Ingress" {
  description       = "Rule to allow port 80 traffic inbound"
  count             = local.is-development == false ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Bridge-Server[0].id
}

resource "aws_security_group_rule" "UAT-Bridge-Server-Ingress-1" {
  description       = "Rule to allow port 3389 traffic inbound"
  count             = local.is-development == false ? 1 : 0
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Bridge-Server[0].id
}

resource "aws_security_group_rule" "UAT-Bridge-Server-Egress" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-development == false ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Bridge-Server[0].id
}
resource "aws_security_group_rule" "UAT-Bridge-Server-Egress-1" {
  description       = "Rule to allow port 445 traffic outbound"
  count             = local.is-development == false ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Bridge-Server[0].id
}

resource "aws_security_group_rule" "UAT-Bridge-Server-Egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  count             = local.is-development == false ? 1 : 0
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Bridge-Server[0].id
}

resource "aws_security_group" "UAT-Document-Service" {
  count       = local.is-preproduction == true ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "UAT-Document-Service"
  description = "Document-Service for UAT"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "UAT-Document-Service-Ingress" {
  description       = "Rule to allow port 80 traffic inbound"
  count             = local.is-preproduction == true ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.UAT-Document-Service[0].id
}

resource "aws_security_group_rule" "UAT-Document-Service-Ingress-1" {
  description       = "Rule to allow port 1433 traffic inbound"
  count             = local.is-preproduction == true ? 1 : 0
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.UAT-Document-Service[0].id
}

resource "aws_security_group_rule" "UAT-Document-Service-Ingress-2" {
  description       = "Rule to allow port 3389 traffic inbound"
  count             = local.is-preproduction == true ? 1 : 0
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.UAT-Document-Service[0].id
}

resource "aws_security_group_rule" "UAT-Document-Service-Egress" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-preproduction == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.UAT-Document-Service[0].id
}

resource "aws_security_group_rule" "UAT-Document-Service-Egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  count             = local.is-preproduction == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.UAT-Document-Service[0].id
}

resource "aws_security_group_rule" "UAT-Document-Service-Egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  count             = local.is-preproduction == true ? 1 : 0
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.UAT-Document-Service[0].id
}

resource "aws_security_group" "PPUD-PROD-Database" {
  count       = local.is-production == true ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "s618358rgvw021"
  description = "PPUD-PROD-Database"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "PPUD-PROD-Database-Ingress" {
  description       = "Rule to allow port 3180 traffic inbound"
  count             = local.is-production == true ? 1 : 0
  type              = "ingress"
  from_port         = 3180
  to_port           = 3180
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-PROD-Database[0].id
}

resource "aws_security_group_rule" "PPUD-PROD-Database-Ingress-1" {
  description       = "Rule to allow port 3389 traffic inbound"
  count             = local.is-production == true ? 1 : 0
  type              = "ingress"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-PROD-Database[0].id
}

resource "aws_security_group_rule" "PPUD-PROD-Database-Egress" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-PROD-Database[0].id
}

resource "aws_security_group_rule" "PPUD-Database-Egress-1" {
  description       = "Rule to allow port 443 traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-PROD-Database[0].id
}

resource "aws_security_group_rule" "PPUD-Database-Egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-PROD-Database[0].id
}

resource "aws_security_group" "PPUD-Mail-Server" {
  count       = local.is-production == true ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "PPUD-Mail-Server"
  description = "PPUD-Mail-Server"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "PPUD-Mail-Server-Ingress" {
  description       = "Rule to allow port 25 traffic inbound"
  count             = local.is-production == true ? 1 : 0
  type              = "ingress"
  from_port         = 25
  to_port           = 25
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-Mail-Server[0].id
}

resource "aws_security_group_rule" "PPUD-Mail-Server-Egress" {
  description       = "Rule to allow port 443 traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-Mail-Server[0].id
}

resource "aws_security_group_rule" "PPUD-Mail-Server-Egress-1" {
  description       = "Rule to allow port 25 traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 25
  to_port           = 25
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-Mail-Server[0].id
}

resource "aws_security_group_rule" "PPUD-Mail-Server-Egress-2" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-Mail-Server[0].id
}

resource "aws_security_group" "PPUD-Mail-Server-2" {
  count       = local.is-production == true ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "PPUD-Relay-Server"
  description = "PPUD-Relay-Server"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "PPUD-Mail-Server-2-Ingress" {
  description       = "Rule to allow port 25 traffic inbound"
  count             = local.is-production == true ? 1 : 0
  type              = "ingress"
  from_port         = 25
  to_port           = 25
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-Mail-Server-2[0].id
}

resource "aws_security_group_rule" "PPUD-Mail-Server-2-Egress" {
  description       = "Rule to allow port 443 traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-Mail-Server-2[0].id
}

resource "aws_security_group_rule" "PPUD-Mail-Server-2-Egress-1" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-Mail-Server-2[0].id
}

resource "aws_security_group_rule" "PPUD-Mail-Server-2-Egress-2" {
  description       = "Rule to allow port 25 traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 25
  to_port           = 25
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-Mail-Server-2[0].id
}

resource "aws_security_group" "docker-build-server" {
  count       = local.is-production == true ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "docker-build-server"
  description = "docker-build-server"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }

  ingress = []
}

resource "aws_security_group_rule" "docker-build-server-Egress" {
  description       = "Rule to allow port 443 traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.docker-build-server[0].id
}

resource "aws_security_group_rule" "docker-build-server-Egress-1" {
  description       = "Rule to allow all traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.docker-build-server[0].id
}

resource "aws_security_group_rule" "docker-build-server-Egress-2" {
  description       = "Rule to allow port 80 traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.docker-build-server[0].id
}
