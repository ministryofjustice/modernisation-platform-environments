output "aws_kms_key_oracle_ec2_arn" {
  description = "aws_kms_key oracle_ec2 arn"
  value       = aws_kms_key.oracle_ec2.arn
}

output "aws_kms_key_oracle_ec2_key_id" {
  description = "aws_kms_key oracle_ec2 key_id"
  value       = aws_kms_key.oracle_ec2.key_id
}

#

output "aws_kms_alias_oracle_ec2_alias_arn" {
  description = "aws_kms_alias oracle_ec2_alias arn"
  value       = aws_kms_alias.oracle_ec2_alias.arn
}

output "aws_kms_alias_oracle_ec2_alias_target_key_arn" {
  description = "aws_kms_alias oracle_ec2_alias target_key_arn"
  value       = aws_kms_alias.oracle_ec2_alias.target_key_arn
}
