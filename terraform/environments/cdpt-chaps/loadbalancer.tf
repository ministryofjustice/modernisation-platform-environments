resource "aws_security_group" "chaps_lb_sc" {
  name        = "load balancer security group"
  description = "control access to the load balancer"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    description = "allow access on HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["188.214.15.75/32", "192.168.5.101/32", "81.134.202.29/32", "79.152.189.104/32", "179.50.12.212/32", "188.172.252.34/32", "194.33.192.0/25", "194.33.193.0/25", "194.33.196.0/25", "194.33.197.0/25", "195.59.75.0/24", "201.33.21.5/32", "213.121.161.112/28", "52.67.148.55/32", "54.94.206.111/32", "178.248.34.42/32", "178.248.34.43/32", "178.248.34.44/32", "178.248.34.45/32", "178.248.34.46/32", "178.248.34.47/32", "89.32.121.144/32", "185.191.249.100/32", "2.138.20.8/32", "18.169.147.172/32", "35.176.93.186/32", "18.130.148.126/32", "35.176.148.126/32", "51.149.250.0/24", "51.149.249.0/29", "194.33.249.0/29", "51.149.249.32/29", "194.33.248.0/29", "20.49.214.199/32", "20.49.214.228/32", "20.26.11.71/32", "20.26.11.108/32", "128.77.75.128/26"]
  }

  egress {
    description = "Open all outbound ports"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "chaps_lb" {
  name               = "chaps-load-balancer"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.chaps_lb_sc.id]
  subnets            = data.aws_subnets.shared-public.ids
  idle_timeout       = 60

  access_logs {
    bucket  = aws_s3_bucket.chaps_lb_logs.id
    prefix  = "chaps_lb"
    enabled = true
  }
}

resource "aws_lb_target_group" "chaps_target_group" {
  name                 = "chaps-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "ip"
  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
  }

  health_check {
    healthy_threshold   = "2"
    interval            = "30"
    unhealthy_threshold = "5"
    matcher             = "200-499"
    timeout             = "10"
  }

}

resource "aws_lb_listener" "https_listener" {
  #checkov:skip=CKV_AWS_103
  depends_on = [aws_acm_certificate_validation.external]

  load_balancer_arn = aws_lb.chaps_lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    target_group_arn = aws_lb_target_group.chaps_target_group.id
    type             = "forward"
  }
}

resource "aws_s3_bucket" "chaps_lb_logs" {
  bucket = "chaps-lb-logs-bucket"
}

resource "aws_s3_bucket_versioning" "chaps_lb_logs_versioning" {
  bucket = aws_s3_bucket.chaps_lb_logs.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "chaps_lb_logs_lifecycle" {
  bucket = aws_s3_bucket.chaps_lb_logs.id

  rule {
    id = "log"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_iam_role" "lb_logging_role" {
  name = "lb-logging-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "elasticloadbalancing.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lb_logging_policy" {
  name = "lb-logging-policy"
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = "${aws_s3_bucket.chaps_lb_logs.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lb_logging_policy_attachment" {
  role       = aws_iam_role.lb_logging_role.name
  policy_arn = aws_iam_policy.elb_logging_policy.arn
}
 
resource "aws_s3_bucket_policy" "chaps_lb_logs_bucket_policy" {
  bucket = aws_s3_bucket.chaps_lb_logs.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = "${aws_s3_bucket.chaps_lb_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
