# Oracle HTTP Server SSL Listen Port 4443
# Oracle WebLogic Server Node Manager Port 5556
# Oracle WebLogic Server Listen Port for Administration Server 7001
# Oracle WebLogic Server SSL Listen Port for Administration Server 7002
# Oracle WebLogic Server Listen Port for Managed Server 8001

resource "aws_security_group" "oem_wl_security_group_1" {
  count    = local.is-production ? 0 : 1
  name_prefix = "${local.application_name}-wl-server-sg-1-"
  description = "Access to the Weblogic server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(tomap(
    { "Name" = "${local.application_name}-wl-server-sg-1" }
  ), local.tags)

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_lz_workspaces]
  }

  ingress {
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [data.aws_vpc.shared.cidr_block, local.cidr_lz_workspaces]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 4443
    to_port         = 4443
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 5556
    to_port         = 5556
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 7001
    to_port         = 7001
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 7002
    to_port         = 7002
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  ingress {
    protocol        = "tcp"
    from_port       = 8001
    to_port         = 8001
    cidr_blocks     = [data.aws_vpc.shared.cidr_block]
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }
}
