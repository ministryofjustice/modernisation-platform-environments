output "aws_instance_ec2_ebsapps_arn" {
  description = "aws_instance ec2_ebsapps arn arn"
  value       = aws_instance.ec2_ebsapps[*].arn
}

output "aws_instance_ec2_ebsapps_private_dns" {
  description = "aws_instance ec2_ebsapps arn private_dns"
  value       = aws_instance.ec2_ebsapps[*].private_dns
}

output "aws_instance_ec2_ebsapps_private_ip" {
  description = "aws_instance ec2_ebsapps arn private_ip"
  value       = aws_instance.ec2_ebsapps[*].private_ip
}

#

output "aws_ebs_volume_stage_arn" {
  description = "aws_ebs_volume stage arn"
  value       = aws_ebs_volume.stage[*].arn
}

#

output "aws_volume_attachment_stage_att_device_name" {
  description = "aws_volume_attachment stage_att device_name"
  value       = aws_volume_attachment.stage_att[*].device_name
}

output "aws_volume_attachment_stage_att_instance_id" {
  description = "aws_volume_attachment stage_att instance_id"
  value       = aws_volume_attachment.stage_att[*].instance_id
}

output "aws_volume_attachment_stage_att_volume_id" {
  description = "aws_volume_attachment stage_att volume_id"
  value       = aws_volume_attachment.stage_att[*].volume_id
}
