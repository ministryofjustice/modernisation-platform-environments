# Redshift VPC security group for bastion access
resource "aws_security_group" "wepi_sg_allow_redshift" {
  # checkov:skip=CKV2_AWS_5: Configured in Redshift cluster, Checkov not detecting reference.
  name        = "wepi_allow_redshift"
  description = "Redshift Cluster SG"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { "Name" = "sg-wepi_redshift_cluster" }
  )
}

resource "aws_security_group_rule" "tcp_5439_ingress_vpc" {
  cidr_blocks       = [data.aws_vpc.shared.cidr_block]
  from_port         = 5439
  protocol          = "TCP"
  security_group_id = aws_security_group.wepi_sg_allow_redshift.id
  to_port           = 5439
  type              = "ingress"
}

resource "aws_security_group_rule" "tcp_5439_ingress_bastion" {
  from_port                = 5439
  protocol                 = "TCP"
  security_group_id        = aws_security_group.wepi_sg_allow_redshift.id
  source_security_group_id = module.wepi_bastion.bastion_security_group
  to_port                  = 5439
  type                     = "ingress"
}

resource "aws_security_group_rule" "tcp_443_egress_s3" {
  from_port         = 443
  prefix_list_ids   = [data.aws_vpc_endpoint.s3.prefix_list_id]
  protocol          = "TCP"
  security_group_id = aws_security_group.wepi_sg_allow_redshift.id
  to_port           = 443
  type              = "egress"
}