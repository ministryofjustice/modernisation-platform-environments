#####################################
### Publisher Role for SNS Topic ###
#####################################
resource "aws_iam_role" "publisher_role" {
  name = "SNS_Publisher_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            aws_iam_role.cwa_extract_lambda_role.arn
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-sns-publisher-role"
    }
  )
}

resource "aws_iam_policy" "publisher_role_policy" {
  name = "SNS_Publisher_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.priority_p1.arn,
          aws_sns_topic.provider_banks.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "publisher_role_attach" {
  role       = aws_iam_role.publisher_role.name
  policy_arn = aws_iam_policy.publisher_role_policy.arn
}

#####################################
### Subscriber Role for SNS Topic ###
#####################################
resource "aws_iam_role" "subscriber_role" {
  name = "SNS_Subscriber_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-sns-subscriber-role"
    }
  )
}

resource "aws_iam_policy" "subscriber_policy" {
  name = "SNS_Subscriber_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Subscribe"
        ]
        Resource = [
          aws_sns_topic.priority_p1.arn,
          aws_sns_topic.provider_banks.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "subscriber_attach" {
  role       = aws_iam_role.subscriber_role.name
  policy_arn = aws_iam_policy.subscriber_policy.arn
}


#####################################
### Admin Role for SNS Topic ###
#####################################
resource "aws_iam_role" "admin_role" {
  name = "SNS_Admin_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-sns-admin-role"
    }
  )
}

resource "aws_iam_policy" "admin_policy" {
  name = "SNS_Admin_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sns:*"
        Resource = [
          aws_sns_topic.priority_p1.arn,
          aws_sns_topic.provider_banks.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.admin_role.name
  policy_arn = aws_iam_policy.admin_policy.arn
}

#####################################
### Logging Role for SNS Topics ###
#####################################

resource "aws_iam_role" "sns_feedback" {
  name = "sns-feedback-logging"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-sns-logging-role"
    }
  )
}

resource "aws_iam_policy" "sns_feedback_logging" {
  name        = "sns-feedback-logging-policy"
  description = "Allows SNS to log delivery status to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sns_feedback_attach" {
  role       = aws_iam_role.sns_feedback.name
  policy_arn = aws_iam_policy.sns_feedback_logging.arn
}