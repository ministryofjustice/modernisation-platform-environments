#### This file can be used to store data specific to the member account ####

## AMI data blocks
data "aws_ami" "oracle_base_prereqs" {
  most_recent = true
  owners      = [local.application_data.accounts[local.environment].ami_owner]

  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].orace_base_prereqs_ami_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "oracle_db" {
  most_recent = true
  owners      = [local.application_data.accounts[local.environment].ami_owner]

  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].orace_db_ami_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "webgate" {
  most_recent = true
  owners      = [local.application_data.accounts[local.environment].ami_owner]

  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].webgate_ami_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "accessgate" {
  most_recent = true
  owners      = [local.application_data.accounts[local.environment].ami_owner]

  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].accessgate_ami_name]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

/*
data "aws_ami" "oracle_base_prereqs_verify" {
  most_recent = true
  owners      = [local.application_data.accounts[local.environment].ami_owner]

  filter {
    name   = "name"
    values = [local.application_data.accounts[local.environment].orace_base_prereqs_ami_name_verify]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
*/

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "SnsTopicId"
  statement {
    sid = "statement1"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    effect = "Allow"
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive"
    ]
    resources = [aws_sns_topic.cw_alerts.arn]
  }
}

data "aws_secretsmanager_secret" "support_email_account" {
  name = "support_email_account"
  depends_on = [
    aws_secretsmanager_secret.support_email_account
  ]
}

data "aws_secretsmanager_secret_version" "support_email_account" {
  secret_id = data.aws_secretsmanager_secret.support_email_account.id
  depends_on = [
    aws_secretsmanager_secret_version.support_email_account
  ]
}







data "aws_security_groups" "all_security_groups" {
  filter {
    name   = "tag:Name"
    values = ["*ccms*"]
  }
}
/*
output "security_group_ids" {
  value = data.aws_security_groups.all_security_groups.ids
}
*/