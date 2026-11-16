resource "aws_security_group" "sftp_cluster_ec2_kpmg" {
  name        = "${local.sftp_suffix}-cluster-ec2-security-group-KPMG"
  description = "Additional rules to allow KPMG access the SFTP cluster"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(local.tags,
    { Name = "${local.sftp_suffix}-cluster-ec2-security-group-KPMG" }
  )
}

# SRE-173: ITHC complete, KPMG ingress removed and SG detached from the launch template.
# Delete this SG once the SFTP cluster instances have been replaced and no longer use it.
