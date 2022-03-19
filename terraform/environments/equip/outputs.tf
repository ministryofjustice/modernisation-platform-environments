output "instance_ids" {
  value = tomap({
    for k, inst in module.ec2_multiple : k => inst.id
  })
}

output "instance_pulbic_ips" {
  value = tomap({
    for k, inst in module.ec2_multiple : k => inst.public_ip
  })
}
output "instance_private_ips" {
  value = tomap({
    for k, inst in module.ec2_multiple : k => inst.private_ip
  })
}

output "instance_password_data" {
  value = tomap({
    for k, inst in module.ec2_multiple : k => inst.password_data
  })
}

