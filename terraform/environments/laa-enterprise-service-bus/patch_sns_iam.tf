#####################################
### Publisher Role for SNS Topic ###
#####################################
resource "aws_iam_role" "patch_publisher_role" {
  count = local.environment == "test" ? 1 : 0
  name  = "PATCH_SNS_Publisher_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            aws_iam_role.patch_cwa_extract_lambda_role[0].arn
          ]
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.tags,
    {
      Name = "${local.application_name_short}-${local.environment}-patch-sns-publisher-role"
    }
  )
}

resource "aws_iam_policy" "patch_publisher_role_policy" {
  count = local.environment == "test" ? 1 : 0
  name  = "PATCH_SNS_Publisher_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.patch_priority_p1[0].arn,
          aws_sns_topic.patch_provider_banks[0].arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "patch_publisher_role_attach" {
  count      = local.environment == "test" ? 1 : 0
  role       = aws_iam_role.patch_publisher_role[0].name
  policy_arn = aws_iam_policy.patch_publisher_role_policy[0].arn
}

#####################################
### Subscriber Role for SNS Topic ###
#####################################
resource "aws_iam_role" "patch_subscriber_role" {
  count = local.environment == "test" ? 1 : 0
  name  = "PATCH_SNS_Subscriber_role"

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
      Name = "${local.application_name_short}-${local.environment}-patch-sns-subscriber-role"
    }
  )
}

resource "aws_iam_policy" "patch_subscriber_policy" {
  count = local.environment == "test" ? 1 : 0
  name  = "PATCH_SNS_Subscriber_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Subscribe"
        ]
        Resource = [
          aws_sns_topic.patch_priority_p1[0].arn,
          aws_sns_topic.patch_provider_banks[0].arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "patch_subscriber_attach" {
  count      = local.environment == "test" ? 1 : 0
  role       = aws_iam_role.patch_subscriber_role[0].name
  policy_arn = aws_iam_policy.patch_subscriber_policy[0].arn
}


#####################################
### Admin Role for SNS Topic ###
#####################################
resource "aws_iam_role" "patch_admin_role" {
  count = local.environment == "test" ? 1 : 0
  name  = "PATCH_SNS_Admin_role"

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
      Name = "${local.application_name_short}-${local.environment}-patch-sns-admin-role"
    }
  )
}

resource "aws_iam_policy" "patch_admin_policy" {
  count = local.environment == "test" ? 1 : 0
  name  = "PACTH_SNS_Admin_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sns:*"
        Resource = [
          aws_sns_topic.patch_priority_p1[0].arn,
          aws_sns_topic.patch_provider_banks[0].arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "patch_admin_attach" {
  count      = local.environment == "test" ? 1 : 0
  role       = aws_iam_role.patch_admin_role[0].name
  policy_arn = aws_iam_policy.patch_admin_policy[0].arn
}