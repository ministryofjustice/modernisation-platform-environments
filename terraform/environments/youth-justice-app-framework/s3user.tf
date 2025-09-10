### Legacy S3 bucket user, to be replaced by iam role before full migration


resource "aws_iam_user" "s3" {
  #checkov:skip=CKV_AWS_273: Will be replaced by iam role
  name = "${local.project_name}-s3-access"

  tags = merge(local.tags, {
    Description = "${local.project_name}-s3-access"
  })
}

resource "aws_iam_access_key" "s3" {
  user = aws_iam_user.s3.name
}


resource "aws_secretsmanager_secret" "s3_user_secret" {
  #checkov:skip=CKV2_AWS_57:todo add rotation if needed
  name        = "${local.project_name}-s3-user"
  description = "key credentials for s3 user"
  kms_key_id  = module.kms.key_id
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "s3_user_secret" {
  secret_id = aws_secretsmanager_secret.s3_user_secret.id
  secret_string = jsonencode({
    username = aws_iam_access_key.s3.id,
    password = aws_iam_access_key.s3.secret
  })
}

## S3 user policy
resource "aws_iam_policy" "s3" {
  name        = "${local.project_name}-s3-access"
  description = "Policy for S3 user"
  policy = templatefile("${path.module}/iam_policies/s3_user_policy.json", {
    dal_buckets            = local.dal_buckets            #declared in ecs.tf
    dal_buckets_wildcarded = local.dal_buckets_wildcarded #declared in ecs.tf
  })
}

resource "aws_iam_user_policy_attachment" "s3_user_attachment" {
  #checkov:skip=CKV_AWS_40:change when user is updated to role
  user       = aws_iam_user.s3.name
  policy_arn = aws_iam_policy.s3.arn
}
