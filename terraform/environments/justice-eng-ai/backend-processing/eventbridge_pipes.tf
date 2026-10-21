# Starts a target state machine when an event with a matching JobStage and JobStatus is
# inserted into the build events table. EventBridge Pipes reads the DynamoDB stream
# directly, so no Lambda is needed. Add an entry to local.pipes for each new trigger;
# the target receives the stream record (an array holding one record) as its input.
locals {
  pipes = [
    {
      name       = "build-approved"
      event_name = "INSERT"
      job_stage  = "control_plane"
      job_status = "approved"
      target_arn = module.step_functions_control_plane.resume_arn
    },
  ]
}

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
    sid       = "StartTargetWorkflows"
    effect    = "Allow"
    actions   = ["states:StartExecution"]
    resources = distinct(local.pipes[*].target_arn)
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

resource "aws_pipes_pipe" "build_events" {
  for_each = { for pipe in local.pipes : pipe.name => pipe }

  name     = "${local.application_name}-${each.key}"
  role_arn = aws_iam_role.build_approval_pipe.arn
  source   = aws_dynamodb_table.build_review.stream_arn
  target   = each.value.target_arn

  source_parameters {
    filter_criteria {
      filter {
        pattern = jsonencode({
          eventName = [each.value.event_name]
          dynamodb = {
            NewImage = {
              JobStage  = { S = [each.value.job_stage] }
              JobStatus = { S = [each.value.job_status] }
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
    step_function_state_machine_parameters {
      invocation_type = "FIRE_AND_FORGET"
    }
  }

  tags = local.tags

  depends_on = [aws_iam_role_policy.build_approval_pipe]
}
