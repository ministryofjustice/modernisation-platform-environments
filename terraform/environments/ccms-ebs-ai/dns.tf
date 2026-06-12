# DNS Configuration

# DNS for ccms-ebs-db-ai-1
resource "aws_route53_record" "record_ccms_ebs_db_ai_1" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ccms-ebs-db-ai-1"
  type     = "A"
  ttl     = 300
  records = [local.application_data.accounts[local.environment].ccms-ebs-db-ai-1-ip]
}

# DNS for ccms-ebs-db-ai-2
resource "aws_route53_record" "record_ccms_ebs_db_ai_2" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "ccms-ebs-db-ai-2"
  type     = "A"
  ttl     = 300
  records = [local.application_data.accounts[local.environment].ccms-ebs-db-ai-2-ip]
}