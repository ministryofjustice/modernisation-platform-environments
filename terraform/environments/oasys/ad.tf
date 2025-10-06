resource "aws_security_group" "mis_ad_dns_resolver_security_group" {
  dynamic "ip_address" {
    for_each = var.account_config.private_subnet_ids
    content {
      subnet_id = ip_address.value
    }
  }
}

variable "instance_profile_policies" {
  type        = string /*list(string)*/
  description = "A list of managed IAM policy document ARNs to be attached to the database instance profile"
}

variable "default_policy_arn" {
  description = "Default policy ARN to attach"
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "this" {
  
policy = {[var.default_policy_arn], (var.instance_profile_policies[0])}
  

  role       = aws_iam_role.this.name
  policy_arn = each.value
}