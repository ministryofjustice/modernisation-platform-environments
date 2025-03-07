output "instance_ami" {
  value = aws_instance.tableau.ami
}

output "instance_arn" {
  value = aws_instance.tableau.arn
}

output "tableau_sg_id" {
  value = module.tableau_sg.security_group_id
}

output "datedog_secret_arn" {
  value = data.aws_secretsmanager_secret.datadog-api-key.id
}
