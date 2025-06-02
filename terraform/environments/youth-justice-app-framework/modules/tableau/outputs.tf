output "instance_ami" {
  value = aws_instance.tableau.ami
}

output "instance_arn" {
  value = aws_instance.tableau.arn
}

output "tableau_sg_id" {
  value = module.tableau_sg.security_group_id
}

