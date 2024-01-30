# ============================================
# AD Security Group Rules
# ============================================

resource "aws_security_group_rule" "ad_egress_to_fsx_sg" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = aws_security_group.fsx.id
  security_group_id        = var.fsx.active_directory_security_group_id
  description              = "egress ALL traffic to FSx Security Group"
}

# allow inbound traffic from fsx security group 
resource "aws_security_group_rule" "ad_egress_to_fsx_integration_sg" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  source_security_group_id = aws_security_group.fsx_integration.id
  security_group_id        = var.fsx.active_directory_security_group_id
  description              = "egress ALL traffic to FSx Integration Security Group"
}