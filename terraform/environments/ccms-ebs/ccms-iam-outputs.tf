output "aws_iam_policy_ec2_ssm_policy_arn" {
  description = "aws_iam_policy ec2_ssm_policy arn"
  value       = aws_iam_policy.ec2_ssm_policy.arn
}

output "aws_iam_policy_ec2_ssm_policy_policy" {
  description = "aws_iam_policy ec2_ssm_policy policy"
  value       = aws_iam_policy.ec2_ssm_policy.policy
}

#

output "aws_iam_role_role_stsassume_oracle_base_arn" {
  description = "aws_iam_role role_stsassume_oracle_base arn"
  value       = aws_iam_role.role_stsassume_oracle_base.arn
}

output "aws_iam_role_role_stsassume_oracle_base_name" {
  description = "aws_iam_role role_stsassume_oracle_base name"
  value       = aws_iam_role.role_stsassume_oracle_base.name
}

#

output "aws_iam_instance_profile_iam_instace_profile_ccms_base_arn" {
  description = "aws_iam_instance_profile iam_instace_profile_ccms_base arn"
  value       = aws_iam_instance_profile.iam_instace_profile_ccms_base.arn
}

output "aws_iam_instance_profile_iam_instace_profile_ccms_base_id" {
  description = "aws_iam_instance_profile iam_instace_profile_ccms_base id"
  value       = aws_iam_instance_profile.iam_instace_profile_ccms_base.id
}

#

output "aws_iam_policy_cw_logging_policy_arn" {
  description = "aws_iam_policy cw_logging_policy arn"
  value       = aws_iam_policy.cw_logging_policy.arn
}

output "aws_iam_policy_cw_logging_policy_policy" {
  description = "aws_iam_policy cw_logging_policy policy"
  value       = aws_iam_policy.cw_logging_policy.policy
}

#

output "aws_iam_policy_rman_to_s3_arn" {
  description = "aws_iam_policy rman_to_s3 arn"
  value       = aws_iam_policy.rman_to_s3.arn
}

output "aws_iam_policy_rman_to_s3_policy" {
  description = "aws_iam_policy rman_to_s3 policy"
  value       = aws_iam_policy.rman_to_s3.policy
}

output "aws_iam_policy_oracle_licensing_arn" {
  description = "aws_iam_policy oracle_licensing arn"
  value       = aws_iam_policy.oracle_licensing.arn
}

output "aws_iam_policy_oracle_licensing_policy" {
  description = "aws_iam_policy oracle_licensing policy"
  value       = aws_iam_policy.oracle_licensing.policy
}
