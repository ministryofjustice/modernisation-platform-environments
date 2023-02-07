resource "aws_security_group" "PPUD-WEB-Portal" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw101"
  description = "Allow access from ALB on port 443"
  /*
   tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
*/
}

resource "aws_security_group_rule" "PPUD-WEB-Portal-Ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-WEB-Portal.id
}

resource "aws_security_group_rule" "PPUD-WEB-Portal-Egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-WEB-Portal.id
}

resource "aws_security_group" "WAM-PORTAL" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw105"
  description = "Allow access from ALB on port 443"
  /*
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
*/
}

resource "aws_security_group_rule" "WAM-Portal-Ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WAM-PORTAL.id
}

resource "aws_security_group_rule" "WAM-Portal-Egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-PORTAL.id
}

resource "aws_security_group" "WAM-Data-Access-Server" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw104"
  description = "Allow access on port 80"
  /*
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
*/
}

resource "aws_security_group_rule" "WAM-Data-Access-Server-Ingress" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.WAM-PORTAL.id
  security_group_id        = aws_security_group.WAM-Data-Access-Server.id
}

resource "aws_security_group_rule" "WAM-Data-Access-Server-Egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-Data-Access-Server.id
}

resource "aws_security_group" "SCR-Team-Foundation-Server" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw109"
  description = "Allow access on port 80 and 8080"
  /*
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
*/
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Dev-Box-VM106.id
  security_group_id        = aws_security_group.SCR-Team-Foundation-Server.id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress-1" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Dev-Box-VM107.id
  security_group_id        = aws_security_group.SCR-Team-Foundation-Server.id

}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress-2" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Dev-Box-VM108.id
  security_group_id        = aws_security_group.SCR-Team-Foundation-Server.id

}
resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress-3" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Dev-Box-VM106.id
  security_group_id        = aws_security_group.SCR-Team-Foundation-Server.id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress-4" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Dev-Box-VM107.id
  security_group_id        = aws_security_group.SCR-Team-Foundation-Server.id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress-5" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Dev-Box-VM108.id
  security_group_id        = aws_security_group.SCR-Team-Foundation-Server.id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.SCR-Team-Foundation-Server.id
}

resource "aws_security_group" "Dev-Box-VM106" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw106"
  description = "Only outbound ports allowed"
  /*
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
*/
}

resource "aws_security_group_rule" "Dev-Box-VM106-Ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Dev-Box-VM106.id
}
/*
resource "aws_security_group_rule" "Dev-Box-VM106-Egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["10.150.0.0/16"]
  security_group_id = aws_security_group.Dev-Box-VM106.id
}
*/
resource "aws_security_group_rule" "Dev-Box-VM106-Egress-1" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Dev-Box-VM106.id
}

resource "aws_security_group" "Dev-Box-VM107" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw107"
  description = "Only outbound ports allowed"
  /*
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
*/

  ingress = []
}

resource "aws_security_group_rule" "Dev-Box-VM107-Egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Dev-Box-VM107.id
}


resource "aws_security_group" "Dev-Box-VM108" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw108"
  description = "Only outbound ports allowed"
  /*
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
*/

}

resource "aws_security_group_rule" "Dev-Box-VM108-Ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Dev-Box-VM108.id
}

resource "aws_security_group_rule" "Dev-Box-VM108-Egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Dev-Box-VM108.id
}

resource "aws_security_group" "PPUD-Database-Server" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "s609693lo6vw100"
  description = "Allow port 1433"
  /*
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
*/
}

resource "aws_security_group_rule" "PPUD-Database-Server-Ingress" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-Database-Server.id
}

resource "aws_security_group_rule" "PPUD-Database-Server-Egress" {
  type              = "egress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-Database-Server.id
}

resource "aws_security_group" "PPUD-ALB" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "PPUD-ALB"
  description = "Allow port https"
  /*
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
*/
}

resource "aws_security_group_rule" "PPUD-ALB-Ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-ALB.id
}

resource "aws_security_group_rule" "PPUD-ALB-Egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-ALB.id
}

resource "aws_security_group" "WAM-ALB" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "WAM-ALB"
  description = "Allow port https"
  /*
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
*/
}

resource "aws_security_group_rule" "WAM-ALB-Ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WAM-ALB.id
}

resource "aws_security_group_rule" "WAM-ALB-Egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WAM-ALB.id
}