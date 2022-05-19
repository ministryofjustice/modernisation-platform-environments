# Build loadbalancer security group
resource "aws_security_group" "example-load-balancer-sg" {
  name        = "example-lb-sg"
  description = "controls access to load balancer"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-", local.application_name, local.environment)) }
  )
  # Need ingress and egress in here
  }

# Build loadbalancer

resource "aws_lb" "example" {
  name                       = "${local.application_name}-loadbalancer"
  load_balancer_type         = "application"
  subnets                    = data.aws_subnets.shared-public.ids
  # enable_deletion_protection = true
  # allow 60*4 seconds before 504 gateway timeout for long-running DB operations
  idle_timeout = 240

  security_groups = [aws_security_group.example-load-balancer-sg.id]

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-loadbalancer"
    }
  )

   depends_on = [aws_security_group.example-ec2-sg]
}