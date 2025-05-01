resource "aws_fis_experiment_template" "az_power_interrupt" {
  description = "Simulate AZ power outage in eu-west-2b"
  role_arn    = "arn:aws:iam::053556912568:role/service-role/AWSFISIAMRole-Preprod"

  stop_condition {
    source = "none"
  }

  log_configuration {
    cloudwatch_logs_configuration {
      log_group_arn = "arn:aws:logs:eu-west-2:053556912568:log-group:AWS-FIS-Logs"
    }
    log_schema_version = 1
  }

  target {
    name           = "ASG"
    resource_type  = "aws:ec2:autoscaling-group"
    selection_mode = "ALL"
    resource_tag {
      key   = "AzImpairmentPower"
      value = "IceAsg"
    }
  }

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

  tags = {
    Name = "FIS AZ Power Outage Simulation"
  }
}
