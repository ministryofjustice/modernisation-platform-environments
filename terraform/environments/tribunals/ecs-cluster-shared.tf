resource "aws_ecs_cluster" "tribunals_cluster" {
  name = "tribunals-all-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "tribunalsFamily_logs" {
  #checkov:skip=CKV_AWS_158:"Using default AWS encryption for CloudWatch logs which is sufficient for our needs"
  name              = "/ecs/tribunalsFamily"
  retention_in_days = 365
}

resource "aws_iam_role" "app_execution" {
  name = "execution-${var.networking[0].application}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.tags,
    {
      Name = "execution-${var.networking[0].application}"
    },
  )
}

resource "aws_iam_role_policy" "app_execution" {
  #checkov:skip=CKV_AWS_290:"Required permissions for ECS execution role"
  #checkov:skip=CKV_AWS_289:"Required permissions for ECS execution role"
  #checkov:skip=CKV_AWS_355:"Required broad resource access for ECS execution role"
  #checkov:skip=CKV_AWS_288:"Required permissions for ECS operations"
  name = "execution-${var.networking[0].application}"
  role = aws_iam_role.app_execution.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
           "Action": [
              "ecr:*",
              "logs:CreateLogStream",
              "logs:PutLogEvents",
              "secretsmanager:GetSecretValue"
           ],
           "Resource": "*",
           "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "app_task" {
  name = "task-${var.networking[0].application}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.tags,
    {
      Name = "task-${var.networking[0].application}"
    },
  )
}

resource "aws_iam_role_policy" "app_task" {
  #checkov:skip=CKV_AWS_290:"Required permissions for ECS task role"
  #checkov:skip=CKV_AWS_289:"Required permissions for ECS task role"
  #checkov:skip=CKV_AWS_355:"Required broad resource access for ECS task role"
  #checkov:skip=CKV_AWS_286:"Required permissions for ECS task operations"
  #checkov:skip=CKV_AWS_287:"Required permissions for ECS task operations"
  #checkov:skip=CKV2_AWS_40:"Broad IAM permissions required for ECS task functionality"
  name = "task-${var.networking[0].application}"
  role = aws_iam_role.app_task.id

  policy = <<-EOF
  {
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ecr:*",
          "iam:*",
          "ec2:*"
        ],
       "Resource": "*"
     }
   ]
  }
  EOF
}


resource "aws_security_group" "ecs_service" {
  #checkov:skip=CKV_AWS_382:"Required for ECS tasks to access external services"
  #checkov:skip=CKV_AWS_23:"Security group for ECS service"
  #checkov:skip=CKV2_AWS_5:"Security group is attached to the tribunals load balancer"
  name_prefix = "ecs-service-sg-"
  vpc_id      = data.aws_vpc.shared.id
  description = "Security group for ECS service"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    description     = "Allow traffic on port 80 from load balancer"
    security_groups = [aws_security_group.tribunals_lb_sc.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

resource "aws_security_group" "ecs_service_sftp" {
  #checkov:skip=CKV_AWS_382:"Required for SFTP tasks to access external services"
  #checkov:skip=CKV_AWS_23:"Security group for ECS SFTP service"
  #checkov:skip=CKV2_AWS_5:"Security group is attached to the tribunals load balancer"
  name_prefix = "ecs-service-sg-sftp-"
  vpc_id      = data.aws_vpc.shared.id
  description = "Security group for ECS SFTP service"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "Allow traffic on port 22 from network load balancer"
    security_groups = [
      aws_security_group.tribunals_lb_sc_sftp.id
    ]
  }

  ingress {
    from_port   = 10022
    to_port     = 10022
    protocol    = "tcp"
    description = "Allow traffic on port 10022 from sftp network load balancers"
    security_groups = [
      aws_security_group.tribunals_lb_sc_sftp.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}
