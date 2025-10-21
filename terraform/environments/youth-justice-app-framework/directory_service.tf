
/*
## Import Statements that were used to deal with issues arising following the last Development Service Destroy. They may not be needed in future.
import {
  to = module.ds.aws_cloudformation_stack.pki_quickstart
  id = "MicrosoftPKIQuickStartCA"
}

import {
  to = module.ds.aws_cloudwatch_log_group.ds
  id = "/aws/directoryservice/d-9c67503609"
}
/*
import {
  to = module.ds.aws_ssm_document.ssm_document
  id = "ssm_document_ad_schema2.2"
}
*/

module "ds" {
  source = "./modules/directory-service"

  project_name = local.project_name
  environment  = local.environment
  tags         = merge(local.tags, { Name = "AD Management Server" })

  ad_management_instance_count = local.application_data.accounts[local.environment].ad_management_instance_count


  ds_managed_ad_directory_name = "i2n.com"
  ds_managed_ad_short_name     = "i2n"
  management_keypair_name      = "ad_management_server"
  ds_managed_ad_secret_key     = module.kms.key_arn
  esb_security_group_id        = module.esb.esb_security_group_id

  ds_managed_ad_vpc_id = data.aws_vpc.shared.id
  private_subnet_ids   = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  vpc_cidr_block       = data.aws_vpc.shared.cidr_block

  rds_cluster_security_group_id = module.aurora.rds_cluster_security_group_id

  depends_on = [module.aurora]
}
