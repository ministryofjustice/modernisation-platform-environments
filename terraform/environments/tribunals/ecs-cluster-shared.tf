resource "aws_ecs_cluster" "tribunals_cluster" {
  name = "tribunals-all-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "tribunalsFamily_logs" {
  name = "/ecs/tribunalsFamily"
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
  name_prefix = "ecs-service-sg-"
  vpc_id      = data.aws_vpc.shared.id

  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   description = "Allow traffic on port 80 from load balancer"
  #   security_groups = [aws_security_group.tribunals_lb_sc.id]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_service_sftp" {
  name_prefix = "ecs-service-sg-sftp-"
  vpc_id      = data.aws_vpc.shared.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "Allow traffic on port 22 from network load balancer"
    security_groups = [
      module.charity_tribunal_decisions.tribunals_lb_sc_id_sftp,
      module.claims_management_decisions.tribunals_lb_sc_id_sftp,
      module.consumer_credit_appeals.tribunals_lb_sc_id_sftp,
      module.estate_agent_appeals.tribunals_lb_sc_id_sftp,
      module.primary_health_lists.tribunals_lb_sc_id_sftp,
      module.siac.tribunals_lb_sc_id_sftp,
      module.sscs_venue_pages.tribunals_lb_sc_id_sftp,
      module.tax_chancery_decisions.tribunals_lb_sc_id_sftp,
      module.tax_tribunal_decisions.tribunals_lb_sc_id_sftp,
      module.ftp_admin_appeals.tribunals_lb_sc_id_sftp
    ]
  }

  ingress {
    from_port   = 10022
    to_port     = 10022
    protocol    = "tcp"
    description = "Allow traffic on port 10022 from sftp network load balancers"
    security_groups = [
      module.charity_tribunal_decisions.tribunals_lb_sc_id_sftp,
      module.claims_management_decisions.tribunals_lb_sc_id_sftp,
      module.consumer_credit_appeals.tribunals_lb_sc_id_sftp,
      module.estate_agent_appeals.tribunals_lb_sc_id_sftp,
      module.primary_health_lists.tribunals_lb_sc_id_sftp,
      module.siac.tribunals_lb_sc_id_sftp,
      module.sscs_venue_pages.tribunals_lb_sc_id_sftp,
      module.tax_chancery_decisions.tribunals_lb_sc_id_sftp,
      module.tax_tribunal_decisions.tribunals_lb_sc_id_sftp,
      module.ftp_admin_appeals.tribunals_lb_sc_id_sftp
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "tribunals-ecr-repo" {
  name         = "tribunals-ecr-repo"
  force_delete = true
}
