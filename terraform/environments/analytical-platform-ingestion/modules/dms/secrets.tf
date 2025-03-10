# Create secret resource in AWS Secrets Manager
# #trivy:ignore:AVD-AWS-0098: The secret is encrypted using an AWS managed key
resource "aws_secretsmanager_secret" "dms_source" {
  #checkov:skip=CKV_AWS_149: The secret is encrypted using an AWS managed key
  name = "${var.db}-source-${var.environment}"
}
