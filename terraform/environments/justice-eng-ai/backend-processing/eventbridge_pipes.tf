# Starts the post-approval workflow when an event is inserted with JobStage
# "control_plane" and JobStatus "approved". EventBridge Pipes reads the DynamoDB stream
# directly, so no Lambda is needed.

resource "aws_sqs_queue" "build_approval_pipe_dlq" {
  name                    = "${local.application_name}-build-approval-pipe-dlq"
  sqs_managed_sse_enabled = true
  tags                    = local.tags
}

data "aws_iam_policy_document" "build_approval_pipe_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["pipes.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "build_approval_pipe" {
  name               = "${local.application_name}-build-approval-pipe"
  assume_role_policy = data.aws_iam_policy_document.build_approval_pipe_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "build_approval_pipe" {
  statement {
    sid    = "ReadBuildReviewStream"
    effect = "Allow"
    actions = [
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams",
    ]
    resources = [aws_dynamodb_table.build_review.stream_arn]
  }

  statement {
    sid       = "StartPostApprovalWorkflow"
    effect    = "Allow"
    actions   = ["states:StartExecution"]
    resources = [module.step_functions_post_approval.arn]
  }

  statement {
    sid       = "SendFailedEventsToDeadLetterQueue"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.build_approval_pipe_dlq.arn]
  }
}

resource "aws_iam_role_policy" "build_approval_pipe" {
  name   = "${local.application_name}-build-approval-pipe"
  role   = aws_iam_role.build_approval_pipe.id
  policy = data.aws_iam_policy_document.build_approval_pipe.json
}

resource "aws_pipes_pipe" "build_approval" {
  name     = "${local.application_name}-build-approval"
  role_arn = aws_iam_role.build_approval_pipe.arn
  source   = aws_dynamodb_table.build_review.stream_arn
  target   = module.step_functions_post_approval.arn

  source_parameters {
    filter_criteria {
      filter {
        pattern = jsonencode({
          eventName = ["INSERT"]
          dynamodb = {
            NewImage = {
              JobStage  = { S = ["control_plane"] }
              JobStatus = { S = ["approved"] }
            }
          }
        })
      }
    }

    dynamodb_stream_parameters {
      starting_position             = "LATEST"
      batch_size                    = 1
      maximum_retry_attempts        = 3
      maximum_record_age_in_seconds = 86400
      dead_letter_config {
        arn = aws_sqs_queue.build_approval_pipe_dlq.arn
      }
    }
  }

  target_parameters {
    # Same shape as the control plane output, so the post-approval workflow
    # starts exactly as it would after an automatic approval.
    input_template = jsonencode({ for name in local.build_review_attributes : name => "<$.dynamodb.NewImage.${name}.S>" })

    step_function_state_machine_parameters {
      invocation_type = "FIRE_AND_FORGET"
    }
  }

  tags = local.tags

  depends_on = [aws_iam_role_policy.build_approval_pipe]
}
