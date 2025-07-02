variable "retention_in_days" {
  type    = number
  default = 365
}

variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/transfer/cafm-migration"
  retention_in_days = var.retention_in_days
  kms_key_id        = aws_kms_key.shared.arn
  tags              = var.tags
}
