data "aws_caller_identity" "current" {}

data "aws_vpc" "shared" {
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}"
  }
}

data "aws_subnets" "shared-data" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-data*"
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

data "aws_subnets" "shared-public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shared.id]
  }
  tags = {
    Name = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public*"
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
    app_name                         = local.application_name
    env_name                         = local.environment
    system_account_id                = local.app_data.accounts[local.environment].system_account_id
    ecr_url                          = format("%s%s%s%s", local.environment_management.account_ids["core-shared-services-production"], ".dkr.ecr.", local.app_data.accounts[local.environment].region, ".amazonaws.com/performance-hub-ecr-repo")
    server_port                      = local.app_data.accounts[local.environment].server_port
    aws_region                       = local.app_data.accounts[local.environment].region
    container_version                = local.app_data.accounts[local.environment].container_version
    db_host                          = aws_db_instance.database.address
    db_user                          = local.app_data.accounts[local.environment].db_user
    db_password                      = aws_secretsmanager_secret_version.db_password.arn
    mojhub_cnnstr                    = aws_secretsmanager_secret_version.mojhub_cnnstr.arn
    mojhub_membership                = aws_secretsmanager_secret_version.mojhub_membership.arn
    govuk_notify_api_key             = aws_secretsmanager_secret_version.govuk_notify_api_key.arn
    os_vts_api_key                   = aws_secretsmanager_secret_version.os_vts_api_key.arn
    storage_bucket                   = "${aws_s3_bucket.upload_files.id}"
    friendly_name                    = local.app_data.accounts[local.environment].friendly_name
    hub_wwwroot                      = local.app_data.accounts[local.environment].hub_wwwroot
    pecs_basm_prod_access_key_id     = aws_secretsmanager_secret_version.pecs_basm_prod_access_key_id.arn
    pecs_basm_prod_secret_access_key = aws_secretsmanager_secret_version.pecs_basm_prod_secret_access_key.arn
    ap_import_access_key_id          = aws_secretsmanager_secret_version.ap_import_access_key_id.arn
    ap_import_secret_access_key      = aws_secretsmanager_secret_version.ap_import_secret_access_key.arn
    ap_export_access_key_id          = aws_secretsmanager_secret_version.ap_export_access_key_id.arn
    ap_export_secret_access_key      = aws_secretsmanager_secret_version.ap_export_secret_access_key.arn
  }
}

#------------------------------------------------------------------------------
# ECS
#------------------------------------------------------------------------------

