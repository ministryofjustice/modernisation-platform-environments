resource "aws_security_group" "PPUD-WEB-Portal" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "PPUD-WEB-Portal"
  description = "PPUD-WEB-Portal for Dev and UAT"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "PPUD-WEB-Portal-ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.PPUD-ALB.id
  security_group_id        = aws_security_group.PPUD-WEB-Portal.id
}

resource "aws_security_group_rule" "PPUD-WEB-Portal-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-WEB-Portal.id
}

resource "aws_security_group_rule" "PPUD-WEB-Portal-egress-1" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-WEB-Portal.id
}

resource "aws_security_group" "WAM-Portal" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "WAM-Portal"
  description = "WAM-Portal for Dev and UAT"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "WAM-Portal-ingress" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"
  # source_security_group_id = aws_security_group.WAM-ALB.id
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-Portal.id
}

resource "aws_security_group_rule" "WAM-Portal-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-Portal.id
}

resource "aws_security_group_rule" "WAM-Portal-egress-1" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WAM-Portal.id
}

resource "aws_security_group" "WAM-Data-Access-Server" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "WAM-Data-Access-Server"
  description = "WAM-Data-Access-Server for Dev and UAT"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "WAM-Data-Access-Server-ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WAM-Data-Access-Server.id
}

resource "aws_security_group_rule" "WAM-Data-Access-Server-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-Data-Access-Server.id
}

resource "aws_security_group_rule" "WAM-Data-Access-Server-Egress-1" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
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
  count                    = local.is-development == true ? 1 : 0
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Dev-Box-VW106[0].id
  security_group_id        = aws_security_group.SCR-Team-Foundation-Server[0].id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress-1" {
  count                    = local.is-development == true ? 1 : 0
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Dev-Box-VW107[0].id
  security_group_id        = aws_security_group.SCR-Team-Foundation-Server[0].id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress-2" {
  count       = local.is-development == true ? 1 : 0
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Dev-Box-VW108[0].id
  security_group_id        = aws_security_group.SCR-Team-Foundation-Server[0].id

}
resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress-3" {
  count                    = local.is-development == true ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Dev-Box-VW106[0].id
  security_group_id        = aws_security_group.SCR-Team-Foundation-Server[0].id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress-4" {
  count                    = local.is-development == true ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Dev-Box-VW107[0].id
  security_group_id        = aws_security_group.SCR-Team-Foundation-Server[0].id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Ingress-5" {
  count                    = local.is-development == true ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.Dev-Box-VW108[0].id
  security_group_id        = aws_security_group.SCR-Team-Foundation-Server[0].id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Egress" {
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.SCR-Team-Foundation-Server[0].id
}

resource "aws_security_group_rule" "SCR-Team-Foundation-Server-Egress-1" {
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
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
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Dev-Box-VW106[0].id
}

resource "aws_security_group_rule" "Dev-Box-VW106-Egress-1" {
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
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
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Dev-Box-VW107[0].id
}

resource "aws_security_group_rule" "Dev-Box-VW107-Egress-1" {
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
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
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Dev-Box-VW108[0].id
}

resource "aws_security_group_rule" "Dev-Box-VW108-Egress-1" {
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Dev-Box-VW108[0].id
}

resource "aws_security_group" "Primary-DOC-Server" {
  count       = local.is-preproduction == false ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "Primary-DOC-Server"
  description = "Primary-DOC-Server for development and production"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "Primary-DOC-Server-Ingress" {
  count             = local.is-preproduction == false ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Primary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Primary-DOC-Server-Ingress-1" {
  count             = local.is-preproduction == false ? 1 : 0
  type              = "ingress"
  from_port         = 445
  to_port           = 445
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Primary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Primary-DOC-Server-Egress" {
  count             = local.is-preproduction == false ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Primary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Primary-DOC-Server-Egress-1" {
  count             = local.is-preproduction == false ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Primary-DOC-Server[0].id
}

resource "aws_security_group" "Secondary-DOC-Server" {
  count       = local.is-preproduction == false ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "Secondary-DOC-Server"
  description = "Secondary-DOC-Server for development and production"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "Secondary-DOC-Server-Ingress" {
  count             = local.is-preproduction == false ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Secondary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Secondary-DOC-Server-Ingress-2" {
  count             = local.is-preproduction == false ? 1 : 0
  type              = "ingress"
  from_port         = 445
  to_port           = 445
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Secondary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Secondary-DOC-Server-Egress" {
  count             = local.is-preproduction == false ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Secondary-DOC-Server[0].id
}

resource "aws_security_group_rule" "Secondary-DOC-Server-Egress-1" {
  count             = local.is-preproduction == false ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
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
  count             = local.is-development == true ? 1 : 0
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-Database-Server[0].id
}

resource "aws_security_group_rule" "PPUD-Database-Server-Egress" {
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-Database-Server[0].id
}

resource "aws_security_group_rule" "PPUD-Database-Server-Egress-1" {
  count             = local.is-development == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-Database-Server[0].id
}


resource "aws_security_group" "PPUD-DEV-AD" {
  vpc_id      = data.aws_vpc.shared.id
  name        = "PPUD-DEV-AD"
  description = "PPUD-AWS-Directory-Server"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "PPUD-DEV-AD-Ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-DEV-AD.id
}

resource "aws_security_group_rule" "PPUD-DEV-AD-Egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.PPUD-DEV-AD.id
}

resource "aws_security_group_rule" "PPUD-DEV-AD-Egress-1" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.PPUD-DEV-AD.id
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
  description = "WAM-ALB"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "WAM-ALB-Ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.WAM-ALB.id
}

resource "aws_security_group_rule" "WAM-ALB-Egress" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.WAM-ALB.id
}
resource "aws_security_group_rule" "WAM-ALB-Egress-1" {
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
  description = "Bridge-Server for UAT and production"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "UAT-Bridge-Server-Ingress" {
  count             = local.is-development == false ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.Bridge-Server[0].id
}

resource "aws_security_group_rule" "UAT-Bridge-Server-Egress" {
  count             = local.is-development == false ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.Bridge-Server[0].id
}
resource "aws_security_group_rule" "UAT-Bridge-Server-Egress-1" {
  count             = local.is-development == false ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
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
  count             = local.is-preproduction == true ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.UAT-Document-Service[0].id
}

resource "aws_security_group_rule" "UAT-Document-Service-Ingress-1" {
  count             = local.is-preproduction == true ? 1 : 0
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.UAT-Document-Service[0].id
}

resource "aws_security_group_rule" "UAT-Document-Service-Egress" {
  count             = local.is-preproduction == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.UAT-Document-Service[0].id
}

resource "aws_security_group_rule" "UAT-Document-Service-Egress-1" {
  count             = local.is-preproduction == true ? 1 : 0
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.UAT-Document-Service[0].id
}