module "log_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = "${var.project_name}-${var.environment}-${local.alb_access_logs_bucket_name_suffix}"
  acl    = "log-delivery-write"

  # For example only
  force_destroy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  attach_elb_log_delivery_policy = true # Required for ALB logs
  attach_lb_log_delivery_policy  = true # Required for ALB/NLB logs

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  attach_deny_insecure_transport_policy = false #todo probably should be true but matching yjaf atm
  attach_require_latest_tls_policy      = false #todo same here
  #todo cloudtrail dataevents for this bucket required
  tags = local.all_tags
}

## s3 bucket for Tableau backups
module "s3" {
  source = "../s3"

  project_name = var.project_name
  environment  = var.environment

  bucket_name = ["tableau-backups"]

   tags = var.tags

}

locals {
  s3_tableau_backup = module.s3.aws_s3_bucket_arn[0]
}


#Setup a local variable Tableau Identity Store config file content
locals {
  file_content = jsonencode({
 
    "configEntities":{
      "identityStore": {
        "_type": "identityStoreType",
    		"type": "activedirectory",
        "domain": "i2N.com",
        "nickname": "i2N",
        "directoryServiceType": "activedirectory",
        "hostname": "<domain_instance>.i2n.com", 
        "sslPort": "636",
        "bind": "simple",
        "username": "tableau",
        "password": "<password>"	
      }
    }
  })
}


#Create a Folder for Tableau Instalation files
resource "aws_s3_object" "install_folder" {
  bucket           = local.s3_tableau_backup
  key              = "Install-Files"
}

#Upload the zip file to s3 bucket under DockerRunFiles folder
resource "aws_s3_object" "file_upload" {
  bucket           = local.s3_tableau_backup
  key              = "Install-Files/identity-store-${var.environment}.json"
  content          = local.file_content
}