module "windows-ecs" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs?ref=v2.1.0"

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
  ec2_ingress_rules       = local.ec2_ingress_rules
  ec2_egress_rules        = local.ec2_egress_rules
  tags_common             = local.tags

  depends_on = [aws_lb_listener.listener]
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
#tfsec:ignore:AWS005 tfsec:ignore:AWS083
resource "aws_lb" "external" {
  #checkov:skip=CKV_AWS_91
  #checkov:skip=CKV_AWS_131
  #checkov:skip=CKV2_AWS_20
  #checkov:skip=CKV2_AWS_28
  name                       = "${local.application_name}-loadbalancer"
  load_balancer_type         = "application"
  subnets                    = data.aws_subnets.shared-public.ids
  enable_deletion_protection = true
  # allow 60*4 seconds before 504 gateway timeout for long-running DB operations
  idle_timeout = 240

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

#tfsec:ignore:AWS004
resource "aws_lb_listener" "listener" {
  #checkov:skip=CKV_AWS_2
  #checkov:skip=CKV_AWS_103
  load_balancer_arn = aws_lb.external.id
  port              = local.app_data.accounts[local.environment].server_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "https_listener" {
  #checkov:skip=CKV_AWS_103
  depends_on = [aws_acm_certificate_validation.external]

  load_balancer_arn = aws_lb.external.id
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = format("arn:aws:acm:eu-west-2:%s:certificate/%s", data.aws_caller_identity.current.account_id, local.app_data.accounts[local.environment].cert_arn)

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
    description = "Open the server port"
    from_port   = local.app_data.accounts[local.environment].server_port
    to_port     = local.app_data.accounts[local.environment].server_port
    #tfsec:ignore:AWS008
    cidr_blocks = ["0.0.0.0/0", ]
  }

  ingress {
    protocol    = "tcp"
    description = "Open the SSL port"
    from_port   = 443
    to_port     = 443
    #tfsec:ignore:AWS008
    cidr_blocks = ["0.0.0.0/0", ]
  }

  egress {
    protocol    = "-1"
    description = "Open all outbound ports"
    from_port   = 0
    to_port     = 0
    #tfsec:ignore:AWS009
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
  #tfsec:ignore:AWS099
  #checkov:skip=CKV_AWS_118
  #checkov:skip=CKV_AWS_157
  identifier                          = local.application_name
  allocated_storage                   = local.app_data.accounts[local.environment].db_allocated_storage
  storage_type                        = "gp2"
  engine                              = "sqlserver-se"
  engine_version                      = "15.00.4073.23.v1"
  license_model                       = "license-included"
  instance_class                      = local.app_data.accounts[local.environment].db_instance_class
  multi_az                            = false
  username                            = local.app_data.accounts[local.environment].db_user
  password                            = aws_secretsmanager_secret_version.db_password.arn
  storage_encrypted                   = true
  iam_database_authentication_enabled = false
  vpc_security_group_ids              = [aws_security_group.db.id]
  snapshot_identifier                 = format("arn:aws:rds:eu-west-2:%s:snapshot:%s", data.aws_caller_identity.current.account_id, local.app_data.accounts[local.environment].db_snapshot_identifier)
  backup_retention_period             = 30
  maintenance_window                  = "Mon:00:00-Mon:03:00"
  backup_window                       = "03:00-06:00"
  final_snapshot_identifier           = "final-snapshot"
  kms_key_id                          = aws_kms_key.rds.arn
  deletion_protection                 = false
  option_group_name                   = aws_db_option_group.db_option_group.name
  db_subnet_group_name                = aws_db_subnet_group.db.id
  enabled_cloudwatch_logs_exports     = ["error"]

  # timeouts {
  #   create = "40m"
  #   delete = "40m"
  #   update = "80m"
  # }

  lifecycle {
    prevent_destroy = true
  }

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
  subnet_ids = sort(data.aws_subnets.shared-data.ids)
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
  description              = "Default SQL Server port 1433"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.db_mgmt_server_security_group.id
}

resource "aws_security_group_rule" "db_ecs_ingress_rule" {
  type                     = "ingress"
  description              = "Default SQL Server port 1433"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = module.windows-ecs.cluster_ec2_security_group_id
}

resource "aws_security_group_rule" "db_bastion_ingress_rule" {
  type                     = "ingress"
  description              = "Default SQL Server port 1433"
  from_port                = 1433
  to_port                  = 1433
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = module.bastion_linux.bastion_security_group
}

resource "aws_security_group_rule" "db_windows_server_failover_tcp_ingress_rule" {
  type                     = "ingress"
  description              = "Windows Server Failover Cluster port TCP Ingress"
  from_port                = 3343
  to_port                  = 3343
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.db_mgmt_server_security_group.id
}

resource "aws_security_group_rule" "db_windows_server_failover_tcp_egress_rule" {
  type                     = "egress"
  description              = "Windows Server Failover Cluster port TCP Egress"
  from_port                = 3343
  to_port                  = 3343
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.db_mgmt_server_security_group.id
}

resource "aws_security_group_rule" "db_windows_server_failover_udp_ingress_rule" {
  type                     = "ingress"
  description              = "Windows Server Failover Cluster port UDP Ingress"
  from_port                = 3343
  to_port                  = 3343
  protocol                 = "udp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.db_mgmt_server_security_group.id
}

resource "aws_security_group_rule" "db_windows_server_failover_udp_egress_rule" {
  type                     = "egress"
  description              = "Windows Server Failover Cluster port UDP Egress"
  from_port                = 3343
  to_port                  = 3343
  protocol                 = "udp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = aws_security_group.db_mgmt_server_security_group.id
}

#------------------------------------------------------------------------------
# S3 Bucket for Database backup files
#------------------------------------------------------------------------------
#tfsec:ignore:AWS002 tfsec:ignore:AWS098
resource "aws_s3_bucket" "database_backup_files" {
  #checkov:skip=CKV_AWS_18
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV2_AWS_6
  bucket = "${local.application_name}-db-backups-${local.environment}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-db-backups-s3"
    }
  )
}

resource "aws_s3_bucket_acl" "database_backup_files" {
  bucket = aws_s3_bucket.database_backup_files.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "database_backup_files" {
  bucket = aws_s3_bucket.database_backup_files.id
  rule {
    id     = "tf-s3-lifecycle"
    status = "Enabled"
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "database_backup_files" {
  bucket = aws_s3_bucket.database_backup_files.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_versioning" "database_backup_files" {
  bucket = aws_s3_bucket.database_backup_files.id
  versioning_configuration {
    status = "Enabled"
  }
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
        "kms:DescribeKey",
        "kms:GenerateDataKey",
        "kms:Encrypt",
        "kms:Decrypt"
      ],
      "Resource": "${aws_kms_key.s3.arn}"
    },
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
#tfsec:ignore:AWS002 tfsec:ignore:AWS098
resource "aws_s3_bucket" "upload_files" {
  #checkov:skip=CKV_AWS_18
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV2_AWS_6
  bucket = "${local.application_name}-uploads-${local.environment}"

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-uploads"
    }
  )
}

resource "aws_s3_bucket_acl" "upload_files" {
  bucket = aws_s3_bucket.upload_files.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "upload_files" {
  bucket = aws_s3_bucket.upload_files.id
  rule {
    id     = "tf-s3-lifecycle"
    status = "Enabled"
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "upload_files" {
  bucket = aws_s3_bucket.upload_files.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_versioning" "upload_files" {
  bucket = aws_s3_bucket.upload_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "upload_files_policy" {
  bucket = aws_s3_bucket.upload_files.id
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "upload_bucket_policy"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cicd-member-user"] }
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
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetEncryptionConfiguration"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
      "kms:Decrypt"
      ],
      "Resource": "*"
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
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_109
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cicd-member-user"]
    }
  }
}
#------------------------------------------------------------------------------
# KMS setup for RDS
#------------------------------------------------------------------------------

resource "aws_kms_key" "rds" {
  description         = "Encryption key for rds"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.rds-kms.json

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-rds-kms"
    }
  )
}

