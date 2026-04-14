locals {
  emds_gdpr_ecr_name = "electronic-monitoring-gdpr"
  shred_unstructured_image_name = "gdpr_zip_file_shredder"
  shred_unstructured_docker_image_uri = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/${local.emds_gdpr_ecr_name}:${local.shred_unstructured_image_name}-${local.environment}"
}

# ==============================================================================
# 1. IAM: Batch Service Role (Allows AWS Batch to manage EC2 instances)
# ==============================================================================
data "aws_iam_policy_document" "gdpr_batch_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["batch.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gdpr_batch_service_role" {
  name               = "emds-gdpr-batch-service-role"
  assume_role_policy = data.aws_iam_policy_document.gdpr_batch_assume_role.json
}

resource "aws_iam_role_policy_attachment" "gdpr_batch_service_role_attachment" {
  role       = aws_iam_role.gdpr_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

# ==============================================================================
# 1.a. AWS Batch Infrastructure - shred unstructured job
# ==============================================================================

resource "aws_batch_compute_environment" "shred_unstructured_from_zip_batch_compute_env" {
  count                    = local.is-production || local.is-development || local.is-preproduction ? 1 : 0
  name                     = "shred-unstructured-from-zip-env"
  type                     = "MANAGED"
  service_role             = aws_iam_role.gdpr_batch_service_role.arn
  tags = merge(local.tags, { Batch_Job_Name = local.shred_unstructured_image_name })

  compute_resources {
    type                = "SPOT"
    spot_iam_fleet_role = aws_iam_role.gdpr_spot_fleet_role.arn
    max_vcpus           = 16
    min_vcpus           = 0
    security_group_ids  = [aws_security_group.gdpr_batch_sg[0].id]
    subnets             = data.aws_subnets.shared-private.ids
    
    # Require large instances with high network/EBS bandwidth
    instance_type       = ["m5.2xlarge", "m5.4xlarge", "r5.2xlarge"]
    instance_role       = aws_iam_instance_profile.gdpr_batch_instance_profile.arn

    launch_template {
      launch_template_id = aws_launch_template.shred_unstructured_from_zip_batch_storage_template.id
      version            = "$Latest"
    }
  }
}

resource "aws_batch_job_queue" "shred_unstructured_from_zip_batch_queue" {
  count                = local.is-production || local.is-development || local.is-preproduction ? 1 : 0
  name                 = "shred-unstructured-from-zip-processing-queue"
  state                = "ENABLED"
  priority             = 1
  compute_environment_order {
    order               = 1
    compute_environment = aws_batch_compute_environment.shred_unstructured_from_zip_batch_compute_env[count.index].arn
  }
  tags = merge(local.tags, { Batch_Job_Name = local.shred_unstructured_image_name })
}

resource "aws_batch_job_definition" "shred_unstructured_from_zip_job" {
  name = "shred-unstructured-from-zip-job"
  type = "container"
  tags = merge(local.tags, { Batch_Job_Name = local.shred_unstructured_image_name })

  # Retry failed jobs once, just in case of an EC2 Spot interruption
  retry_strategy {
    attempts = 2
  }

  container_properties = jsonencode({
    image            = local.shred_unstructured_docker_image_uri
    executionRoleArn = aws_iam_role.ecs_gdpr_execution_role.arn
    jobRoleArn       = aws_iam_role.gdpr_batch_code_job_role.arn
    
    resourceRequirements = [
      { type = "VCPU", value = "8" },
      { type = "MEMORY", value = "32768" }
    ]

    environment = [
      { name = "S3_FILE_URI", value = "" },
      { name = "DELETE_PATTERN", value = "" }
    ]
  })
}

resource "aws_launch_template" "shred_unstructured_from_zip_batch_storage_template" {
  name_prefix   = "shred-unstructured-from-zip-"
  
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 1500
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }
}

# ==============================================================================
# 1.b. IAM: Spot Fleet Role (Required ONLY because we use SPOT instances)
# ==============================================================================
data "aws_iam_policy_document" "gdpr_spot_fleet_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["spotfleet.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gdpr_spot_fleet_role" {
  name               = "emds-gdpr-spot-fleet-role"
  assume_role_policy = data.aws_iam_policy_document.gdpr_spot_fleet_assume_role.json
}

resource "aws_iam_role_policy_attachment" "gdpr_spot_fleet_role_attachment" {
  role       = aws_iam_role.gdpr_spot_fleet_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

# ==============================================================================
# 1.c. IAM: EC2 Instance Profile (Allows the EC2 servers to join the Batch cluster)
# ==============================================================================

data "aws_iam_policy_document" "gdpr_ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "gdpr_batch_instance_role" {
  name               = "emds-gdpr-batch-instance-role"
  assume_role_policy = data.aws_iam_policy_document.gdpr_ec2_assume_role.json
}

