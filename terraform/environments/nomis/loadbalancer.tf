data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
  tags = {
    Name = "${local.vpc_name}-${local.environment}-${local.subnet_set}-private-${local.region}*"
  }
}

resource "aws_security_group" "internal_elb" {

  name        = "internal-lb-${local.application_name}"
  description = "Allow inbound traffic to internal load balancer"
  vpc_id      = local.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "internal-loadbalancer-sg"
    },
  )
}

resource "aws_lb" "internal" {
  #checkov:skip=CKV_AWS_91:skip "Ensure the ELBv2 (Application/Network) has access logging enabled". Logging can be considered when the MP load balancer module is available
  name                       = "lb-internal-${local.application_name}"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.internal_elb.id]
  subnets                    = data.aws_subnets.private.ids
  enable_deletion_protection = false
  drop_invalid_header_fields = true

  tags = merge(
    local.tags,
    {
      Name = "internal-loadbalancer"
    },
  )
}
