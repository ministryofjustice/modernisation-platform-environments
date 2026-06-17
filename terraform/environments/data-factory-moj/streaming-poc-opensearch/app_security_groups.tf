resource "aws_security_group" "opensearch" {
  count       = contains(["development"], local.environment) ? 1 : 0
  name        = "${local.cluster_name}-sg"
  description = "OpenSearch domain access"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.shared.cidr_block] # this will need narrowing and subject to change
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
  }

  tags = merge(local.extended_tags, {
    name        = "{local.cluster_name}-sg",
    description = "Security group for opensearch cluster"
  })
}
