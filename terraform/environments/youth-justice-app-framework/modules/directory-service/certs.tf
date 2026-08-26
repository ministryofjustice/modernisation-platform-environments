#Taken from https://aws.amazon.com/blogs/security/how-to-enable-ldaps-for-your-aws-microsoft-ad-directory/
#https://aws.amazon.com/solutions/implementations/microsoft-pki/
#Troubleshooting this cloudformation - find logs in SSM run command window and in cloudwatch
#If erroring Check CW to see if registering a instance to a domain fails because it already exists, then remove computer from AD to allow it to be re-registered

##############################
####Warning### 
#- this cloudformation takes at least 40mins to run also it takes hours for the certs to fully propagate, so ldaps may not work for a while
#- Also remember when testing using ldp.exe to use the dns name. EG i2n.com 636 and ssl enabled
#############################
#Deploy the CA solution from the available AWS cloudformation stack

# Create an SSM parameter for the AMI to be used - an alternative is to change the cloudformation template to accept an aim id instead of an SSM parameter

resource "aws_ssm_parameter" "w2022_ami" {
  # checkov:skip=CKV2_AWS_34: "Not supported by cloudformation below"
  name  = "/service/ami-windows-latest/CIS_Windows_Server_2022_Benchmark_Level_1"
  type  = "String"
  value = data.aws_ami.windows_2022.id
}

resource "aws_cloudformation_stack" "pki_quickstart" {
  #checkov:skip=CKV_AWS_124: "The template is provided by AWS"
  name = "MicrosoftPKIQuickStartCA"

  template_url = "https://aws-ia-us-east-1.s3.us-east-1.amazonaws.com/cfn-ps-microsoft-pki/templates/microsoft-pki.template.yaml"

  capabilities     = ["CAPABILITY_AUTO_EXPAND", "CAPABILITY_IAM"]
  disable_rollback = false # Only set tp true for troublshooting as it will leave the Stack in an inconsistent state on failure
  parameters = {
    "VPCCIDR"                = var.vpc_cidr_block
    "VPCID"                  = var.ds_managed_ad_vpc_id
    "CaServerSubnet"         = var.private_subnet_ids[0]
    "DomainMembersSG"        = aws_security_group.mgmt_instance_sg.id
    "KeyPairName"            = module.key_pair.key_pair_name
    "DirectoryType"          = "AWSManaged"
    "DomainDNSName"          = aws_directory_service_directory.ds_managed_ad.name
    "DomainNetBIOSName"      = var.ds_managed_ad_short_name
    "DomainController1IP"    = tolist(aws_directory_service_directory.ds_managed_ad.dns_ip_addresses)[0]
    "DomainController2IP"    = tolist(aws_directory_service_directory.ds_managed_ad.dns_ip_addresses)[1]
    "AdministratorSecret"    = aws_secretsmanager_secret.mad_admin_secret.arn
    "CADeploymentType"       = "Two-Tier"
    "UseS3ForCRL"            = "No"
    "EntCaServerNetBIOSName" = "SubordinateCA"
    "OrCaServerNetBIOSName"  = "RootCA"
    "AMI"                    = aws_ssm_parameter.w2022_ami.name
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "2h"
  }

  lifecycle {
    ignore_changes = all
  }
}

