#####################################
### Publisher Role for SNS Topic ###
#####################################
resource "aws_iam_role" "publisher_role" {
  name = "SNS Publisher role"

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
}

resource "aws_iam_policy" "publisher_role_policy" {
  name = "SNS Publisherpolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.priority_p1.arn
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
  name = "SNS Subscriber role"

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
}

resource "aws_iam_policy" "subscriber_policy" {
  name = "SNS Subscriber policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Subscribe"
        ]
        Resource = aws_sns_topic.priority_p1.arn
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
  name = "SNS Admin role"

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
}

resource "aws_iam_policy" "admin_policy" {
  name = "SNS Admin policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sns:*"
        Resource = aws_sns_topic.priority_p1.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "admin_attach" {
  role       = aws_iam_role.admin_role.name
  policy_arn = aws_iam_policy.admin_policy.arn
}