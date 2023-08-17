### Instances

resource "aws_instance" "ec2_instance_dummy_app" {
  ami                         = "ami-0f3d9639a5674d559"
  associate_public_ip_address = false
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name
  instance_type               = "t2.micro"
  key_name                    = local.application_data.accounts[local.environment].key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids      = [aws_security_group.sg_dummy_app.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    iops        = 3000
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    tags = merge(
      { Name = "device-root-dummy-app" },
      { host-attachement = lower(format("ec2-%s-%s-dummy-app", local.application_name, local.environment)) }
    )
  }

  tags = merge(
    { Name = lower(format("ec2-%s-%s-dummy-app", local.application_name, local.environment)) },
    { instance-scheduling = "skip-scheduling" },
    { backup = "false" }
  )
}

resource "aws_instance" "ec2_instance_dummy_db" {
  ami                         = "ami-0f3d9639a5674d559"
  associate_public_ip_address = false
  ebs_optimized               = true
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_ccms_base.name
  instance_type               = "t2.micro"
  key_name                    = local.application_data.accounts[local.environment].key_name
  monitoring                  = true
  subnet_id                   = data.aws_subnet.private_subnets_a.id
  vpc_security_group_ids      = [aws_security_group.sg_dummy_db.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 50
    iops        = 3000
    encrypted   = true
    kms_key_id  = data.aws_kms_key.ebs_shared.key_id
    tags = merge(
      { Name = "device-root-dummy-db" },
      { host-attachement = lower(format("ec2-%s-%s-dummy-db", local.application_name, local.environment)) }
    )
  }

  tags = merge(
    { Name = lower(format("ec2-%s-%s-dummy-db", local.application_name, local.environment)) },
    { instance-scheduling = "skip-scheduling" },
    { backup = "false" }
  )
}

### Load Balancer

resource "aws_lb" "ec2_lb_dummy_alb" {
  name                   = lower(format("alb-%s-%s-dummy", local.application_name, local.environment))
  internal               = false
  load_balancer_type     = "application"
  security_groups        = [aws_security_group.sg_dummy_alb.id]
  subnets                = data.aws_subnets.shared-public.ids
  vpc_id                 = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("alb-%s-%s-dummy", local.application_name, local.environment)) }
  )
}

resource "aws_lb_listener" "ec2_lb_dummy_listener" {
  certificate_arn   = data.aws_acm_certificate.gandi_cert.arn
  load_balancer_arn = aws_lb.ec2_lb_dummy_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_lb_dummy_tg.id
  }
}

resource "aws_lb_target_group" "ec2_lb_dummy_tg" {
  name     = lower(format("tg-%s-%s-dummy", local.application_name, local.environment))
  port     = "443"
  protocol = "HTTPS"
  vpc_id   = data.aws_vpc.shared.id

  health_check {
    port     = "443"
    protocol = "HTTPS"
  }
}

resource "aws_lb_target_group_attachment" "ec2_lb_dummy_tg_attachement" {
  target_group_arn = aws_lb_target_group.ec2_lb_dummy_tg.arn
  target_id        = aws_instance.ec2_instance_dummy_app.id
  port             = "443"
}

### Security Groups:

## SGs attached to resources.

# Internet = anything in fron of the LB.
resource "aws_security_group" "sg_dummy_internet" {
  name        = "sg_dummy_internet"
  description = "SG attached to the Internet."
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-dummy-internet", local.application_name, local.environment)) }
  )
}

# The Load Balancer.
resource "aws_security_group" "sg_dummy_alb" {
  name        = "sg_dummy_alb"
  description = "SG attached to the ALB."
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-dummy-alb", local.application_name, local.environment)) }
  )
}

# The App instance.
resource "aws_security_group" "sg_dummy_app" {
  name        = "sg_dummy_app"
  description = "SG attached to the App instance."
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-dummy-app", local.application_name, local.environment)) }
  )
}

# The DB instance.
resource "aws_security_group" "sg_dummy_db" {
  name        = "sg_dummy_db"
  description = "SG attached to the DB instance."
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-dummy-db", local.application_name, local.environment)) }
  )
}

## SGs "between" the resources - where the traffic control is.

