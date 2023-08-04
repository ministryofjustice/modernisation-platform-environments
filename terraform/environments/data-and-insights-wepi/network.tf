# Redshift VPC security group for bastion access
resource "aws_security_group" "wepi_sg_allow_redshift" {
  # checkov:skip=CKV2_AWS_5: Configured in Redshfit cluster, Checkov not detecting reference.
  name        = "wepi_allow_redshift"
  description = "Allow Redshift inbound traffic from bastion"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "Redshift ingress from bastion"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [
      module.wepi_bastion.bastion_security_group
    ]
  }

  egress {
    description = "Redshift egress to S3 endpoint"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = [
      data.aws_vpc_endpoint.s3.prefix_list_id
    ]
  }

  tags = local.tags
}
