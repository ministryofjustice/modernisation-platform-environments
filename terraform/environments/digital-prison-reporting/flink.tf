resource "aws_iam_role" "flink_role" {
  name = "dpr-flink-spike-execution-role-development"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Principal = {
          "Service" = "kinesisanalytics.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "flink_spike_additional_policy" {
  name = "flink_spike_additional_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:Get*",
          "s3:List*",
          "s3:Put*",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::dpr-working-development",
          "arn:aws:s3:::dpr-working-development/*",
          "arn:aws:s3:::flink-demo-771283872747-eu-west-2-1713861000297-bucket",
          "arn:aws:s3:::flink-demo-771283872747-eu-west-2-1713861000297-bucket/*",
          "arn:aws:s3:::dpr-artifact-store-development",
          "arn:aws:s3:::dpr-artifact-store-development/*"
        ]
      },
      {
        "Action": "cloudwatch:PutMetricData",
        "Resource": "*",
        "Effect": "Allow"
      },
      {
        "Action": [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        "Resource": "*",
        "Effect": "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "flink_spike_policy_attachment" {
  role       = aws_iam_role.flink_role.name
  policy_arn = aws_iam_policy.flink_spike_additional_policy.arn
}

resource "aws_iam_role_policy_attachment" "flink_spike_cloudwatch_full_access_policy_attachment" {
  role       = aws_iam_role.flink_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "flink_spike_vpc_full_access_policy_attachment" {
  role       = aws_iam_role.flink_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_cloudwatch_log_group" "flink_log_group" {
  name              = "/aws/kinesis-analytics/flink-spike-app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "flink_log_stream" {
  name           = "flink-spike-app"
  log_group_name = aws_cloudwatch_log_group.flink_log_group.name
}

resource "aws_kinesisanalyticsv2_application" "flink_spike_app" {
  name                   = "flink-spike"
  runtime_environment    = "FLINK-1_18"
  service_execution_role = aws_iam_role.flink_role.arn

  application_configuration {
    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = "arn:aws:s3:::flink-demo-771283872747-eu-west-2-1713861000297-bucket"
          file_key   = "flink-spike-0.1-SNAPSHOT-all.jar"
        }
      }

      code_content_type = "ZIPFILE"
    }

    flink_application_configuration {
      checkpoint_configuration {
        configuration_type = "DEFAULT"
      }

      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = "INFO"
        metrics_level      = "APPLICATION"
      }

      parallelism_configuration {
        auto_scaling_enabled = false
        configuration_type   = "CUSTOM"
        parallelism          = 1
        parallelism_per_kpu  = 1
      }
    }

    vpc_configuration {
      security_group_ids = [aws_security_group.flink_allow_outbound.id]
      subnet_ids         = [data.aws_subnet.private_subnets_a.id]
    }
  }

  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.flink_log_stream.arn
  }
}

resource "aws_security_group" "flink_allow_outbound" {
  name        = "flink_allow_outbound"
  description = "Allow all outbound traffic from the Flink application"
  vpc_id      = data.aws_vpc.shared.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}