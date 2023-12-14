resource "aws_ecr_respository" "ad-clean-up" {
    name = "ad-clean-up"
}

resource "aws_cloudwatch_event_rule" "instance-state" {
    name = "InstanceState"
    description = "Trigger AdCleanUp Lambda function"
    event_pattern = jsonencode({
      "source": ["aws.ec2"],
      "detail-type": ["EC2 Instance State-change Notification"],
      "detail": {
        "state": ["terminated", "stopped"]
        }
    })
}

resource "aws_cloud_watch_event_target" "lambda" {
    rule = aws_cloudwatch_event_rule.instance-state.InstanceState
    arn = module.ad-clean-up-lambda.arn # TODO
}

module "ad-clean-up-lambda" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function" # ref for V2.1
  application_name = "AdCleanUp"
  description = "Lambda to remove corresponding computer object from Active Directory upon server termination"
  funtion_name = "ad-clean-up-${local.environment}"
  role_name = "ad-lambda-role-${local.environment}"
 
  policy_json = jsonencode({
    Version = "2012-10-17",
    Statement = [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface",
                "ec2:AssignPrivateIpAddresses",
                "ec2:UnassignPrivateIpAddresses",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "*"
        }
    ]
  })
  
  create_role = true
  allowed_triggers = {

    AllowExecutionFromCloudWatch = {
      action     = "lambda:InvokeFunction"
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.instance-state.arn
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "ad-clean-up-lambda"
    },
  )

}