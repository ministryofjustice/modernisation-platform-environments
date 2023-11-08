module "iambackup" {
  source = "./modules/lambdapolicy"
    backup_policy_name = "laa-${local.application_name}-${local.environment}-policy"
    tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-mp" }
  )
}

module "s3_bucket_lambda" {
  source = "./modules/s3"

  bucket_name = "laa-${local.application_name}-${local.environment}-mp"
  tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-mp" }
  )

}

resource "aws_security_group" "lambdasg" {
  name       = "${local.application_name}-${local.environment}-lambda-security-group"
  description = "APEX Lambda Security Group"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    description = "outbound access"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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



resource "aws_lambda_layer_version" "lambda_layer" {
  layer_name = "SSHNodeJSLayer"
  description = "A layer to add ssh libs to lambda"
  license_info = "Apache-2.0"
  s3_bucket = module.s3_bucket_lambda.lambdabucketname
  s3_key = local.s3layerkey

  compatible_runtimes = [local.compatible_runtimes]
}


resource "aws_lambda_function" "snapshotDBFunction" {
  function_name = local.snapshotDBFunctionname
  role          = module.iambackup.backuprole
  handler       = local.snapshotDBFunctionhandler
  source_code_hash = data.archive_file.dbsnapshot_file.output_base64sha256
  runtime = local.snapshotDBFunctionruntime
  layers = [aws_lambda_layer_version.lambda_layer.arn]
  s3_bucket = module.s3_bucket_lambda.lambdabucketname
  s3_key = local.snapshotDBFunctionfilename
  memory_size = 300
  timeout = 300
  

  environment {
    variables = {
      LD_LIBRARY_PATH = "/opt/nodejs/node_modules/lib"

    }
  }
   vpc_config {
    security_group_ids = [aws_security_group.lambdasg.id]
    subnet_ids = [data.aws_subnet.private_subnets_a.id]
  }
  tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-lambda-snapshot-mp" }
  )
}

resource "aws_lambda_function" "deletesnapshotFunction" {
  function_name = local.deletesnapshotFunctionname
  role          = module.iambackup.backuprole
  handler       = local.deletesnapshotFunctionhandler
  source_code_hash = data.archive_file.deletesnapshot_file.output_base64sha256
  runtime = local.deletesnapshotFunctionruntime
  s3_bucket = module.s3_bucket_lambda.lambdabucketname
  s3_key = local.deletesnapshotFunctionfilename

  environment {
    variables = {
      LD_LIBRARY_PATH = "/opt/nodejs/node_modules/lib"

    }
  }
   vpc_config {
    security_group_ids = [aws_security_group.lambdasg.id]
    subnet_ids = [data.aws_subnet.private_subnets_a.id]
  }
  tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-lambda-deletesnapshot-mp" }
  )
}


resource "aws_lambda_function" "connectDBFunction" {
  function_name = local.connectDBFunctionname
  role          = module.iambackup.backuprole
  handler       = local.connectDBFunctionhandler
  source_code_hash = data.archive_file.dbconnect_file.output_base64sha256
  runtime = local.connectDBFunctionruntime
  layers = [aws_lambda_layer_version.lambda_layer.arn]
  s3_bucket = module.s3_bucket_lambda.lambdabucketname
  s3_key = local.connectDBFunctionfilename
  memory_size = 350
  timeout = 300

  environment {
    variables = {
      LD_LIBRARY_PATH = "/opt/nodejs/node_modules/lib"

    }
  }
   vpc_config {
    security_group_ids = [aws_security_group.lambdasg.id]
    subnet_ids = [data.aws_subnet.private_subnets_a.id]
  }
  tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-lambda-connect-mp" }
  )
}