# Internet <-> LB.
resource "aws_security_group" "sg_dummy_internet2alb" {
  name        = "sg_dummy_internet_alb"
  description = "SG for traffic between the ALB and the Internet."
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-dummy-alb-internet", local.application_name, local.environment)) }
  )
}

# LB <-> App.
resource "aws_security_group" "sg_dummy_alb2app" {
  name        = "sg_dummy_alb_app"
  description = "SG for traffic between the ALB and App instance."
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-dummy-alb-app", local.application_name, local.environment)) }
  )
}

# App <-> DB.
resource "aws_security_group" "sg_dummy_app2db" {
  name        = "sg_dummy_app_db"
  description = "SG for traffic between the App and DB instances."
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = lower(format("sg-%s-%s-dummy-app-db", local.application_name, local.environment)) }
  )
}

### Security Groups' rules

## Internet <-> ALB

# Internet <-> Internet_2_ALB
resource "aws_vpc_security_group_egress_rule" "sr_dummy_internet_alb_out" {
  security_group_id            = aws_security_group.sg_dummy_alb.id
  description                  = "ALB -> Internet : 443"
  ip_protocol                  = "TCP"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.sg_dummy_internet.id # source
}

resource "aws_vpc_security_group_ingress_rule" "sr_dummy_internet_alb_in" {
  security_group_id            = aws_security_group.sg_dummy_alb.id
  description                  = "Internet -> ALB : 443"
  ip_protocol                  = "TCP"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.sg_dummy_internet.id # destination
}

## ALB <-> App
# ALB <-> ALB_2_App : 443
resource "aws_vpc_security_group_egress_rule" "sr_dummy_alb2app_alb_out_443" {
  security_group_id            = aws_security_group.sg_dummy_alb.id
  description                  = "ALB_2_App -> ALB : 443"
  ip_protocol                  = "TCP"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.sg_dummy_alb2app.id # source
}

resource "aws_vpc_security_group_ingress_rule" "sr_dummy_alb_alb2app_in_443" {
  security_group_id            = aws_security_group.sg_dummy_alb.id
  description                  = "ALB -> ALB_2_App : 443"
  ip_protocol                  = "TCP"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.sg_dummy_alb2app.id # destination
}

# ALB_2_App <-> App : 443
resource "aws_vpc_security_group_egress_rule" "sr_dummy_alb2app_app_out_443" {
  security_group_id            = aws_security_group.sg_dummy_alb2app.id
  description                  = "ALB_2_App -> App : 443"
  ip_protocol                  = "TCP"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.sg_dummy_app.id # source
}

resource "aws_vpc_security_group_ingress_rule" "sr_dummy_app_alb2app_in_443" {
  security_group_id            = aws_security_group.sg_dummy_alb2app.id
  description                  = "ALB -> ALB_2_App : 443"
  ip_protocol                  = "TCP"
  from_port                    = 443
  to_port                      = 443
  referenced_security_group_id = aws_security_group.sg_dummy_app.id # destination
}

## App <-> DB
# ALB <-> ALB_2_App : 22
resource "aws_vpc_security_group_egress_rule" "sr_dummy_app2db_app_out_443" {
  security_group_id            = aws_security_group.sg_dummy_app.id
  description                  = "ALB_2_App -> App : 22"
  ip_protocol                  = "TCP"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.sg_dummy_app2db.id # source
}

resource "aws_vpc_security_group_ingress_rule" "sr_dummy_app_app2db_in_443" {
  security_group_id            = aws_security_group.sg_dummy_app.id
  description                  = "App -> ALB_2_App : 22"
  ip_protocol                  = "TCP"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.sg_dummy_app2db.id # destination
}

# ALB_2_App <-> App : 22
resource "aws_vpc_security_group_egress_rule" "sr_dummy_app2db_db_out_443" {
  security_group_id            = aws_security_group.sg_dummy_app2db.id
  description                  = "App_2_DB -> DB : 22"
  ip_protocol                  = "TCP"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.sg_dummy_db.id # source
}

resource "aws_vpc_security_group_ingress_rule" "sr_dummy_db_app2db_in_443" {
  security_group_id            = aws_security_group.sg_dummy_app2db.id
  description                  = "DB -> App_2_DB : 22"
  ip_protocol                  = "TCP"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.sg_dummy_db.id # destination
}