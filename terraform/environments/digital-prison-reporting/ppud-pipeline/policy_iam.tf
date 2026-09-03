# S3 Read Write Policy
data "aws_iam_role" "dataapi_cross_role" {
  name = "dpr-data-api-cross-account-role"
}

resource "aws_iam_policy" "s3_read_write_ppud_policy" {
  name = "${local.environment}_${local.short_name}_s3_read_write_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowUserToSeeBucketListInTheConsole",
        "Action" : ["s3:ListAllMyBuckets", "s3:GetBucketLocation"],
        "Effect" : "Allow",
        "Resource" : ["arn:aws:s3:::*"]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
        ],
        "Resource" : [
          "arn:aws:s3:::${local.short_name}-*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*Object",
        ],
        "Resource" : [
          "arn:aws:s3:::${local.short_name}-*/*",
          "arn:aws:s3:::${local.short_name}-*",
        ]
      }
    ]
  })
}

# S3 Read Write PPUD Policy Attachement
resource "aws_iam_role_policy_attachment" "s3_read_write_ppud" {
  #checkov:skip=CKV_AWS_274:Disallow IAM roles, users, and groups from using the AWS AdministratorAccess policy

  role       = data.aws_iam_role.dataapi_cross_role.name
  policy_arn = aws_iam_policy.s3_read_write_ppud_policy.arn
}