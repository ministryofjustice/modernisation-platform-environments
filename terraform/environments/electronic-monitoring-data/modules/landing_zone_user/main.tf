data "aws_iam_policy_document" "transfer_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#------------------------------------------------------------------------------
# AWS transfer user
#
# Create user profile that has put access for specified landing zone bucket.
#------------------------------------------------------------------------------

resource "aws_transfer_user" "this" {
  server_id = var.transfer_server.id
  user_name = var.user_name
  role      = aws_iam_role.this_transfer_user.arn

  home_directory = "/${var.landing_bucket.id}/"

  tags = merge(
    var.local_tags,
    {
      supplier = var.user_name,
    },
  )
}

#------------------------------------------------------------------------------
# AWS transfer user IAM role
#-------------------------------------------------------------------------------

resource "aws_iam_role" "this_transfer_user" {
  name               = "${var.supplier}-${var.user_name}-transfer-user-iam-role"
  assume_role_policy = data.aws_iam_policy_document.transfer_assume_role.json
}

resource "aws_iam_role_policy" "this_transfer_user" {
  name   = "${var.user_name}-transfer-user-iam-policy"
  role   = aws_iam_role.this_transfer_user.id
  policy = data.aws_iam_policy_document.this_transfer_user.json
}

resource "aws_iam_role_policy_attachment" "this_transfer_user" {
  role       = aws_iam_role.this_transfer_user.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
}

data "aws_iam_policy_document" "this_transfer_user" {
  statement {
    sid       = "AllowListAccessToLandingS3"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.landing_bucket.arn]
  }
  statement {
    sid       = "AllowPutAccessToLandingS3"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${var.landing_bucket.arn}/*"]
  }
}

#------------------------------------------------------------------------------
# AWS transfer ssh key
#
# Set the public ssh key for the user profile to access SFTP server.
#------------------------------------------------------------------------------

resource "aws_transfer_ssh_key" "this" {
  server_id = var.transfer_server.id
  user_name = aws_transfer_user.this.user_name

  for_each = { for ssh_key in var.ssh_keys : ssh_key => ssh_key }
  body     = each.key
}
