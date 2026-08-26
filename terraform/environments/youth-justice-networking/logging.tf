# Configure log groups for CloudWatch

locals {
  log_groups = {
    "yjaf-juniper/OSSecurity" = 400
    "yjaf-juniper/OSSystem"   = 400
    "yjaf-juniper/clamav"     = 400
    "yjaf-juniper/rsyslog"    = 400
  }
}

resource "aws_cloudwatch_log_group" "yjaf_logs" {
  for_each          = local.log_groups
  name              = each.key
  retention_in_days = each.value
}

resource "aws_iam_role" "yjb_juniper_ec2_role" {
  name = "YJBJuniperEC2Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# CReate instance profile for syslog server

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.yjb_juniper_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_attach" {
  role       = aws_iam_role.yjb_juniper_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "yjb_juniper_instance_profile" {
  name = "YJBJuniperInstanceProfile"
  role = aws_iam_role.yjb_juniper_ec2_role.name
}
