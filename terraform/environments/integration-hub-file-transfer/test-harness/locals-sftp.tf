locals {
  sftp_server_name = "${local.application_name}-${local.component_name}-sftp"
  sftp_bucket_name = "${local.application_name}-${local.environment}-${local.component_name}-sftp"

  sftp_incoming_prefix = "${local.component_name}/push-to-sftp/"
  sftp_username        = "ihubtest"

  # Files the server receives are copied to this prefix so the tests can read deliveries through S3.
  sftp_readback_prefix = "push-to-sftp/"

  # The file-dispatch module derives the same address from the same subnet lookup. Keep them in step.
  sftp_subnet_id  = sort(data.aws_subnets.shared-private.ids)[0]
  sftp_private_ip = local.create_test_harness ? cidrhost(data.aws_subnet.sftp[0].cidr_block, 100) : null

  sftp_host_key_secret_name = "${local.application_name}/${local.component_name}/sftp-host-private-key"

  # Keypair containers created by the push-to-sftp component for the test-harness dispatch entry.
  sftp_client_public_key_secret_arn = "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:${local.application_name}/push-to-sftp/test-harness-push-to-sftp/public-key-??????"

  sftp_writer_security_group_name = "${local.application_name}-push-to-sftp"
  secrets_kms_key_alias           = "alias/secrets/${local.application_name}-${local.environment}"

  sftp_user_data = templatefile("${path.module}/sftp-server-user-data.sh.tftpl", {
    username                     = local.sftp_username
    region                       = data.aws_region.current.region
    bucket_name                  = local.sftp_bucket_name
    readback_prefix              = local.sftp_readback_prefix
    host_key_secret_name         = local.sftp_host_key_secret_name
    client_public_key_secret_arn = replace(local.sftp_client_public_key_secret_arn, "-??????", "")
  })

  sftp_egress_rules = local.create_test_harness ? merge(
    {
      for subnet_id, subnet in data.aws_subnet.shared_protected : "https-${subnet_id}" => {
        description = "HTTPS to shared protected VPC endpoint subnets"
        cidr_ipv4   = subnet.cidr_block
        ip_protocol = "tcp"
        from_port   = 443
        to_port     = 443
      }
    },
    {
      s3 = {
        description    = "HTTPS to the regional S3 managed prefix list"
        prefix_list_id = data.aws_ec2_managed_prefix_list.s3[0].id
        ip_protocol    = "tcp"
        from_port      = 443
        to_port        = 443
      }
    },
  ) : {}
}
