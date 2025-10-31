#--Transfer Service IAM
resource "aws_iam_role" "transfer" {
  name               = "${var.app_name}-cashoffice-transfer"
  assume_role_policy = data.aws_iam_policy_document.transfer_assume_role.json
}

resource "aws_iam_policy" "transfer" {
  name        = "${var.app_name}-transfer"
  description = "${var.app_name}-transfer"
  policy      = data.aws_iam_policy_document.transfer.json
}

resource "aws_iam_role_policy_attachment" "transfer" {
  role       = aws_iam_role.transfer.name
  policy_arn = aws_iam_policy.transfer.arn
}

resource "aws_iam_role_policy_attachment" "transfer_logs" {
  role       = aws_iam_role.transfer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
}

#--S3 IAM
resource "aws_iam_role" "s3" {
  name               = "${var.app_name}-cashoffice-s3"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role.json
}

resource "aws_iam_policy" "s3" {
  name        = "${var.app_name}-cashoffice-s3"
  description = "${var.app_name}-cashoffice-s3"
  policy      = data.aws_iam_policy_document.s3.json
}

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.s3.name
  policy_arn = aws_iam_policy.s3.arn
}
