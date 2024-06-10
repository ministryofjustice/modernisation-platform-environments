# resource "aws_ssm_parameter" "ssh_key" {
#   name        = "EC2_SSH_KEY" # This needs to match the name supplied to the dbconnect.js script
#   description = "SSH Key used by Lambda function to access database instance for backup. Value is updated manually."
#   type        = "SecureString"
#   value       = "Placeholder"

#   tags = merge(
#     local.tags,
#     { Name = "EC2_SSH_KEY" }
#   )
#   lifecycle {
#     ignore_changes = [
#       value,
#     ]
#   }
# }

##################################
### IAM Role for BackUp Lambda
##################################

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "ssm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backuplambdarole" {
  name               = "edw-backuplambdarole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "backuplambdapolicy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  name   = "${local.application_name}-${local.environment}-backup-lambda-policy"
  tags   = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-backup-lambda-policy" }
  )
  policy = <<EOF
{
    "Version" : "2012-10-17",
    "Statement": [
        {
            "Action": [
                "lambda:InvokeFunction",
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeSecurityGroups",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:DescribeInstances",
                "ec2:DescribeAddresses",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeVolumes",
                "ec2:DescribeSnapshots",
                "ec2:CreateTags",
                "s3:*",
                "ssm:*",
                "ses:*",
                "logs:*",
                "cloudwatch:*",
                "sts:AssumeRole"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "backuppolicyattachment" {
  role       = aws_iam_role.backuplambdarole.name
  policy_arn = aws_iam_policy.backuplambdapolicy.arn
}

##################################
### S3 for Backup Lambda
##################################

resource "aws_s3_bucket" "backup_lambda" {
  bucket = "${local.application_name}-${local.environment}-backup-lambda"
  tags   = merge(
    local.tags,
    { Name = "${local.application_name}-${local.environment}-backup-lambda" }
  )
}

resource "aws_s3_object" "provision_files" {
  bucket       = aws_s3_bucket.backup_lambda.id
  for_each     = fileset("./zipfiles/", "**")
  key          = each.value
  source       = "./zipfiles/${each.value}" 
  content_type = "application/zip"
  source_hash  = filemd5("./zipfiles/${each.value}")
}

# This delays the creation of resource 
resource "time_sleep" "wait_for_provision_files" {
  create_duration = "1m"
  depends_on      = [aws_s3_object.provision_files]
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
## Thus no need to add the zip files manually to the zipfiles directory except for nodejs.zip


data "archive_file" "dbsnapshot_file" {
  type        = "zip"
  source_file = local.dbsnapshot_source_file
  output_path = local.dbsnapshot_output_path
}

data "archive_file" "deletesnapshot_file" {
  type        = "zip"
  source_file = local.deletesnapshot_source_file
  output_path = local.deletesnapshot_output_path

}

data "archive_file" "dbconnect_file" {
  type        = "zip"
  source_file = local.dbconnect_source_file
  output_path = local.dbconnect_output_path
}


######################################
### Lambda Resources
######################################

resource "aws_security_group" "lambdasg" {
  name        = "${local.application_name}-${local.environment}-lambda-security-group"
  description = "EDW Lambda Security Group"
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
    { Name = "${local.application_name}-${local.environment}-backup-lambda-security-group" }
  )
}

resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name   = "SSHNodeJSLayer"
  description  = "A layer to add ssh libs to lambda"
  license_info = "Apache-2.0"
  s3_bucket    = aws_s3_bucket.backup_lambda.id
  s3_key       = local.s3layerkey

  compatible_runtimes = [local.compatible_runtimes]
}


resource "aws_lambda_function" "snapshotDBFunction" {

  description      = "Snapshot volumes for Oracle EC2"
  function_name    = local.snapshotDBFunctionname
  role             = aws_iam_role.backuplambdarole.arn
  handler          = local.snapshotDBFunctionhandler
  source_code_hash = data.archive_file.dbsnapshot_file.output_base64sha256
  runtime          = local.snapshotDBFunctionruntime
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  s3_bucket        = aws_s3_bucket.backup_lambda.id
  s3_key           = local.snapshotDBFunctionfilename
  memory_size      = 128
  timeout          = 900
  depends_on       = [time_sleep.wait_for_provision_files] #This resource will create (at least) 300 seconds after aws_s3_object.provision_files




  environment {
    variables = {
      LD_LIBRARY_PATH = "/opt/nodejs/node_modules/lib"

    }
  }
  vpc_config {
    security_group_ids = [aws_security_group.lambdasg.id]
    subnet_ids         = [data.aws_subnet.private_subnets_a.id]
  }
  tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-lambda-snapshot-mp" }
  )
}

resource "aws_lambda_function" "deletesnapshotFunction" {

  description      = "Clean up script to delete old unused snapshots"
  function_name    = local.deletesnapshotFunctionname
  role             = aws_iam_role.backuplambdarole.arn
  handler          = local.deletesnapshotFunctionhandler
  source_code_hash = data.archive_file.deletesnapshot_file.output_base64sha256
  runtime          = local.deletesnapshotFunctionruntime
  s3_bucket        = aws_s3_bucket.backup_lambda.id
  s3_key           = local.deletesnapshotFunctionfilename
  memory_size      = 1024
  timeout          = 900
  depends_on       = [time_sleep.wait_for_provision_files] #This resource will create (at least) 300 seconds after aws_s3_object.provision_files


  environment {
    variables = {
      LD_LIBRARY_PATH = "/opt/nodejs/node_modules/lib"

    }
  }
  vpc_config {
    security_group_ids = [aws_security_group.lambdasg.id]
    subnet_ids         = [data.aws_subnet.private_subnets_a.id]
  }
  tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-lambda-deletesnapshot-mp" }
  )
}


resource "aws_lambda_function" "connectDBFunction" {

  description      = "SSH to the DB EC2"
  function_name    = local.connectDBFunctionname
  role             = aws_iam_role.backuplambdarole.arn
  handler          = local.connectDBFunctionhandler
  source_code_hash = data.archive_file.dbconnect_file.output_base64sha256
  runtime          = local.connectDBFunctionruntime
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  s3_bucket        = aws_s3_bucket.backup_lambda.id
  s3_key           = local.connectDBFunctionfilename
  memory_size      = 128
  timeout          = 900
  depends_on       = [time_sleep.wait_for_provision_files] #This resource will create (at least) 300 seconds after aws_s3_object.provision_files



  environment {
    variables = {
      LD_LIBRARY_PATH = "/opt/nodejs/node_modules/lib"

    }
  }
  vpc_config {
    security_group_ids = [aws_security_group.lambdasg.id]
    subnet_ids         = [data.aws_subnet.private_subnets_a.id]
  }
  tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-lambda-connect-mp" }
  )
}
