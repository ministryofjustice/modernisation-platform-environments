data "aws_iam_role" "srt_access" {
  name = "AWSSRTSupport"
}

resource "aws_shield_drt_access_role_arn_association" "srt_access" {
  role_arn = data.aws_iam_role.srt_access.arn
}