# Attach the managed policy required for ECS cluster registration
resource "aws_iam_role_policy_attachment" "gdpr_batch_instance_role_attach" {
  role       = aws_iam_role.gdpr_batch_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# EC2 requires IAM roles to be wrapped in an "Instance Profile" to be attached to a server
resource "aws_iam_instance_profile" "gdpr_batch_instance_profile" {
  name = "emds-gdpr-batch-instance-profile"
  role = aws_iam_role.gdpr_batch_instance_role.name
}

# ==============================================================================
# 2. IAM: ECS Execution Role with all policies for other AWS services
# ==============================================================================

## ECS resources
data "aws_iam_policy_document" "gdpr_batch_jobs_assume_ecs_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_gdpr_execution_role" {
  name               = "emds-gdpr-execution-role" # STRICT NAME REQUIRED BY EXTERNAL ECR
  assume_role_policy = data.aws_iam_policy_document.gdpr_batch_jobs_assume_ecs_policy.json
}

resource "aws_iam_role_policy_attachment" "gdpr_batch_jobs_ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_gdpr_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

## Cloudwatch resources
data "aws_iam_policy_document" "gdpr_batch_jobs_logs_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "gdpr_batch_jobs_logs_policy" {
  name   = "emds-gdpr-batch-jobs-logs-policy"
  policy = data.aws_iam_policy_document.gdpr_batch_jobs_logs_policy_document.json
}
resource "aws_iam_role_policy_attachment" "gdpr_batch_jobs_logs_policy_attach" {
  role       = aws_iam_role.ecs_gdpr_execution_role.name
  policy_arn = aws_iam_policy.gdpr_batch_jobs_logs_policy.arn
}
##

## ECR resources
data "aws_iam_policy_document" "gdpr_batch_jobs_ecr_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "gdpr_batch_jobs_ecr_policy" {
  name   = "emds-gdpr-batch-jobs-ecr-policy"
  policy = data.aws_iam_policy_document.gdpr_batch_jobs_ecr_policy_document.json
}
resource "aws_iam_role_policy_attachment" "gdpr_batch_jobs_ecr_policy_attach" {
  role       = aws_iam_role.ecs_gdpr_execution_role.name
  policy_arn = aws_iam_policy.gdpr_batch_jobs_ecr_policy.arn
}
##

# ==============================================================================
# 3. IAM: Job Role (For the code to access S3)
# ==============================================================================

# Can re-use the assume ecs statement as it is the same, but want different permissions here.
resource "aws_iam_role" "gdpr_batch_code_job_role" {
  name               = "emds-gdpr-code-job-role"
  assume_role_policy = data.aws_iam_policy_document.gdpr_batch_jobs_assume_ecs_policy.json
}

## S3 Policies
data "aws_iam_policy_document" "gdpr_batch_jobs_s3_access_policy_document" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      module.s3-data-bucket.bucket.arn,
      "${module.s3-data-bucket.bucket.arn}/*"
    ]
  }
}
resource "aws_iam_policy" "gdpr_batch_jobs_s3_access_policy" {
  name   = "emds-gdpr-batch-jobs-s3-role-policy"
  policy = data.aws_iam_policy_document.gdpr_batch_jobs_s3_access_policy_document.json
}
resource "aws_iam_role_policy_attachment" "gdpr_batch_jobs_s3_access_policy_attach" {
  role       = aws_iam_role.gdpr_batch_code_job_role.name
  policy_arn = aws_iam_policy.gdpr_batch_jobs_s3_access_policy.arn
}
##

# ==============================================================================
# 4. Security Groups, VPNs and Rules
# Uses aws_subnets.shared-private, data.aws_vpc.shared, and the data.aws_prefix_list.s3
# ==============================================================================

resource "aws_security_group" "gdpr_batch_sg" {
  #checkov:skip=CKV2_AWS_5
  count       = local.is-production || local.is-development || local.is-preproduction ? 1 : 0
  name_prefix = "emds-gdpr-batch-sg-"
  description = "Secuity Group for GDPR Batch Compute Environment"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    {
      Name          = "emds-gdpr-batch-sg"
      Resource_Type = "Security Group for GDPR Batch Compute Environment",
    }
  )
}

resource "aws_security_group_rule" "gdpr_batch_egress_s3" {
  for_each          = local.is-production || local.is-development || local.is-preproduction ? toset([for port in var.sqlserver_https_ports : tostring(port)]) : toset([])
  security_group_id = aws_security_group.gdpr_batch_sg[0].id
  type              = "egress"
  cidr_blocks       = data.aws_ip_ranges.london_s3.cidr_blocks
  protocol          = "tcp"
  from_port         = each.value
  to_port           = each.value
  description       = "AWS Batch -----[tcp]-----+ London S3 Cidr"
}

resource "aws_vpc_security_group_egress_rule" "gdpr_batch_egress_vpc" {
  count                        = local.is-production || local.is-development || local.is-preproduction ? 1 : 0
  security_group_id            = aws_security_group.gdpr_batch_sg[0].id
  description                  = "AWS Batch -----[https]-----+ VPC (for Cloudwatch, ECR, and AWS Batch API)"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
  cidr_ipv4 = data.aws_vpc.shared.cidr_block
}