######################################################
# Security Groups for EC2 instances and load balancers
######################################################


resource "aws_security_group" "PPUD-Mail-Server" {
  # checkov:skip=CKV2_AWS_5: "Security group will be updated or removed in the near term, so this finding can be ignored for now."
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
  # checkov:skip=CKV2_AWS_5: "Security group will be updated or removed in the near term, so this finding can be ignored for now."
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
  # checkov:skip=CKV2_AWS_5: "Security group will be updated or removed in the near term, so this finding can be ignored for now."
  count       = local.is-production == true ? 1 : 0
  vpc_id      = data.aws_vpc.shared.id
  name        = "docker-build-server"
  description = "docker-build-server"

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "docker-build-server-Ingress" {
  description       = "Rule to allow port 25 traffic inbound"
  count             = local.is-production == true ? 1 : 0
  type              = "ingress"
  from_port         = 25
  to_port           = 25
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  security_group_id = aws_security_group.docker-build-server[0].id
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

resource "aws_security_group_rule" "docker-build-server-Egress-3" {
  description       = "Rule to allow port 25 traffic outbound"
  count             = local.is-production == true ? 1 : 0
  type              = "egress"
  from_port         = 25
  to_port           = 25
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.docker-build-server[0].id
}

###########################################################################################################################
# General optimisation and re-code of security_group.tf is below
# New groups to be created with stardised naming conventions, left empty at creation & 
# EC2 and LBs to be slowly migrated over before removal of old groups
# Consolidation of 1134 lines of code into 405 lines of code
###########################################################################################################################

######################################################
# Security Groups - Dynamic (all environments)
######################################################

locals {

  # -------------------------------------------------------------------
  # All-environment security groups (always created)
  # -------------------------------------------------------------------
  sg_all = {
    "PPUD-Web-Portal-Server-Security-Group" = {
      name        = "PPUD-Web-Portal-Server-Security-Group"
      description = "PPUD Web Portal server security group for all environments"
      ingress = [
        # Note there are additional ingress rules for port 443 from the old and new ALB security groups in separate statements
        { port = 80, cidr = "vpc", description = "Allow port 80 inbound" },
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
    "WAM-Data-Access-Server-Security-Group" = {
      name        = "WAM-Data-Access-Server-Security-Group"
      description = "WAM Data Access server security group for for all environments"
      ingress = [
        { port = 80, cidr = "vpc", description = "Allow port 80 inbound" },
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
    "Document-Service-Server-Security-Group" = {
      name        = "Document-Service-Server-Security-Group"
      description = "Document Service server security group for all environments"
      ingress = [
        { port = 80, cidr = "vpc", description = "Allow port 80 inbound" },
        { port = 445, cidr = "vpc", description = "Allow port 445 inbound" },
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
    "Tooling-Service-Server-Security-Group" = {
      name        = "Tooling-Service-Server-Security-Group"
      description = "Tooling Service server security group for all environments"
      ingress = [
        { port = 80, cidr = "vpc", description = "Allow port 80 inbound" },
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
    "WAM-Web-Portal-Server-Security-Group" = {
      name        = "WAM-Web-Portal-Server-Security-Group"
      description = "WAM Web Portal server security group for all environments"
      ingress = [
        # Note there are additional ingress rules for port 443 from the old and new ALB security groups in separate statements
        { port = 80, cidr = "vpc", description = "Allow port 80 inbound" },
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
    "Certificate-Authority-Server-Security-Group" = {
      name        = "Certificate-Authority-Server-Security-Group"
      description = "Certificate Authority server security group for all environments"
      ingress = [
        { port = 80, cidr = "vpc", description = "Allow port 80 inbound" },
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
    "PPUD-ALB-Load-Balancer-Security-Group" = {
      name        = "PPUD-ALB-Load-Balancer-Security-Group"
      description = "PPUD ALB load balancer security group for all environments"
      ingress = [
        { port = 443, cidr = "0.0.0.0/0", description = "Allow port 443 inbound" },
      ]
      egress = [
        { port = 443, to_port = 443, protocol = "tcp", cidr = "vpc", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "vpc", description = "Allow port 80 outbound" },
      ]
    }
    "WAM-ALB-Load-Balancer-Security-Group" = {
      name        = "WAM-ALB-Load-Balancer-Security-Group"
      description = "WAM ALB load balancer security group for all environments"
      ingress = [
        { port = 443, cidr = "0.0.0.0/0", description = "Allow port 443 inbound" },
      ]
      egress = [
        { port = 80, to_port = 80, protocol = "tcp", cidr = "vpc", description = "Allow port 80 outbound" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "vpc", description = "Allow port 443 outbound" },
      ]
    }
  }

  # -------------------------------------------------------------------
  # Environment-conditional security groups
  # -------------------------------------------------------------------
  sg_development = local.is-development ? {
    "Team-Foundation-Server-Security-Group" = {
      name        = "Team-Foundation-Server-Security-Group"
      description = "Team Foundation Server security group for the development environment"
      ingress = [
        { port = 80, cidr = "vpc", description = "Allow port 80 inbound" },
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
        { port = 443, cidr = "vpc", description = "Allow port 443 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
    "Dev-Ops-Server-Security-Group" = {
      name        = "Dev-Ops-Server-Security-Group"
      description = "Dev Ops Server security group for the development environment"
      ingress = [
        { port = 80, cidr = "vpc", description = "Allow port 80 inbound" },
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
        { port = 443, cidr = "vpc", description = "Allow port 443 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
    "Development-Servers-Standard-Security-Group" = {
      name        = "Development-Servers-Standard-Security-Group"
      description = "Development servers standard security group for the development environment"
      ingress = [
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
        { port = 80, cidr = "vpc", description = "Allow port 80 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
    "PPUD-Database-Server-Security-Group" = {
      name        = "PPUD-Database-Server-Security-Group"
      description = "PPUD Database server security group for the development environment"
      ingress = [
        { port = 1433, cidr = "vpc", description = "Allow port 1433 inbound" },
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
  } : {}

  sg_not_development = !local.is-development ? {
    "WAM-Bridge-Server-Security-Group" = {
      name        = "WAM-Bridge-Server-Security-Group"
      description = "WAM Bridge server security group for UAT & PROD environments"
      ingress = [
        { port = 80, cidr = "vpc", description = "Allow port 80 inbound" },
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
  } : {}

  sg_preproduction = local.is-preproduction ? {
    "Database-and-Document-Service-Security-Group" = {
      name        = "Database-and-Document-Service-Security-Group"
      description = "Document Service security group for the UAT environment"
      ingress = [
        { port = 80, cidr = "vpc", description = "Allow port 80 inbound" },
        { port = 1433, cidr = "vpc", description = "Allow port 1433 inbound" },
        { port = 445, cidr = "vpc", description = "Allow port 445 inbound" }, #Temporarily allowed for development/testing purposes
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
  } : {}

  sg_production = local.is-production ? {
    "PPUD-PROD-Database-Security-Group" = {
      name        = "PPUD-PROD-Database-Security-Group"
      description = "PPUD PROD Database security group for the production environment"
      ingress = [
        { port = 3180, cidr = "vpc", description = "Allow port 3180 inbound" },
        { port = 3389, cidr = "vpc", description = "Allow port 3389 inbound" },
      ]
      egress = [
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
      ]
    }
    "Internal-Mail-Relay-Security-Group" = {
      name        = "Internal-Mail-Relay-Security-Group"
      description = "Internal Mail Relay security group for the production environment"
      ingress = [
        { port = 25, cidr = "vpc", description = "Allow port 25 inbound" },
      ]
      egress = [
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 25, to_port = 25, protocol = "tcp", cidr = "vpc", description = "Allow port 25 outbound" },
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
      ]
    }
    "External-Mail-Relay-Security-Group" = {
      name        = "External-Mail-Relay-Security-Group"
      description = "External Mail Relay security group for the production environment"
      ingress = [
        { port = 25, cidr = "vpc", description = "Allow port 25 inbound" },
      ]
      egress = [
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 25, to_port = 25, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 25 outbound" },
      ]
    }
    "Docker-Build-Server-Security-Group" = {
      name        = "Docker-Build-Server-Security-Group"
      description = "Docker Build Server security group for the production environment"
      ingress = [
        { port = 25, cidr = "vpc", description = "Allow port 25 inbound" },
      ]
      egress = [
        { port = 443, to_port = 443, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 443 outbound" },
        { port = 0, to_port = 0, protocol = "-1", cidr = "vpc", description = "Allow all outbound (VPC)" },
        { port = 80, to_port = 80, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 80 outbound" },
        { port = 25, to_port = 25, protocol = "tcp", cidr = "0.0.0.0/0", description = "Allow port 25 outbound" },
      ]
    }
  } : {}

  # -------------------------------------------------------------------
  # Merged maps used by conditional resources
  # -------------------------------------------------------------------
  sg_conditional = merge(
    local.sg_development,
    local.sg_not_development,
    local.sg_preproduction,
    local.sg_production,
  )

  # Resolve "vpc" shorthand to the actual VPC CIDR at flatten time
  _vpc_cidr = data.aws_vpc.shared.cidr_block

  # Flatten ingress rules for all-environment SGs
  sg_all_ingress = merge([
    for sg_key, sg in local.sg_all : {
      for rule in sg.ingress :
      "${sg_key}-${rule.port}" => merge(rule, {
        sg_key = sg_key
        cidr   = rule.cidr == "vpc" ? local._vpc_cidr : rule.cidr
      })
    }
  ]...)

  # Flatten egress rules for all-environment SGs
  sg_all_egress = merge([
    for sg_key, sg in local.sg_all : {
      for idx, rule in sg.egress :
      "${sg_key}-${rule.port}-${idx}" => merge(rule, {
        sg_key = sg_key
        cidr   = rule.cidr == "vpc" ? local._vpc_cidr : rule.cidr
      })
    }
  ]...)

  # Flatten ingress rules for conditional SGs
  sg_conditional_ingress = merge([
    for sg_key, sg in local.sg_conditional : {
      for rule in sg.ingress :
      "${sg_key}-${rule.port}" => merge(rule, {
        sg_key = sg_key
        cidr   = rule.cidr == "vpc" ? local._vpc_cidr : rule.cidr
      })
    }
  ]...)

  # Flatten egress rules for conditional SGs
  sg_conditional_egress = merge([
    for sg_key, sg in local.sg_conditional : {
      for idx, rule in sg.egress :
      "${sg_key}-${rule.port}-${idx}" => merge(rule, {
        sg_key = sg_key
        cidr   = rule.cidr == "vpc" ? local._vpc_cidr : rule.cidr
      })
    }
  ]...)
}

# -------------------------------------------------------------------
# All-environment security groups
# -------------------------------------------------------------------
resource "aws_security_group" "all" {
  # checkov:skip=CKV2_AWS_5: "Security group will be updated or removed in the near term, so this finding can be ignored for now."
  for_each    = local.sg_all
  vpc_id      = data.aws_vpc.shared.id
  name        = each.value.name
  description = each.value.description

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "all_ingress" {
  for_each          = local.sg_all_ingress
  description       = each.value.description
  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  cidr_blocks       = [each.value.cidr]
  security_group_id = aws_security_group.all[each.value.sg_key].id
}

resource "aws_security_group_rule" "all_egress" {
  for_each          = local.sg_all_egress
  description       = each.value.description
  type              = "egress"
  from_port         = each.value.port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = [each.value.cidr]
  security_group_id = aws_security_group.all[each.value.sg_key].id
}

# Source-SG ingress rules (cannot use CIDR, kept as standalone)
resource "aws_security_group_rule" "ppud_web_portal_alb_ingress" {
  description              = "Allow port 443 inbound from PPUD ALB load balancer security group"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.all["PPUD-ALB-Load-Balancer-Security-Group"].id
  security_group_id        = aws_security_group.all["PPUD-Web-Portal-Server-Security-Group"].id
}

resource "aws_security_group_rule" "wam_portal_alb_ingress" {
  description              = "Allow port 443 inbound from WAM ALB load balancer security group"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.all["WAM-ALB-Load-Balancer-Security-Group"].id
  security_group_id        = aws_security_group.all["WAM-Web-Portal-Server-Security-Group"].id
}

# -------------------------------------------------------------------
# Conditional security groups
# -------------------------------------------------------------------
resource "aws_security_group" "conditional" {
  # checkov:skip=CKV2_AWS_5: "Security group will be updated or removed in the near term, so this finding can be ignored for now."
  for_each    = local.sg_conditional
  vpc_id      = data.aws_vpc.shared.id
  name        = each.value.name
  description = each.value.description

  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}"
  }
}

resource "aws_security_group_rule" "conditional_ingress" {
  for_each          = local.sg_conditional_ingress
  description       = each.value.description
  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  cidr_blocks       = [each.value.cidr]
  security_group_id = aws_security_group.conditional[each.value.sg_key].id
}

resource "aws_security_group_rule" "conditional_egress" {
  for_each          = local.sg_conditional_egress
  description       = each.value.description
  type              = "egress"
  from_port         = each.value.port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  cidr_blocks       = [each.value.cidr]
  security_group_id = aws_security_group.conditional[each.value.sg_key].id
}
