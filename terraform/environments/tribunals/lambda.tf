resource "aws_iam_role" "lambda_role" {
  name = "lambda_db_setup_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_custom_policy" {
  name        = "lambda_custom_policy"
  description = "Custom policy for Lambda to interact with RDS and other AWS services"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect : "Allow",
        Action : [
          "ec2:CreateSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DescribeNetworkInterfaces"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "rds-db:connect",
          "rds:CreateDBProxy",
          "rds:CreateDBInstance",
          "rds:CreateDBSubnetGroup",
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "rds:DescribeDBSubnetGroups",
          "rds:DescribeDBProxies",
          "rds:DescribeDBProxyTargets",
          "rds:DescribeDBProxyTargetGroups",
          "rds:RegisterDBProxyTargets",
          "rds:ModifyDBInstance",
          "rds:ModifyDBProxy"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "lambda:CreateFunction",
          "lambda:ListFunctions",
          "lambda:UpdateFunctionConfiguration"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "iam:AttachRolePolicy",
          "iam:AttachPolicy",
          "iam:CreateRole",
          "iam:CreatePolicy"
        ],
        Resource : "*"
      },
      {
        Effect : "Allow",
        Action : [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:CreateSecret"
        ],
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_custom_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_custom_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_vpc_policy" {
  name        = "lambda_vpc_policy"
  description = "Policy to allow Lambda to create network interfaces in VPC"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_vpc_policy.arn
}

resource "random_password" "app_new_password" {
  length  = 16
  special = false
}

resource "aws_lambda_layer_version" "pyodbc_layer" {
  filename            = "pyodbc311.zip"
  layer_name          = "pyodbc_layer"
  compatible_runtimes = ["python3.11"]
}

resource "aws_lambda_function" "app_setup_db" {
  for_each      = var.web_app_services
  filename      = "lambda_function/my_deployment_package.zip"
  function_name = "${each.value.name_prefix}-setup-db"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300
  architectures = ["x86_64"]

  environment {
    variables = {
      DB_URL        = aws_db_instance.rdsdb.address
      USER_NAME     = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["username"]
      PASSWORD      = jsondecode(data.aws_secretsmanager_secret_version.data_rds_secret_current.secret_string)["password"]
      NEW_DB_NAME   = each.value.app_db_name
      APP_FOLDER    = each.value.sql_migration_path
    }
  }

  vpc_config {
    subnet_ids         = data.aws_subnets.shared-private.ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  layers = [aws_lambda_layer_version.pyodbc_layer.arn]
}

resource "aws_security_group" "lambda_sg" {
  name   = "lambda_sg"
  vpc_id = data.aws_vpc.shared.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_security_group_rule" "allow_lambda_access_to_rds" {
#   type                     = "ingress"
#   from_port                = 1433
#   to_port                  = 1433
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.sqlserver_db_sc.id
#   source_security_group_id = aws_security_group.lambda_sg.id
# }
