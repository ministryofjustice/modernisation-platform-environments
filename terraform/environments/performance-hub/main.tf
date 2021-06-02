resource "aws_ecr_repository" "ecr_repo" {
  name                 = local.application_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "shared" {
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}"
  }
}

data "aws_subnet_ids" "shared-data" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data*"
  }
}

data "aws_subnet" "private_subnets_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${var.region}a"
  }
}

data "aws_subnet" "private_subnets_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${var.region}b"
  }
}

data "aws_subnet" "private_subnets_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${var.region}c"
  }
}

data "aws_route53_zone" "external" {
  provider = aws.core-vpc

  name         = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

data "aws_route53_zone" "inner" {
  provider = aws.core-vpc

  name         = "${var.networking[0].business-unit}-${local.environment}.modernisation-platform.internal."
  private_zone = true
}

data "aws_route53_zone" "network-services" {
  provider = aws.core-network-services

  name         = "modernisation-platform.service.justice.gov.uk."
  private_zone = false
}

data "aws_subnet_ids" "shared-public" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public*"
  }
}

data "terraform_remote_state" "core_network_services" {
  backend = "s3"
  config = {
    acl     = "bucket-owner-full-control"
    bucket  = "modernisation-platform-terraform-state"
    key     = "environments/accounts/core-network-services/core-network-services-production/terraform.tfstate"
    region  = "eu-west-2"
    encrypt = "true"
  }
}

data "template_file" "launch-template" {
  template = "${file("templates/user-data.txt")}"
  vars = {
    cluster_name = local.application_name
  }
}

data "template_file" "task_definition" {
  template = "${file("templates/task_definition.json")}"
  vars = {
    app_name          = local.application_name
    #app_image         = format("%s%s", data.aws_caller_identity.current.account".dkr.ecr."${var.region}".amazonaws.com/"${local.application_name})
    app_image         = format("%s%s", data.aws_caller_identity.current.account_id,var.app_image)
    #data.aws_ecr_image.service_image.id
    #".dkr.ecr.eu-west-2.amazonaws.com/ccms-opa18-hub"
    server_port       = var.server_port
    aws_region        = var.region
    container_version = var.container_version
    db_host           = aws_db_instance.database.endpoint
    # db_user           = var.db_user
    # db_password       = var.db_password
  }
}

#------------------------------------------------------------------------------
# ECS
#------------------------------------------------------------------------------

module "windows-ecs" {

  source = "../../modules/windows-ecs"

  subnet_set_name             = local.subnet_set_name
  vpc_all                     = local.vpc_all
  app_name                    = local.application_name
  ami_image_id                = var.ami_image_id
  instance_type               = var.instance_type
  user_data                   = base64encode(data.template_file.launch-template.rendered)
  key_name                    = var.key_name
  task_definition             = data.template_file.task_definition.rendered
  ec2_desired_capacity        = var.ec2_desired_capacity
  ec2_max_size                = var.ec2_max_size
  ec2_min_size                = var.ec2_min_size
  container_cpu               = var.container_cpu
  container_memory            = var.container_memory
  server_port                 = var.server_port
  app_count                   = var.app_count
#   cidr_access                 = var.cidr_access
  tags_common                 = local.tags

  depends_on = [aws_ecr_repository.ecr_repo, aws_lb_listener.listener]
}

resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-preprod.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# TODO Split out the domain validation options so that we only create one record in the relevant domain
resource "aws_route53_record" "external_validation" {
  provider = aws.core-network-services
  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

# TODO Split out the domain validation options so that we only create one record in the relevant domain
resource "aws_route53_record" "external_validation_subdomain" {
  provider = aws.core-vpc
  for_each = {
    for dvo in aws_acm_certificate.external.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = concat([for record in aws_route53_record.external_validation : record.fqdn], [for record in aws_route53_record.external_validation_subdomain : record.fqdn])
}

#------------------------------------------------------------------------------
# Load Balancer
#------------------------------------------------------------------------------

resource "aws_lb" "external" {
  name               = local.application_name
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.shared-public.ids

  security_groups = [aws_security_group.load_balancer_security_group.id]

  tags = local.tags
}

resource "aws_lb_target_group" "target_group" {
  name                 = local.application_name
  port                 = var.server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  # health_check {
  #   path                = var.health_check_path
  #   healthy_threshold   = "5"
  #   interval            = "120"
  #   protocol            = "HTTP"
  #   unhealthy_threshold = "2"
  #   matcher             = "200"
  #   timeout             = "5"
  # }

  tags = local.tags
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.external.id
  port              = var.server_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.external.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "https_listener" {
  depends_on = [ aws_acm_certificate_validation.external ]

  load_balancer_arn = aws_lb.external.id
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      status_code  = "403"
    }
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  name_prefix = local.application_name
  description = "controls access to lb"
  vpc_id      = data.aws_vpc.shared.id

  # ingress {
  #   protocol  = "tcp"
  #   from_port = var.server_port
  #   to_port   = var.server_port
  #   cidr_blocks = concat(
  #     var.cidr_access,
  #   )
  # }

  # ingress {
  #   protocol  = "tcp"
  #   from_port = 80
  #   to_port   = 80
  #   cidr_blocks = concat(
  #     var.cidr_access,
  #   )
  # }

  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    cidr_blocks = ["0.0.0.0/0", ]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = local.tags
}

#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------

resource "aws_db_instance" "database" {
  identifier                          = local.application_name
  allocated_storage                   = 100
  storage_type                        = "gp2"
  engine                              = "sqlserver-se"
  engine_version                      = "15.00.4073.23.v1"
  license_model                       = "license-included"
  instance_class                      = "db.m5.large"
  multi_az                            = true
  # name                                = local.application_name
  username                            = var.db_user
  password                            = var.db_password
  storage_encrypted                   = false
  iam_database_authentication_enabled = false
  vpc_security_group_ids = [
    aws_security_group.db.id
  ]
  # snapshot_identifier       = var.db_snapshot_identifier
  backup_retention_period   = 30
  maintenance_window        = "Mon:00:00-Mon:03:00"
  backup_window             = "03:00-06:00"
  final_snapshot_identifier = "final-snapshot"
  deletion_protection       = false
  db_subnet_group_name      = aws_db_subnet_group.db.id

  # timeouts {
  #   create = "40m"
  #   delete = "40m"
  #   update = "80m"
  # }

  tags = local.tags
}

resource "aws_db_subnet_group" "db" {
  name = local.application_name
  subnet_ids = sort(data.aws_subnet_ids.shared-data.ids)
  tags = local.tags
}

resource "aws_security_group" "db" {
  name        = local.application_name
  description = "Allow DB inbound traffic"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port = 1433
    to_port   = 1433
    protocol  = "tcp"
    cidr_blocks = [data.aws_subnet.private_subnets_a.cidr_block, data.aws_subnet.private_subnets_b.cidr_block, data.aws_subnet.private_subnets_c.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

#------------------------------------------------------------------------------
# S3 Bucket for Database backup files
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "database_files" {
  bucket_prefix = "performance-hub"
  acl           = "private"

  lifecycle {
    prevent_destroy = true
  }

  dynamic "lifecycle_rule" {
    for_each = true ? [true] : []

    content {
      enabled = true

      noncurrent_version_transition {
        days          = 30
        storage_class = "STANDARD_IA"
      }

      transition {
        days          = 60
        storage_class = "STANDARD_IA"
      }
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.s3.arn
      }
    }
  }

  versioning {
    enabled = true
  }

  tags = merge(
    local.tags,
    {
      Name = "performance-hub-s3"
    },
  )
}

#S3 bucket access policy
data "aws_iam_policy_document" "bucket_access" {

  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.database_files.arn,
      "${aws_s3_bucket.database_files.arn}/*"
    ]
    principals {
      identifiers = ["s3.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_s3_bucket_policy" "root" {

  bucket = aws_s3_bucket.database_files.id
  policy = data.aws_iam_policy_document.bucket_access.json
}

#------------------------------------------------------------------------------
# KMS setup for S3
#------------------------------------------------------------------------------

resource "aws_kms_key" "s3" {
  description         = "Encryption key for s3"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.s3-kms.json

  tags = merge(
    local.tags,
    {
      Name = "s3-kms"
    },
  )
}

resource "aws_kms_alias" "kms-alias" {
  name          = "alias/s3"
  target_key_id = aws_kms_key.s3.arn
}

data "aws_iam_policy_document" "s3-kms" {
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}