resource "aws_kms_alias" "rds-kms-alias" {
  name          = "alias/rds"
  target_key_id = aws_kms_key.rds.arn
}

data "aws_iam_policy_document" "rds-kms" {
  #checkov:skip=CKV_AWS_111
  #checkov:skip=CKV_AWS_109
  statement {
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/cicd-member-user"]
    }
  }
}

#------------------------------------------------------------------------------
# Secrets definitions
#------------------------------------------------------------------------------
# Create secret
resource "random_password" "random_password" {

  length  = 32
  special = false
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "mojhub_cnnstr" {
  #checkov:skip=CKV_AWS_149
  name = "mojhub_cnnstr"
  tags = merge(
    local.tags,
    {
      Name = "mojhub_cnnstr"
    },
  )
}
resource "aws_secretsmanager_secret_version" "mojhub_cnnstr" {
  secret_id     = aws_secretsmanager_secret.mojhub_cnnstr.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "mojhub_membership" {
  #checkov:skip=CKV_AWS_149
  name = "mojhub_membership"
  tags = merge(
    local.tags,
    {
      Name = "mojhub_membership"
    },
  )
}
resource "aws_secretsmanager_secret_version" "mojhub_membership" {
  secret_id     = aws_secretsmanager_secret.mojhub_membership.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "govuk_notify_api_key" {
  #checkov:skip=CKV_AWS_149
  name = "govuk_notify_api_key"
  tags = merge(
    local.tags,
    {
      Name = "govuk_notify_api_key"
    },
  )
}
resource "aws_secretsmanager_secret_version" "govuk_notify_api_key" {
  secret_id     = aws_secretsmanager_secret.govuk_notify_api_key.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "os_vts_api_key" {
  #checkov:skip=CKV_AWS_149
  name = "os_vts_api_key"
  tags = merge(
    local.tags,
    {
      Name = "os_vts_api_key"
    },
  )
}
resource "aws_secretsmanager_secret_version" "os_vts_api_key" {
  secret_id     = aws_secretsmanager_secret.os_vts_api_key.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "ap_import_access_key_id" {
  #checkov:skip=CKV_AWS_149
  name = "ap_import_access_key_id"
  tags = merge(
    local.tags,
    {
      Name = "ap_import_access_key_id"
    },
  )
}
resource "aws_secretsmanager_secret_version" "ap_import_access_key_id" {
  secret_id     = aws_secretsmanager_secret.ap_import_access_key_id.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "ap_import_secret_access_key" {
  #checkov:skip=CKV_AWS_149
  name = "ap_import_secret_access_key"
  tags = merge(
    local.tags,
    {
      Name = "ap_import_secret_access_key"
    },
  )
}
resource "aws_secretsmanager_secret_version" "ap_import_secret_access_key" {
  secret_id     = aws_secretsmanager_secret.ap_import_secret_access_key.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "ap_export_access_key_id" {
  #checkov:skip=CKV_AWS_149
  name = "ap_export_access_key_id"
  tags = merge(
    local.tags,
    {
      Name = "ap_export_access_key_id"
    },
  )
}
resource "aws_secretsmanager_secret_version" "ap_export_access_key_id" {
  secret_id     = aws_secretsmanager_secret.ap_export_access_key_id.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "ap_export_secret_access_key" {
  #checkov:skip=CKV_AWS_149
  name = "ap_export_secret_access_key"
  tags = merge(
    local.tags,
    {
      Name = "ap_export_secret_access_key"
    },
  )
}
resource "aws_secretsmanager_secret_version" "ap_export_secret_access_key" {
  secret_id     = aws_secretsmanager_secret.ap_export_secret_access_key.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "pecs_basm_prod_access_key_id" {
  #checkov:skip=CKV_AWS_149
  name = "pecs_basm_prod_access_key_id"
  tags = merge(
    local.tags,
    {
      Name = "pecs_basm_prod_access_key_id"
    },
  )
}
resource "aws_secretsmanager_secret_version" "pecs_basm_prod_access_key_id" {
  secret_id     = aws_secretsmanager_secret.pecs_basm_prod_access_key_id.id
  secret_string = random_password.random_password.result
}

#tfsec:ignore:AWS095
resource "aws_secretsmanager_secret" "pecs_basm_prod_secret_access_key" {
  #checkov:skip=CKV_AWS_149
  name = "pecs_basm_prod_secret_access_key"
  tags = merge(
    local.tags,
    {
      Name = "pecs_basm_prod_secret_access_key"
    },
  )
}
resource "aws_secretsmanager_secret_version" "pecs_basm_prod_secret_access_key" {
  secret_id     = aws_secretsmanager_secret.pecs_basm_prod_secret_access_key.id
  secret_string = random_password.random_password.result
}
