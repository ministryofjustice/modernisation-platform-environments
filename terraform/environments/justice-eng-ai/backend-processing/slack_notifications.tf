# Job-completion messages for the team Slack channel. The root state machine
# publishes to this topic (notify_slack step) and AWS Chatbot delivers it.
# Runtime errors are covered separately by CloudWatch alarms.
locals {
  slack_channel_id = local.application_data.accounts[local.environment].slack_channel_id
}

data "aws_iam_policy_document" "kms_job_completion" {
  # checkov:skip=CKV_AWS_109: Key policy is attached to the key itself; account root delegates access to IAM
  # checkov:skip=CKV_AWS_111: Key policy is attached to the key itself; account root delegates access to IAM
  # checkov:skip=CKV_AWS_356: Policy is attached to a resource
  statement {
    sid    = "AllowAccountAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "job_completion" {
  description             = "Encrypts the ${local.application_name} job completion SNS topic"
  policy                  = data.aws_iam_policy_document.kms_job_completion.json
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = local.tags
}

resource "aws_kms_alias" "job_completion" {
  name          = "alias/${local.application_name}-job-completion"
  target_key_id = aws_kms_key.job_completion.id
}

resource "aws_sns_topic" "job_completion" {
  name              = "${local.application_name}-job-completion"
  kms_master_key_id = aws_kms_key.job_completion.id
  tags              = local.tags
}

# The Slack client must be set up manually in the account first (see the module README).
# Nothing is created until a channel ID is set for the environment.
module "job_completion_chatbot" {
  count  = local.slack_channel_id == "" ? 0 : 1
  source = "github.com/ministryofjustice/modernisation-platform-terraform-aws-chatbot?ref=0ec33c7bfde5649af3c23d0834ea85c849edf3ac" # v3.0.0

  slack_channel_id = local.slack_channel_id
  sns_topic_arns   = [aws_sns_topic.job_completion.arn]
  application_name = local.application_name
  tags             = local.tags
}

# The Chatbot role must decrypt messages from the encrypted topic.
resource "aws_iam_role_policy" "job_completion_chatbot_decrypt" {
  count = local.slack_channel_id == "" ? 0 : 1

  name = "${local.application_name}-job-completion-decrypt"
  # v3.0.0 outputs the role ARN rather than the role object
  role = element(split("/", module.job_completion_chatbot[0].aws_chatbot_iam_role), -1)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DecryptJobCompletionTopic"
      Effect   = "Allow"
      Action   = ["kms:Decrypt"]
      Resource = [aws_kms_key.job_completion.arn]
    }]
  })
}
