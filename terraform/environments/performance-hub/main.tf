resource "aws_ecr_repository" "ecr_repo" {
  name                 = local.application_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  lifecycle {
    prevent_destroy = true
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
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${local.app_data.accounts[local.environment].region}a"
  }
}

data "aws_subnet" "private_subnets_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${local.app_data.accounts[local.environment].region}b"
  }
}

data "aws_subnet" "private_subnets_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-private-${local.app_data.accounts[local.environment].region}c"
  }
}

data "aws_subnet" "public_az_a" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public-${local.app_data.accounts[local.environment].region}a"
  }
}

data "aws_subnet" "public_az_b" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public-${local.app_data.accounts[local.environment].region}b"
  }
}

data "aws_subnet" "public_az_c" {
  vpc_id = data.aws_vpc.shared.id
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public-${local.app_data.accounts[local.environment].region}c"
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
  template = file("templates/user-data.txt")
  vars = {
    cluster_name = local.application_name
    environment  = local.environment
  }
}

data "template_file" "task_definition" {
  template = file("templates/task_definition.json")
  vars = {
    app_name             = local.application_name
    ecr_url              = format("%s%s%s%s%s", data.aws_caller_identity.current.account_id, ".dkr.ecr.", local.app_data.accounts[local.environment].region, ".amazonaws.com/", local.application_name)
    server_port          = local.app_data.accounts[local.environment].server_port
    aws_region           = local.app_data.accounts[local.environment].region
    container_version    = local.app_data.accounts[local.environment].container_version
    db_host              = aws_db_instance.database.address
    db_user              = local.app_data.accounts[local.environment].db_user
    db_password          = "${data.aws_secretsmanager_secret_version.database_password.arn}:perfhub_db_password::"
    mojhub_cnnstr        = "${data.aws_secretsmanager_secret_version.mojhub_cnnstr.arn}:mojhub_cnnstr::"
    mojhub_membership    = "${data.aws_secretsmanager_secret_version.mojhub_membership.arn}:mojhub_membership::"
    govuk_notify_api_key = "${data.aws_secretsmanager_secret_version.govuk_notify_api_key.arn}:govuk_notify_api_key::"
    os_vts_api_key       = "${data.aws_secretsmanager_secret_version.os_vts_api_key.arn}:os_vts_api_key::"
  }
}

#------------------------------------------------------------------------------
# ECS
#------------------------------------------------------------------------------

module "windows-ecs" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs?ref=v1.0.1"

  subnet_set_name         = local.subnet_set_name
  vpc_all                 = local.vpc_all
  app_name                = local.application_name
  container_instance_type = local.app_data.accounts[local.environment].container_instance_type
  environment             = local.environment
  ami_image_id            = local.app_data.accounts[local.environment].ami_image_id
  instance_type           = local.app_data.accounts[local.environment].instance_type
  user_data               = base64encode(data.template_file.launch-template.rendered)
  key_name                = local.app_data.accounts[local.environment].key_name
  task_definition         = data.template_file.task_definition.rendered
  ec2_desired_capacity    = local.app_data.accounts[local.environment].ec2_desired_capacity
  ec2_max_size            = local.app_data.accounts[local.environment].ec2_max_size
  ec2_min_size            = local.app_data.accounts[local.environment].ec2_min_size
  container_cpu           = local.app_data.accounts[local.environment].container_cpu
  container_memory        = local.app_data.accounts[local.environment].container_memory
  task_definition_volume  = local.app_data.accounts[local.environment].task_definition_volume
  network_mode            = local.app_data.accounts[local.environment].network_mode
  server_port             = local.app_data.accounts[local.environment].server_port
  app_count               = local.app_data.accounts[local.environment].app_count
  public_cidrs            = [data.aws_subnet.public_az_a.cidr_block, data.aws_subnet.public_az_b.cidr_block, data.aws_subnet.public_az_c.cidr_block]
  bastion_cidr            = "${module.bastion_linux.bastion_private_ip}/32"
  ec2_ingress_rules       = local.ec2_ingress_rules
  tags_common             = local.tags

  depends_on = [aws_ecr_repository.ecr_repo, aws_lb_listener.listener]
}

resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
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

resource "aws_route53_record" "external_validation" {
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}

#------------------------------------------------------------------------------
# Load Balancer
#------------------------------------------------------------------------------

resource "aws_lb" "external" {
  name               = "${local.application_name}-loadbalancer"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.shared-public.ids

  security_groups = [aws_security_group.load_balancer_security_group.id]

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-external-loadbalancer"
    }
  )
}

