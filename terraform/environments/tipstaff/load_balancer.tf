
resource "aws_lb" "tipstaff-dev-lb" {
  name               = "tipstaff-dev-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups            = [aws_security_group.tipstaff-dev-lb-sc.id]
  # security_groups            = [resource.aws_security_group.postgresql_db_sc.id]
  subnets                    = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
  enable_deletion_protection = false
}

resource "aws_security_group" "tipstaff-dev-lb-sc" {
  name        = "load balancer security group"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id
  ingress {
    description = "Allow all traffic through HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "Allows access to load balancer"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${local.application_data.accounts[local.environment].subdomain_name}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.tipstaff-dev-lb.dns_name
    zone_id                = aws_lb.tipstaff-dev-lb.zone_id
    evaluate_target_health = true
  }
}


// Look into target groups?? Maybe they're needed?