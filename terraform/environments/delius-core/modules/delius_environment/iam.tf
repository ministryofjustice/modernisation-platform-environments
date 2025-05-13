# # Role that enables cross-account (delius-alfresco) reading of resources
# data "aws_iam_policy_document" "alfresco_read_only" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${var.alfresco_account_ids[var.env_name]}:root"]
#     }
#   }
# }

# resource "aws_iam_role" "alfresco_read_only" {
#   name               = "${var.env_name}-alfresco-read-only"
#   assume_role_policy = data.aws_iam_policy_document.alfresco_read_only.json
#   tags               = var.tags
# }

# resource "aws_iam_role_policy_attachment" "readonly_access" {
#   role       = aws_iam_role.alfresco_read_only.name
#   policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
# }