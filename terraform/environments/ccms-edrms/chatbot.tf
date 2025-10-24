# Chatbot Configuration for CCMS EDRMS Cloudwatch Alerts


module "template" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  slack_channel_id = data.aws_secretsmanager_secret_version.slack_channel_id.secret_string
  sns_topic_arns   = ["arn:aws:sns:eu-west-2:${local.environment_management.account_ids[terraform.workspace]}:cloudwatch-slack-alerts"]
  tags             = local.tags
  application_name = local.application_name

}