resource "aws_lb_target_group" "target_group" {
  name                 = "${local.application_name}-tg-${local.environment}"
  port                 = local.app_data.accounts[local.environment].server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"
  }

  health_check {
    # path                = "/"
    healthy_threshold   = "5"
    interval            = "120"
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-tg-${local.environment}"
    }
  )
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.external.id
  port              = local.app_data.accounts[local.environment].server_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "https_listener" {
  depends_on = [aws_acm_certificate_validation.external]

  load_balancer_arn = aws_lb.external.id
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.external.arn

  default_action {
    target_group_arn = aws_lb_target_group.target_group.id
    type             = "forward"
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  name_prefix = "${local.application_name}-loadbalancer-security-group"
  description = "controls access to lb"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    protocol    = "tcp"
    from_port   = local.app_data.accounts[local.environment].server_port
    to_port     = local.app_data.accounts[local.environment].server_port
    cidr_blocks = ["0.0.0.0/0", ]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
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

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-loadbalancer-security-group"
    }
  )
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
  instance_class                      = local.app_data.accounts[local.environment].db_instance_class
  multi_az                            = false
  username                            = local.app_data.accounts[local.environment].db_user
  password                            = data.aws_secretsmanager_secret_version.database_password.arn
  storage_encrypted                   = false
  iam_database_authentication_enabled = false
  vpc_security_group_ids              = [aws_security_group.db.id]
  snapshot_identifier                 = local.app_data.accounts[local.environment].db_snapshot_identifier
  backup_retention_period             = 0
  maintenance_window                  = "Mon:00:00-Mon:03:00"
  backup_window                       = "03:00-06:00"
  final_snapshot_identifier           = "final-snapshot"
  deletion_protection                 = false
  option_group_name                   = aws_db_option_group.db_option_group.name
  db_subnet_group_name                = aws_db_subnet_group.db.id

  # timeouts {
  #   create = "40m"
  #   delete = "40m"
  #   update = "80m"
  # }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-database"
    }
  )
}

resource "aws_db_option_group" "db_option_group" {
  name                     = "${local.application_name}-option-group"
  option_group_description = "Terraform Option Group"
  engine_name              = "sqlserver-se"
  major_engine_version     = "15.00"

  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.s3_database_backups_role.arn
    }
  }
}

resource "aws_db_subnet_group" "db" {
  name       = "${local.application_name}-db-subnet-group"
  subnet_ids = sort(data.aws_subnet_ids.shared-data.ids)
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-db-subnet-group"
    }
  )
}

resource "aws_security_group" "db" {
  name        = "${local.application_name}-db-sg"
  description = "Allow DB inbound traffic"
  vpc_id      = data.aws_vpc.shared.id
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-db-sg"
    }
  )
}

resource "aws_security_group_rule" "db_mgmt_ingress_rule" {
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.db_mgmt_server_security_group.id
}

resource "aws_security_group_rule" "db_ecs_ingress_rule" {
  type                     = "ingress"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = module.windows-ecs.cluster_ec2_security_group_id
}

resource "aws_security_group_rule" "db_bastion_ingress_rule" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  security_group_id = aws_security_group.db.id
  cidr_blocks       = ["${module.bastion_linux.bastion_private_ip}/32"]
}

#------------------------------------------------------------------------------
# S3 Bucket for Database backup files
#------------------------------------------------------------------------------
resource "aws_s3_bucket" "database_backup_files" {
  bucket = "${local.application_name}-db-backups-${local.environment}"
  acl    = "private"

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
      Name = "${local.application_name}-db-backups-s3"
    }
  )
}

#S3 bucket access policy
resource "aws_iam_policy" "s3_database_backups_policy" {
  name   = "${local.application_name}-s3-database_backups-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
          "${aws_s3_bucket.database_backup_files.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObjectMetaData",
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload"
      ],
      "Resource": [
        "${aws_s3_bucket.database_backup_files.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "s3_database_backups_role" {
  name               = "${local.application_name}-s3-database-backups-role"
  assume_role_policy = data.aws_iam_policy_document.s3-access-policy.json
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-s3-db-backups-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "s3_database_backups_attachment" {
  role       = aws_iam_role.s3_database_backups_role.name
  policy_arn = aws_iam_policy.s3_database_backups_policy.arn
}
#------------------------------------------------------------------------------
# S3 Bucket for Uploads
#------------------------------------------------------------------------------
resource "aws_s3_bucket" "upload_files" {
  bucket = "${local.application_name}-uploads-${local.environment}"
  acl    = "private"

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
      Name = "${local.application_name}-uploads"
    }
  )
}

resource "aws_s3_bucket_policy" "upload_files_policy" {
  bucket = aws_s3_bucket.upload_files.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "upload_bucket_policy"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.upload_files.arn,
          "${aws_s3_bucket.upload_files.arn}/*",
        ]
      },
    ]
  })
}

resource "aws_iam_role" "s3_uploads_role" {
  name               = "${local.application_name}-s3-uploads-role"
  assume_role_policy = data.aws_iam_policy_document.s3-access-policy.json
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-s3-uploads-role"
    }
  )
}

data "aws_iam_policy_document" "s3-access-policy" {
  version = "2012-10-17"
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "rds.amazonaws.com",
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "s3-uploads-policy" {
  name   = "${local.application_name}-s3-uploads-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "s3:*"
      ],
      "Resource": [
          "${aws_s3_bucket.upload_files.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.upload_files.arn}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "s3_uploads_attachment" {
  role       = aws_iam_role.s3_uploads_role.name
  policy_arn = aws_iam_policy.s3-uploads-policy.arn
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
      Name = "${local.application_name}-s3-kms"
    }
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
