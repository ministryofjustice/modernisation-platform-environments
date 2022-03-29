resource "aws_security_group" "alb" {
  name        = "terraform_alb_security_group"
  description = "Terraform load balancer security group"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port   = 443
    to_port     = 443
    description = "Allow SSL Traffic"
    protocol    = "tcp"
    #tfsec:ignore:aws-vpc-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    description = "Allow Non SSL Traffic"
    protocol    = "tcp"
    #tfsec:ignore:aws-vpc-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    description = "Allow Egress Traffic"
    protocol    = "-1"
    #tfsec:ignore:aws-vpc-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-alb-security-group"
  }
}

##############################################################
# S3 Bucket Creation
# For root account id, refer below link
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
##############################################################

resource "aws_lb" "citrix_alb" {

  #checkov:skip=CKV2_AWS_28:

  name        = format("%s-alb", var.name)
  name_prefix = var.name_prefix

  load_balancer_type = var.load_balancer_type
  #tfsec:ignore:aws-elb-alb-not-public
  internal        = var.internal
  security_groups = [aws_security_group.alb.id]
  subnets         = [data.aws_subnet.public_az_a.id, data.aws_subnet.public_az_b.id]

  enable_deletion_protection       = var.enable_deletion_protection
  idle_timeout                     = var.idle_timeout
  enable_http2                     = var.enable_http2
  desync_mitigation_mode           = var.desync_mitigation_mode
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  enable_waf_fail_open             = var.enable_waf_fail_open
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  ip_address_type                  = var.ip_address_type

  tags = merge(
    var.tags,
    var.lb_tags,
    {
      Name = var.name != null ? var.name : var.name_prefix
    },
  )

  access_logs {
    bucket  = aws_s3_bucket.this.id
    prefix  = "access-logs-alb"
    enabled = "true"
  }

  depends_on = [aws_s3_bucket.this]

  timeouts {
    create = var.load_balancer_create_timeout
    update = var.load_balancer_update_timeout
    delete = var.load_balancer_delete_timeout
  }
}
