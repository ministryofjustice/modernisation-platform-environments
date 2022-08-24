# Redshift VPC security group for bastion access
resource "aws_security_group" "wepi_sg_allow_redshift" {
  # checkov:skip=CKV2_AWS_5: Configured in Redshfit cluster, Checkov not detecting reference.
  name        = "wepi_allow_redshift"
  description = "Allow Redshift inbound traffic from bastion"
  vpc_id      = data.aws_vpc.wepi_vpc.id

  ingress {
    description = "Redshift from bastion"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    security_groups = [
      module.wepi_bastion.bastion_security_group
    ]
  }

  tags = local.tags
}