resource "aws_fis_experiment_template" "az_power_interrupt" {
  description = "Simulate AZ power outage in eu-west-2b"
  role_arn    = aws_iam_role.fis_role.arn

  stop_condition {
    source = "none"
  }

  log_configuration {
    cloudwatch_logs_configuration {
      log_group_arn = "${aws_cloudwatch_log_group.fis_logs.arn}:*"
    }
    log_schema_version = 1
  }

  # Targets
  target {
    name           = "ASG"
    resource_type  = "aws:ec2:autoscaling-group"
    selection_mode = "ALL"
    resource_tag {
      key   = "AzImpairmentPower"
      value = "IceAsg"
    }
  }

  target {
    name           = "ASGInstances"
    resource_type  = "aws:ec2:instance"
    selection_mode = "ALL"
    resource_tag {
      key   = "AzImpairmentPower"
      value = "IceAsg"
    }
    filter {
      path   = "State.Name"
      values = ["running"]
    }
    filter {
      path   = "Placement.AvailabilityZone"
      values = ["eu-west-2b"]
    }
  }

  target {
    name           = "RDSCluster"
    resource_type  = "aws:rds:cluster"
    selection_mode = "ALL"
    resource_tag {
      key   = "AzImpairmentPower"
      value = "DisruptRds"
    }
  }

  # Actions
  action {
    name      = "Pause-ASG-Scaling"
    action_id = "aws:ec2:asg-insufficient-instance-capacity-error"

    target {
      key   = "AutoScalingGroups"
      value = "ASG"
    }

    parameter {
      key   = "availabilityZoneIdentifiers"
      value = "euw2-az3"
    }

    parameter {
      key   = "duration"
      value = "PT1H"
    }

    parameter {
      key   = "percentage"
      value = "100"
    }
  }

  action {
    name      = "Stop-ASG-Instances"
    action_id = "aws:ec2:stop-instances"

    target {
      key   = "Instances"
      value = "ASGInstances"
    }

    parameter {
      key   = "completeIfInstancesTerminated"
      value = "true"
    }

    parameter {
      key   = "startInstancesAfterDuration"
      value = "PT1H"
    }
  }


  action {
    name      = "Failover-RDS"
    action_id = "aws:rds:failover-db-cluster"

    target {
      key   = "Clusters"
      value = "RDSCluster"
    }
  }

  tags = {
    Name = "FIS AZ Power Outage Simulation"
  }
}


resource "aws_iam_role" "fis_role" {
  name = "AWSFISIAMRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "fis.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "fis_asg_custom_policy" {
  name = "FIS-ASG-Custom-Policy"
  role = aws_iam_role.fis_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowInjectAPI",
        Effect = "Allow",
        Action = [
          "ec2:InjectApiError"
        ],
        Resource = ["*"],
        Condition = {
          "ForAnyValue:StringEquals" = {
            "ec2:FisActionId" = [
              "aws:ec2:api-insufficient-instance-capacity-error",
              "aws:ec2:asg-insufficient-instance-capacity-error"
            ]
          }
        }
      },
      {
        Sid    = "DescribeAsg",
        Effect = "Allow",
        Action = [
          "autoscaling:DescribeAutoScalingGroups"
        ],
        Resource = ["*"]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "fis_ec2_policy" {
  role       = aws_iam_role.fis_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorEC2Access"
}

resource "aws_iam_role_policy_attachment" "fis_networkaccess_policy" {
  role       = aws_iam_role.fis_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorNetworkAccess"
}

resource "aws_iam_role_policy_attachment" "fis_rds_policy" {
  role       = aws_iam_role.fis_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSFaultInjectionSimulatorRDSAccess"
}

resource "aws_iam_role_policy_attachment" "fis_cloudwatch_policy" {
  role       = aws_iam_role.fis_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccessV2"
}

resource "aws_cloudwatch_log_group" "fis_logs" {
  name              = "AWS-FIS-Logs"
  retention_in_days = 400
  kms_key_id        = module.kms.key_arn
}
