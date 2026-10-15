locals {
  env_label = "feasibility"

  private_subnets = [
    data.aws_subnet.private_subnets_a.id,
    data.aws_subnet.private_subnets_b.id,
    data.aws_subnet.private_subnets_c.id,
  ]

  # Number of EBS apps instances; ebsapps_ami_ids needs one AMI per instance
  ebsapps_count = local.application_data.accounts[local.environment].ebsapps_count

  # Mount points with disk usage alarms, as alarmed on in the original ccms-ebs stack (plus /).
  # Each must exist on the instance, or its alarm stays in INSUFFICIENT_DATA.
  ebsapps_disk_paths = ["/", "/temp", "/home", "/export/home", "/u01", "/u03", "/stage"]
  ebsdb_disk_paths = [
    "/", "/temp", "/home", "/export/home", "/u01", "/backup",
    "/CCMS/EBS/arch", "/CCMS/EBS/diag", "/CCMS/EBS/redoA", "/CCMS/EBS/redoB", "/CCMS/EBS/techst",
  ]
}
