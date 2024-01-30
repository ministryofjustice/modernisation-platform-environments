# ============================================
# FSx Integration Security Group
# ============================================
resource "aws_security_group" "fsx_integration" {
  name        = "${var.fsx.common_name}-fsx-integration"
  description = "security group to allow instances access to fsx filesystem"
  vpc_id      = var.common.vpc_id

  tags = merge(
    var.common.tags,
    {
      "Name" = "${var.fsx.common_name}-fsx-integration"
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "fsx_integration_ingress_all_local_sg" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.fsx_integration.id
  self              = true
  description       = "ingress internal security group traffic"
}

resource "aws_security_group_rule" "fsx_integration_egress_all_local_sg" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.fsx_integration.id
  self              = true
  description       = "egress internal security group traffic"
}

resource "aws_security_group_rule" "fsx_integration_sg_ingress_from_fsx_sg" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = aws_security_group.fsx.id
  security_group_id        = aws_security_group.fsx_integration.id
  description              = "ingress ALL traffic from FSx Security Group"
}

resource "aws_security_group_rule" "fsx_integration_sg_egress_to_fsx_sg" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = aws_security_group.fsx.id
  security_group_id        = aws_security_group.fsx_integration.id
  description              = "egress ALL traffic to FSx Security Group"
}

resource "aws_security_group_rule" "fsx_integration_sg_ingress_from_ad_sg" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = var.fsx.active_directory_security_group_id
  security_group_id        = aws_security_group.fsx_integration.id
  description              = "ingress ALL traffic from AD Security Group"
}

resource "aws_security_group_rule" "fsx_integration_sg_egress_to_ad_sg" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = var.fsx.active_directory_security_group_id
  security_group_id        = aws_security_group.fsx_integration.id
  description              = "egress ALL traffic to AD Security Group"
}