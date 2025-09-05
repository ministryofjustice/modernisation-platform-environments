
resource "aws_iam_role" "scheduler_invoke_role" {
  name = "scheduler-invoke-cwa-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "scheduler.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-scheduler-invoke-cwa-sfn-role"
    }
  )
}

resource "aws_iam_policy" "scheduler_invoke_sfn" {
  name = "scheduler-invoke-sfn-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "states:StartExecution",
      Resource = "${aws_sfn_state_machine.sfn_state_machine.arn}"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_invoke_sfn_attachment" {
  role       = aws_iam_role.scheduler_invoke_role.name
  policy_arn = aws_iam_policy.scheduler_invoke_sfn.arn
}
