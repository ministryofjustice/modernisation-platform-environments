locals {
  delete_db_snapshots_script_prefix = "deletesnapshots"
}

##################################
### IAM Role for BackUp Lambda
##################################

data "aws_iam_policy_document" "backup_lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "ssm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup_lambda" {
  name               = "${local.application_name_short}-backup-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.backup_lambda.json
  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-backup-lambda-role" }
  )
}

resource "aws_iam_policy" "backup_lambda" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name = "${local.application_name_short}-${local.environment}-backup-lambda-policy"
  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-backup-lambda-policy" }
  )
  policy = <<EOF
{
    "Version" : "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface",
                "ec2:DeleteSnapshot",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:DescribeInstances",
                "ec2:DescribeAddresses",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "backup_lambda" {
  role       = aws_iam_role.backup_lambda.name
  policy_arn = aws_iam_policy.backup_lambda.arn
}

##################################
### S3 for Backup Lambda
##################################

resource "aws_s3_bucket" "backup_lambda" {
  bucket = "${local.application_name_short}-${local.environment}-backup-lambda"
  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-backup-lambda" }
  )
}

resource "aws_s3_bucket_ownership_controls" "backup_lambda" {
  bucket = aws_s3_bucket.backup_lambda.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "backup_lambda" {
  bucket = aws_s3_bucket.backup_lambda.id
  acl    = "private"
  depends_on = [
    aws_s3_bucket_ownership_controls.backup_lambda
  ]
}

resource "aws_s3_bucket_public_access_block" "backup_lambda" {
  bucket                  = aws_s3_bucket.backup_lambda.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "backup_lambda" {
  bucket = aws_s3_bucket.backup_lambda.id
  versioning_configuration {
    status = "Enabled"
  }
}

#####################################
### Provision scripts to S3 bucket
#####################################

## When Terraform Init and Plan is ran as part of the pipeline, the zip files will be created, which will be picked up by aws_s3_object.provision_files in the Terraform Apply to send to the S3 bucket

data "archive_file" "delete_db_snapshots" {
  type        = "zip"
  source_file = "scripts/${local.delete_db_snapshots_script_prefix}.py"
  output_path = "scripts/${local.delete_db_snapshots_script_prefix}.zip"
}

resource "aws_s3_object" "provision_files" {
  bucket       = aws_s3_bucket.backup_lambda.id
  for_each     = toset(["${local.delete_db_snapshots_script_prefix}.zip"])
  key          = each.value
  source       = "./scripts/${each.value}"
  content_type = "application/zip"
  source_hash  = filemd5("./scripts/${each.value}")
}

# This delays the creation of resource 
resource "time_sleep" "wait_for_provision_files" {
  create_duration = "1m"
  depends_on      = [aws_s3_object.provision_files]
}

######################################
### Lambda Resources
######################################

resource "aws_security_group" "backup_lambda" {
  name        = "${local.application_name_short}-${local.environment}-backup-lambda-security-group"
  description = "Bakcup Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    description = "outbound access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-backup-lambda-security-group" }
  )
}

resource "aws_lambda_function" "delete_db_snapshots" {

  description      = "Clean up script to delete old unused snapshots"
  function_name    = "deletesnapshotFunction"
  role             = aws_iam_role.backup_lambda.arn
  handler          = "deletesnapshots.lambda_handler"
  source_code_hash = data.archive_file.delete_db_snapshots.output_base64sha256
  runtime          = "python3.8"
  s3_bucket        = aws_s3_bucket.backup_lambda.id
  s3_key           = "${local.delete_db_snapshots_script_prefix}.zip"
  memory_size      = 3000
  timeout          = 900
  depends_on       = [time_sleep.wait_for_provision_files] # This resource creation will be delayed to ensure object exists in the bucket

  vpc_config {
    security_group_ids = [aws_security_group.backup_lambda.id]
    subnet_ids         = [data.aws_subnet.data_subnets_a.id]
  }
  tags = merge(
    local.tags,
    { Name = "${local.application_name_short}-${local.environment}-lambda-delete-snapshots" }
  )
}